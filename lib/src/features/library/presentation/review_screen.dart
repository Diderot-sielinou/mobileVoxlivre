import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/features/library/presentation/review_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';

/// Libellé d'une ligne retirée.
String setAsideLabel(SetAsideReason reason) => switch (reason) {
  SetAsideReason.header => 'En-tête',
  SetAsideReason.footer => 'Pied de page',
  SetAsideReason.pageNumber => 'Pagination',
  SetAsideReason.footnote => 'Note',
  SetAsideReason.caption => 'Légende',
  SetAsideReason.table => 'Tableau',
  SetAsideReason.unknown => 'Autre',
};

/// Message d'un échec d'enregistrement ou de relecture, par code.
String reviewErrorText(String code) => switch (code) {
  'INVALID_PAGE_TEXT' =>
    'Texte refusé : ${PageText.maxLength} caractères au plus, sans '
        'caractère spécial invisible.',
  'NETWORK_UNAVAILABLE' || 'TIMEOUT' =>
    'Pas de connexion : rien n’a été enregistré. Votre texte est '
        'gardé.',
  'DOCUMENT_TEXT_NOT_READY' => 'Le texte n’est pas encore prêt.',
  _ => 'L’enregistrement a échoué. Réessayez.',
};

/// Vérification du texte (maquettes « Vérification du texte » et « Mode
/// édition », RF-06) : pages à relire d'abord (confiance OCR < 80 %),
/// correction d'une page, lignes retirées à réintégrer, « J'ai relu ».
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    required this.documentId,
    required this.onReviewed,
    super.key,
  });

  final String documentId;

  /// Relecture enregistrée : retour à la fiche.
  final VoidCallback onReviewed;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _draft = TextEditingController();
  int? _editing;
  bool _busy = false;
  String? _actionError;

  ReviewController get _controller =>
      ref.read(reviewControllerProvider(widget.documentId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.refresh());
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _edit(DocumentPage page, [String? text]) => setState(() {
    _editing = page.pageNumber;
    _draft.text = text ?? page.text;
    _actionError = null;
  });

  void _cancel() => setState(() {
    _editing = null;
    _actionError = null;
  });

  Future<void> _save(int pageNumber) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final code = await _controller.save(pageNumber, _draft.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _actionError = code;
      if (code == null) _editing = null;
    });
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Page $pageNumber enregistrée')),
      );
    }
  }

  Future<void> _markReviewed() async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final code = await _controller.markReviewed();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _actionError = code;
    });
    if (code == null) {
      final messenger = ScaffoldMessenger.of(context);
      widget.onReviewed();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Texte relu : vous pouvez lancer la conversion.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.documentId;
    final view = ref.watch(reviewControllerProvider(id));
    final pages = ref.watch(documentPagesProvider(id)).value ?? const [];
    final sheet = ref.watch(documentSheetProvider(id)).value;
    final toReview = [
      for (final p in pages)
        if (p.needsReview) p,
    ];
    final filtered = view.onlyToReview && toReview.isNotEmpty;
    final visible = filtered ? toReview : pages;
    final page =
        visible.where((p) => p.pageNumber == view.pageNumber).firstOrNull ??
        visible.firstOrNull;
    final index = page == null ? -1 : visible.indexOf(page);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification du texte')),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            VoxSpacing.screenMargin,
            VoxSpacing.sm,
            VoxSpacing.screenMargin,
            VoxSpacing.xl,
          ),
          children: [
            if (sheet != null)
              Text(
                sheet.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.vox.textSecondary,
                ),
              ),
            if (view.errorCode != null) ...[
              const SizedBox(height: VoxSpacing.sm),
              VoxBanner(
                icon: Icons.cloud_off_outlined,
                message: pages.isEmpty
                    ? 'Hors ligne : le texte s’affichera au retour du réseau.'
                    : 'Hors ligne : texte enregistré sur l’appareil.',
              ),
            ],
            if (pages.isEmpty && view.refreshing) ...[
              const SizedBox(height: VoxSpacing.xl),
              const LinearProgressIndicator(),
              const SizedBox(height: VoxSpacing.sm),
              const Text('Chargement du texte…', textAlign: TextAlign.center),
            ],
            if (page != null) ...[
              const SizedBox(height: VoxSpacing.md),
              _Filters(
                toReview: toReview.length,
                total: pages.length,
                onlyToReview: filtered,
                onChanged: (value) =>
                    _controller.showOnlyToReview(value: value),
              ),
              const SizedBox(height: VoxSpacing.sm),
              _PageChips(
                pages: visible,
                selected: page.pageNumber,
                onSelected: (n) {
                  _cancel();
                  _controller.select(n);
                },
              ),
              const SizedBox(height: VoxSpacing.md),
              _PageCard(
                page: page,
                total: pages.length,
                editing: _editing == page.pageNumber,
                draft: _draft,
                busy: _busy,
                error: _editing == page.pageNumber ? _actionError : null,
                onEdit: () => _edit(page),
                onCancel: _cancel,
                onSave: () => _save(page.pageNumber),
              ),
              if (page.stillSetAside.isNotEmpty) ...[
                const SizedBox(height: VoxSpacing.md),
                _SetAside(
                  lines: page.stillSetAside,
                  onReintegrate: (line) => _edit(
                    page,
                    _editing == page.pageNumber
                        ? DocumentPage(
                            pageNumber: page.pageNumber,
                            text: _draft.text,
                          ).withLine(line)
                        : page.withLine(line),
                  ),
                ),
              ],
              const SizedBox(height: VoxSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: index > 0
                        ? OutlinedButton.icon(
                            onPressed: () {
                              _cancel();
                              _controller.select(visible[index - 1].pageNumber);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: Text(
                              'Page ${visible[index - 1].pageNumber}',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: VoxSpacing.sm),
                  Expanded(
                    child: index < visible.length - 1
                        ? OutlinedButton.icon(
                            onPressed: () {
                              _cancel();
                              _controller.select(visible[index + 1].pageNumber);
                            },
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              'Page ${visible[index + 1].pageNumber}',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      // Masquée pendant l'édition : le clavier a besoin de la place.
      bottomNavigationBar: (sheet?.reviewPending ?? false) && _editing == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VoxSpacing.screenMargin,
                  VoxSpacing.sm,
                  VoxSpacing.screenMargin,
                  VoxSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_actionError != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          reviewErrorText(_actionError!),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.vox.error),
                        ),
                      ),
                      const SizedBox(height: VoxSpacing.xs),
                    ],
                    VoxPrimaryButton(
                      label: 'J’ai relu le texte',
                      icon: Icons.check_circle_outline,
                      loading: _busy,
                      onPressed: pages.isEmpty ? null : _markReviewed,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

/// « À vérifier (n) » / « Toutes (n) » ; le premier n'existe que pour un
/// scan qui a des pages douteuses.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.toReview,
    required this.total,
    required this.onlyToReview,
    required this.onChanged,
  });

  final int toReview;
  final int total;
  final bool onlyToReview;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: VoxSpacing.sm,
    children: [
      if (toReview > 0)
        ChoiceChip(
          avatar: const Icon(Icons.warning_amber_rounded, size: 18),
          label: Text('À vérifier ($toReview)'),
          selected: onlyToReview,
          showCheckmark: false,
          onSelected: (_) => onChanged(true),
        ),
      ChoiceChip(
        label: Text('Toutes ($total)'),
        selected: !onlyToReview,
        showCheckmark: false,
        onSelected: (_) => onChanged(false),
      ),
    ],
  );
}

