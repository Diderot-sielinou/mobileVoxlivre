import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/features/player/presentation/player_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/format/durations.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Message d'un marque-page refusé, par code.
String bookmarkErrorText(String code) => switch (code) {
  'INVALID_BOOKMARK_NOTE' => 'La note dépasse 2 000 caractères.',
  'BOOKMARKS_LIMIT_CONFLICT' => '500 marque-pages au plus par livre.',
  _ => 'Le marque-page n’a pas pu être enregistré.',
};

/// Animations des feuilles du lecteur (300 ms / 200 ms), coupées si le
/// téléphone demande moins d'animations.
AnimationStyle sheetAnimation(BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return AnimationStyle(
    duration: reduceMotion ? Duration.zero : VoxMotion.sheetIn,
    reverseDuration: reduceMotion ? Duration.zero : VoxMotion.sheetOut,
  );
}

/// Feuille « Ajouter un marque-page » (ou « Modifier la note ») : rend la
/// note saisie, `null` si annulé.
Future<String?> showBookmarkNoteSheet(
  BuildContext context, {
  required int page,
  required String excerpt,
  int? timeMs,
  String note = '',
  bool editing = false,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: sheetAnimation(context),
  builder: (context) => _NoteSheet(
    page: page,
    excerpt: excerpt,
    timeMs: timeMs,
    note: note,
    editing: editing,
  ),
);

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.page,
    required this.excerpt,
    required this.timeMs,
    required this.note,
    required this.editing,
  });

  final int page;
  final String excerpt;
  final int? timeMs;
  final String note;
  final bool editing;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _note = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final place = [
      'Page ${widget.page}',
      if (widget.timeMs case final ms?) VoxFormat.clock(ms),
    ].join(' · ');
    return Padding(
      // Le clavier ne recouvre pas la note.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VoxSpacing.screenMargin,
            0,
            VoxSpacing.screenMargin,
            VoxSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.bookmark, color: colors.accent),
                  const SizedBox(width: VoxSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.editing
                          ? 'Modifier la note'
                          : 'Ajouter un marque-page',
                      style: text.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: VoxSpacing.md),
              Container(
                padding: const EdgeInsets.all(VoxSpacing.md),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(VoxRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place, style: text.labelLarge),
                    const SizedBox(height: VoxSpacing.xs),
                    Text(
                      '« ${widget.excerpt}… »',
                      style: text.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VoxSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('Note personnelle', style: text.titleSmall),
                  ),
                  Text(
                    'Facultatif',
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VoxSpacing.sm),
              TextField(
                controller: _note,
                autofocus: widget.editing,
                minLines: 3,
                maxLines: 6,
                maxLength: bookmarkNoteMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex. Définition à réécouter en révision…',
                ),
              ),
              const SizedBox(height: VoxSpacing.md),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: VoxSpacing.md),
                  Expanded(
                    child: VoxPrimaryButton(
                      label: widget.editing
                          ? 'Enregistrer la note'
                          : 'Enregistrer',
                      icon: Icons.bookmark_add_outlined,
                      onPressed: () => Navigator.of(context).pop(_note.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtres de la liste.
enum _Filter { all, withNote, toReview }

/// Feuille « Marque-pages » d'un livre ouvert : filtres, cartes, aller au
/// mot, modifier la note, supprimer (glisser ou menu, avec confirmation).
class BookmarksSheet extends ConsumerStatefulWidget {
  const BookmarksSheet({
    required this.conversionId,
    required this.documentId,
    super.key,
  });

  final String conversionId;
  final String documentId;

  @override
  ConsumerState<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends ConsumerState<BookmarksSheet> {
  _Filter _filter = _Filter.all;

  /// Message affiché dans la feuille : un `SnackBar` resterait caché
  /// dessous, sur l'écran du lecteur.
  String? _notice;
  Timer? _noticeTimer;

  void _say(String message) {
    _noticeTimer?.cancel();
    setState(() => _notice = message);
    _noticeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  PlayerController get _player =>
      ref.read(playerControllerProvider(widget.conversionId).notifier);

  Future<void> _open(Bookmark bookmark) async {
    final navigator = Navigator.of(context);
    if (await _player.jumpTo(bookmark)) {
      navigator.pop();
    } else if (mounted) {
      _say('Cette partie du livre n’est pas encore prête.');
    }
  }

  Future<void> _edit(Bookmark bookmark) async {
    final note = await showBookmarkNoteSheet(
      context,
      page: bookmark.pageNumber,
      excerpt: bookmark.excerpt,
      timeMs: _timeOf(bookmark),
      note: bookmark.note,
      editing: true,
    );
    if (note == null || !mounted) return;
    final code = await _player.editBookmark(bookmark, note);
    if (mounted) {
      _say(code == null ? 'Note enregistrée' : bookmarkErrorText(code));
    }
  }

  /// Confirmation puis suppression ; `true` si supprimé.
  Future<bool> _delete(Bookmark bookmark) async {
    final colors = context.vox;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce marque-page ?'),
        content: Text(
          bookmark.hasNote
              ? 'Sa note sera supprimée aussi.'
              : '« ${bookmark.excerpt}… »',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return false;
    await _player.deleteBookmark(bookmark);
    if (mounted) _say('Marque-page supprimé');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final all =
        ref.watch(bookmarksProvider(widget.documentId)).value ?? const [];
    final withNote = all.where((b) => b.hasNote).toList();
    final toReview = all.where((b) => b.needsReview).toList();
    final shown = switch (_filter) {
      _Filter.all => all,
      _Filter.withNote => withNote,
      _Filter.toReview => toReview,
    };
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          0,
          VoxSpacing.screenMargin,
          VoxSpacing.xl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Marque-pages', style: text.titleLarge),
                      TextSpan(
                        text: '  ${_count(all.length)}',
                        style: text.labelLarge?.copyWith(
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: VoxSpacing.sm),
          Wrap(
            spacing: VoxSpacing.sm,
            runSpacing: VoxSpacing.sm,
            children: [
              for (final (filter, label, count) in [
                (_Filter.all, 'Tous', all.length),
                (_Filter.withNote, 'Avec notes', withNote.length),
                (_Filter.toReview, 'À vérifier', toReview.length),
              ])
                ChoiceChip(
                  label: Text('$label ($count)'),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: VoxSpacing.md),
          // Confirmation annoncée au lecteur d'écran.
          Semantics(
            liveRegion: true,
            container: true,
            child: _notice == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: VoxSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: colors.success),
                        const SizedBox(width: VoxSpacing.sm),
                        Expanded(
                          child: Text(_notice!, style: text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VoxSpacing.lg),
              child: Text(
                all.isEmpty
                    ? 'Aucun marque-page. Touchez l’icône marque-page en '
                          'haut, ou appuyez longuement sur un mot du texte.'
                    : 'Aucun marque-page dans ce filtre.',
                style: text.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ),
          for (final bookmark in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
              child: Dismissible(
                key: ValueKey(bookmark.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _delete(bookmark),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VoxSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(VoxRadius.card),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, color: colors.background),
                      const SizedBox(width: VoxSpacing.xs),
                      Text(
                        'Supprimer',
                        style: text.labelLarge?.copyWith(
                          color: colors.background,
                        ),
                      ),
                    ],
                  ),
                ),
                child: _BookmarkCard(
                  bookmark: bookmark,
                  timeMs: _timeOf(bookmark),
                  now: ref.read(clockProvider).now(),
                  onOpen: () => _open(bookmark),
                  onEdit: () => _edit(bookmark),
                  onDelete: () => _delete(bookmark),
                ),
              ),
            ),
          if (all.isNotEmpty) ...[
            const SizedBox(height: VoxSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: VoxSpacing.sm),
                Expanded(
                  child: Text(
                    'Astuce : appuyez longuement sur un mot du texte pour '
                    'poser un marque-page à cet endroit.',
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int? _timeOf(Bookmark bookmark) {
    final position = _player.positionOfBookmark(bookmark);
    if (position < 0) return null;
    return ref
        .read(playerControllerProvider(widget.conversionId))
        .text
        ?.words[position]
        .startMs;
  }

  static String _count(int n) => n > 1 ? '$n enregistrés' : '$n enregistré';
}

/// Une carte : badges (à vérifier, en attente), extrait, note, place.
class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.timeMs,
    required this.now,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final int? timeMs;
  final DateTime now;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    // `createdAt` vient de l'horloge du serveur (à l'arrivée), `updatedAt`
    // de l'appareil : seul un écart net signale une modification.
    final edited = bookmark.updatedAt.isAfter(
      bookmark.createdAt.add(const Duration(minutes: 1)),
    );
    final when = VoxFormat.ago(bookmark.updatedAt, now);
    final place = [
      'p. ${bookmark.pageNumber}',
      if (timeMs case final ms?) VoxFormat.clock(ms),
      if (edited) 'Modifié $when' else 'Créé $when',
    ].join(' · ');
    final radius = BorderRadius.circular(VoxRadius.card);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VoxSpacing.md,
            VoxSpacing.md,
            VoxSpacing.xs,
            VoxSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookmark.needsReview) ...[
                      _Badge(
                        icon: Icons.warning_amber_rounded,
                        label: 'À vérifier',
                        color: colors.warning,
                      ),
                      const SizedBox(height: VoxSpacing.xs),
                      Text(
                        'Le texte de cette page a changé depuis : ce '
                        'marque-page a été replacé au passage le plus proche.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: VoxSpacing.sm),
                    ],
                    if (bookmark.pending) ...[
                      _Badge(
                        icon: Icons.cloud_off_outlined,
                        label: 'En attente de synchronisation',
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: VoxSpacing.sm),
                    ],
                    Text(
                      '« ${bookmark.excerpt}… »',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (bookmark.hasNote) ...[
                      const SizedBox(height: VoxSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(VoxSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.elevated,
                          borderRadius: BorderRadius.circular(VoxRadius.chip),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: VoxSpacing.sm),
                            Expanded(
                              child: Text(
                                bookmark.note,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: VoxSpacing.sm),
                    Text(
                      place,
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<VoidCallback>(
                tooltip: 'Actions du marque-page',
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: onEdit,
                    child: const ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier la note'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: onDelete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: colors.error),
                      title: Text(
                        'Supprimer',
                        style: TextStyle(color: colors.error),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastille d'état : icône **et** texte.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: VoxSpacing.sm,
      vertical: VoxSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(VoxRadius.chip),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: VoxSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

/// Pose un marque-page sur le mot à [position] du lecteur : feuille de
/// note, puis retour haptique et message.
Future<void> addBookmarkAt(
  BuildContext context,
  WidgetRef ref,
  String conversionId,
  int position,
) async {
  final view = ref.read(playerControllerProvider(conversionId));
  final text = view.text;
  if (text == null || position < 0) return;
  final note = await showBookmarkNoteSheet(
    context,
    page: text.pageOf(position),
    excerpt: text.excerptAt(position),
    timeMs: text.words[position].startMs,
  );
  if (note == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final code = await ref
      .read(playerControllerProvider(conversionId).notifier)
      .addBookmark(position, note);
  if (code == null) unawaited(HapticFeedback.mediumImpact());
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          code == null ? 'Marque-page ajouté' : bookmarkErrorText(code),
        ),
      ),
    );
}