class _PageChips extends StatelessWidget {
  const _PageChips({
    required this.pages,
    required this.selected,
    required this.onSelected,
  });

  final List<DocumentPage> pages;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: VoxSizes.minTouchTarget,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: pages.length,
      separatorBuilder: (_, _) => const SizedBox(width: VoxSpacing.sm),
      itemBuilder: (context, i) {
        final page = pages[i];
        return ChoiceChip(
          avatar: page.needsReview
              ? const Icon(Icons.warning_amber_rounded, size: 18)
              : null,
          tooltip: page.needsReview
              ? 'Page ${page.pageNumber}, à vérifier'
              : 'Page ${page.pageNumber}',
          label: Text('p. ${page.pageNumber}'),
          selected: page.pageNumber == selected,
          showCheckmark: false,
          onSelected: (_) => onSelected(page.pageNumber),
        );
      },
    ),
  );
}

/// La page : numéro, confiance (icône **et** texte), texte ou éditeur.
class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.page,
    required this.total,
    required this.editing,
    required this.draft,
    required this.busy,
    required this.error,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final DocumentPage page;
  final int total;
  final bool editing;
  final TextEditingController draft;
  final bool busy;
  final String? error;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final confidence = page.confidence;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Page ${page.pageNumber} sur $total',
                      style: text.titleMedium,
                    ),
                  ),
                ),
                if (!editing)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
              ],
            ),
            if (confidence != null) ...[
              const SizedBox(height: VoxSpacing.xs),
              Row(
                children: [
                  Icon(
                    page.needsReview
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 18,
                    color: page.needsReview ? colors.warning : colors.success,
                  ),
                  const SizedBox(width: VoxSpacing.xs),
                  Flexible(
                    child: Text(
                      'Confiance ${(confidence * 100).round()} %'
                      '${page.needsReview ? ' · à relire' : ''}',
                      style: text.labelMedium?.copyWith(
                        color: page.needsReview
                            ? colors.warning
                            : colors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: VoxSpacing.md),
            if (editing) ...[
              TextField(
                controller: draft,
                autofocus: true,
                enabled: !busy,
                minLines: 6,
                maxLines: 18,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Texte de la page',
                  alignLabelWithHint: true,
                  errorText: error == null ? null : reviewErrorText(error!),
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: VoxSpacing.md),
              // L'un sous l'autre : côte à côte, les libellés se coupent
              // avec une grande taille de police.
              FilledButton.icon(
                onPressed: busy ? null : onSave,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Enregistrer la page'),
              ),
              const SizedBox(height: VoxSpacing.sm),
              OutlinedButton.icon(
                onPressed: busy ? null : onCancel,
                icon: const Icon(Icons.close),
                label: const Text('Annuler'),
              ),
            ] else
              SelectableText(
                page.text.isEmpty ? '(page vide)' : page.text,
                style: text.bodyLarge?.copyWith(height: 1.6),
              ),
          ],
        ),
      ),
    );
  }
}

/// « Lignes retirées de la lecture (n) » : chacune peut être réintégrée.
class _SetAside extends StatelessWidget {
  const _SetAside({required this.lines, required this.onReintegrate});

  final List<SetAsideLine> lines;
  final ValueChanged<SetAsideLine> onReintegrate;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.playlist_remove, color: colors.textSecondary),
        title: Text('Lignes retirées de la lecture (${lines.length})'),
        subtitle: const Text('En-têtes, numéros, notes : non lus à voix haute'),
        children: [
          for (final line in lines)
            ListTile(
              title: Text(
                line.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
              subtitle: Text(setAsideLabel(line.reason)),
              trailing: TextButton(
                onPressed: () => onReintegrate(line),
                child: const Text('Réintégrer'),
              ),
            ),
        ],
      ),
    );
  }
}
