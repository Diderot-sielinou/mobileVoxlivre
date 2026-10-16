import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/features/player/presentation/bookmark_sheets.dart';
import 'package:voxlivre/src/features/player/presentation/player_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Message d'un livre impossible à ouvrir, par code.
String playerErrorText(String code) => switch (code) {
  'CONVERSION_NOT_READY' =>
    'Rien à écouter pour l’instant : la première partie arrive.',
  'UNSUPPORTED_MANIFEST' =>
    'Mettez l’application à jour pour écouter ce livre.',
  'NETWORK_UNAVAILABLE' ||
  'TIMEOUT' => 'Pas de connexion : l’écoute demande le réseau pour l’instant.',
  _ => 'Le livre n’a pas pu être ouvert. Réessayez.',
};

/// Libellé d'une vitesse : « 1× », « 1,25× ».
String speedLabel(double speed) =>
    '${speed.toString().replaceAll(RegExp(r'\.0$'), '').replaceAll('.', ',')}×';

/// Le lecteur (design system, écran « Lecteur ») : texte lu surligné mot à
/// mot, phrase en halo, défilement qui suit la voix, contrôles en bas
/// (ADR-0010).
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    required this.conversionId,
    required this.title,
    super.key,
  });

  final String conversionId;
  final String title;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  PlayerController get _controller =>
      ref.read(playerControllerProvider(widget.conversionId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open(widget.title));
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(playerControllerProvider(widget.conversionId));
    final colors = context.vox;
    final text = view.text;
    final page = text == null || view.wordPosition < 0
        ? null
        : text.pageOf(view.wordPosition);
    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (page != null)
              Text(
                'Page $page',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (view.documentId case final documentId? when text != null)
            ..._bookmarkActions(documentId, page, view.wordPosition),
        ],
      ),
      body: _reading(view),
    );
  }
}

extension on _PlayerScreenState {
  /// Le texte et les commandes, sur le dégradé « Nuit ».
  Widget _reading(PlayerViewState view) {
    final Widget content;
    if (view.loading) {
      content = const _Loading();
    } else if (view.errorCode case final code?) {
      content = _Failed(
        code: code,
        onRetry: () => _controller.open(widget.title),
      );
    } else {
      content = Column(
        children: [
          if (!view.complete)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VoxSpacing.screenMargin,
                VoxSpacing.sm,
                VoxSpacing.screenMargin,
                0,
              ),
              child: VoxBanner(
                icon: Icons.hourglass_top,
                message:
                    'Aperçu : ${view.partsReady} partie(s) sur '
                    '${view.partCount} prête(s), la suite arrive.',
              ),
            ),
          Expanded(
            child: _BookTextView(
              conversionId: widget.conversionId,
              text: view.text!,
            ),
          ),
          _Controls(
            view: view,
            onToggle: _controller.toggle,
            onSeekBy: _controller.seekBy,
            onSeekTo: _controller.seekTo,
            onSpeed: _controller.setSpeed,
          ),
        ],
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: VoxGradients.nuit),
      child: SafeArea(child: content),
    );
  }

  /// Poser un marque-page (icône pleine si la page en a déjà un), et la
  /// liste (ADR-0012).
  List<Widget> _bookmarkActions(String documentId, int? page, int position) {
    final marks = ref.watch(bookmarksProvider(documentId)).value ?? const [];
    final marked = page != null && marks.any((b) => b.pageNumber == page);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return [
      IconButton(
        tooltip: marked
            ? 'Ajouter un marque-page (page déjà marquée)'
            : 'Ajouter un marque-page',
        onPressed: () => addBookmarkAt(
          context,
          ref,
          widget.conversionId,
          position < 0 ? 0 : position,
        ),
        icon: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : VoxMotion.bookmarkFill,
          child: Icon(
            marked ? Icons.bookmark : Icons.bookmark_add_outlined,
            key: ValueKey(marked),
            color: marked ? context.vox.accent : null,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Marque-pages (${marks.length})',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          sheetAnimationStyle: sheetAnimation(context),
          builder: (_) => BookmarksSheet(
            conversionId: widget.conversionId,
            documentId: documentId,
          ),
        ),
        icon: const Icon(Icons.bookmarks_outlined),
      ),
    ];
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(VoxSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(),
          SizedBox(height: VoxSpacing.sm),
          Text('Ouverture du livre…'),
        ],
      ),
    ),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.code, required this.onRetry});

  final String code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(VoxSpacing.screenMargin),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoxBanner(tone: VoxBannerTone.error, message: playerErrorText(code)),
        const SizedBox(height: VoxSpacing.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    ),
  );
}

/// Le texte, page par page (liste paresseuse) ; seule la page du mot
/// courant est repeinte ; le défilement garde la ligne lue dans le tiers
/// haut, sauf pendant quelques secondes après un défilement à la main.
class _BookTextView extends ConsumerStatefulWidget {
  const _BookTextView({required this.conversionId, required this.text});

  final String conversionId;
  final BookText text;

  @override
  ConsumerState<_BookTextView> createState() => _BookTextViewState();
}

class _BookTextViewState extends ConsumerState<_BookTextView> {
  final _scroll = ScrollController();
  final GlobalKey _currentKey = GlobalKey();
  DateTime _manualUntil = DateTime(0);
  late List<({int page, int from, int to})> _pages = widget.text.pages;

  /// Après un défilement à la main, on ne suit plus la voix pendant 4 s.
  static const _manualPause = Duration(seconds: 4);

  @override
  void didUpdateWidget(_BookTextView old) {
    super.didUpdateWidget(old);
    if (!identical(old.text, widget.text)) _pages = widget.text.pages;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _pageIndexOf(int position) {
    for (var i = 0; i < _pages.length; i++) {
      if (position <= _pages[i].to) return i;
    }
    return _pages.length - 1;
  }

  /// Fait défiler jusqu'au mot à [position] (tiers haut de l'écran).
  void _follow(int position) {
    if (position < 0 || DateTime.now().isBefore(_manualUntil)) return;
    if (!_scroll.hasClients) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final paragraph = _currentKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) {
      // Page pas encore construite (saut lointain) : on s'en approche, la
      // suite se fait à l'image suivante.
      final share =
          _pageIndexOf(position) / (_pages.length - 1).clamp(1, 1 << 30);
      _scroll.jumpTo(share * _scroll.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _follow(position);
      });
      return;
    }
    final page = _pages[_pageIndexOf(position)];
    final start = _offsetInPage(page, position);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + 1),
    );
    if (boxes.isEmpty) return;
    final viewport = RenderAbstractViewport.of(paragraph);
    final target = viewport
        .getOffsetToReveal(paragraph, 0.3, rect: boxes.first.toRect())
        .offset
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if ((target - _scroll.offset).abs() < 4) return;
    if (reduceMotion) {
      _scroll.jumpTo(target);
    } else {
      unawaited(
        _scroll.animateTo(
          target,
          duration: VoxMotion.page,
          curve: Curves.easeOut,
        ),
      );
    }
  }

  int _offsetInPage(({int page, int from, int to}) page, int position) {
    var offset = 0;
    for (var i = page.from; i < position; i++) {
      offset += widget.text.words[i].text.length + 1;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      playerControllerProvider(
        widget.conversionId,
      ).select((s) => s.wordPosition),
      (_, position) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _follow(position);
      }),
    );
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          _manualUntil = DateTime.now().add(_manualPause);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          VoxSpacing.md,
          VoxSpacing.screenMargin,
          VoxSpacing.xl * 3,
        ),
        itemCount: _pages.length,
        itemBuilder: (context, i) => _PageBlock(
          conversionId: widget.conversionId,
          text: widget.text,
          page: _pages[i],
          currentKey: _currentKey,
        ),
      ),
    );
  }
}

/// Position du mot sous le caractère [offset] d'une page (mots séparés
/// d'une espace, de [from] à [to]).
int wordAtOffset(BookText text, int from, int to, int offset) {
  var start = 0;
  for (var i = from; i <= to; i++) {
    start += text.words[i].text.length + 1;
    if (offset < start) return i;
  }
  return to;
}

/// Une page : texte simple, sauf la page du mot courant (halo sur la
/// phrase, pastille sur le mot).
class _PageBlock extends ConsumerWidget {
  const _PageBlock({
    required this.conversionId,
    required this.text,
    required this.page,
    required this.currentKey,
  });

  final String conversionId;
  final BookText text;
  final ({int page, int from, int to}) page;
  final GlobalKey currentKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(
      playerControllerProvider(conversionId).select(
        (s) => s.wordPosition >= page.from && s.wordPosition <= page.to
            ? s.wordPosition
            : -1,
      ),
    );
    final colors = context.vox;
    final style = VoxTypography.reading(
      colors.text,
    ).copyWith(fontSize: 20, height: 1.75);
    final words = text.words;
    final InlineSpan content;
    if (position < 0) {
      content = TextSpan(
        text: [
          for (var i = page.from; i <= page.to; i++) words[i].text,
        ].join(' '),
      );
    } else {
      final sentence = text.sentenceAround(position);
      content = TextSpan(
        children: [
          for (var i = page.from; i <= page.to; i++)
            TextSpan(
              text: i == page.to ? words[i].text : '${words[i].text} ',
              style: i == position
                  ? TextStyle(
                      backgroundColor: colors.wordHighlight,
                      color: colors.onWordHighlight,
                    )
                  : i >= sentence.start && i <= sentence.end
                  ? TextStyle(backgroundColor: colors.sentenceHalo)
                  : null,
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: VoxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Page ${page.page}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: VoxSpacing.xs),
          // Appui long sur un mot : marque-page à cet endroit (ADR-0012).
          Builder(
            builder: (paragraphContext) => GestureDetector(
              onLongPressStart: (details) {
                // Sous le détecteur de gestes : le paragraphe du texte.
                var node = paragraphContext.findRenderObject();
                while (node is RenderProxyBox) {
                  node = node.child;
                }
                final paragraph = node;
                if (paragraph is! RenderParagraph) return;
                final offset = paragraph
                    .getPositionForOffset(
                      paragraph.globalToLocal(details.globalPosition),
                    )
                    .offset;
                unawaited(HapticFeedback.selectionClick());
                unawaited(
                  addBookmarkAt(
                    context,
                    ref,
                    conversionId,
                    wordAtOffset(text, page.from, page.to, offset),
                  ),
                );
              },
              child: RichText(
                key: position >= 0 ? currentKey : null,
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(style: style, children: [content]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de commandes (verre dépoli, design system) : progression, −15 s,
/// lecture/pause, +15 s, vitesse.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.view,
    required this.onToggle,
    required this.onSeekBy,
    required this.onSeekTo,
    required this.onSpeed,
  });

  final PlayerViewState view;
  final VoidCallback onToggle;
  final ValueChanged<int> onSeekBy;
  final ValueChanged<int> onSeekTo;
  final ValueChanged<double> onSpeed;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final duration = view.durationMs <= 0 ? 1 : view.durationMs;
    final time = text.labelMedium?.copyWith(
      color: colors.textSecondary,
      fontFeatures: VoxTypography.tabularFigures,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VoxSpacing.md,
        VoxSpacing.sm,
        VoxSpacing.md,
        VoxSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VoxRadius.sheet),
        ),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: view.positionMs.clamp(0, duration).toDouble(),
            max: duration.toDouble(),
            semanticFormatterCallback: (v) =>
                '${VoxFormat.clock(v.round())} sur '
                '${VoxFormat.clock(duration)}',
            onChanged: (v) => onSeekTo(v.round()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VoxSpacing.md),
            child: Row(
              children: [
                Text(VoxFormat.clock(view.positionMs), style: time),
                const Spacer(),
                Text(
                  '−${VoxFormat.clock(duration - view.positionMs)}',
                  style: time,
                ),
              ],
            ),
          ),
          const SizedBox(height: VoxSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _chooseSpeed(context),
                child: Text(
                  speedLabel(view.speed),
                  semanticsLabel:
                      'Vitesse de lecture, ${speedLabel(view.speed)}',
                ),
              ),
              IconButton(
                tooltip: 'Reculer de 15 secondes',
                iconSize: 32,
                onPressed: () => onSeekBy(-15000),
                icon: const _SkipIcon(forward: false),
              ),
              SizedBox.square(
                dimension: VoxSizes.playButton,
                child: IconButton.filled(
                  tooltip: view.playing ? 'Pause' : 'Lecture',
                  iconSize: 40,
                  onPressed: onToggle,
                  icon: Icon(view.playing ? Icons.pause : Icons.play_arrow),
                ),
              ),
              IconButton(
                tooltip: 'Avancer de 15 secondes',
                iconSize: 32,
                onPressed: () => onSeekBy(15000),
                icon: const _SkipIcon(forward: true),
              ),
              const SizedBox(width: VoxSizes.minTouchTarget),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _chooseSpeed(BuildContext context) async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final chosen = await showModalBottomSheet<double>(
      context: context,
      sheetAnimationStyle: AnimationStyle(
        duration: reduceMotion ? Duration.zero : VoxMotion.sheetIn,
        reverseDuration: reduceMotion ? Duration.zero : VoxMotion.sheetOut,
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VoxSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vitesse de lecture',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: VoxSpacing.md),
              Wrap(
                spacing: VoxSpacing.sm,
                runSpacing: VoxSpacing.sm,
                children: [
                  for (final speed in playerSpeeds)
                    ChoiceChip(
                      label: Text(speedLabel(speed)),
                      selected: speed == view.speed,
                      showCheckmark: false,
                      onSelected: (_) => Navigator.of(context).pop(speed),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) onSpeed(chosen);
  }
}

/// Flèche de reprise avec « 15 » (les icônes Material n'ont que 5, 10, 30).
class _SkipIcon extends StatelessWidget {
  const _SkipIcon({required this.forward});

  final bool forward;

  @override
  Widget build(BuildContext context) {
    const arrow = Icon(Icons.replay, size: 32);
    // Le « 15 » dessiné ne doit pas être lu seul.
    return Semantics(
      label: forward ? 'Avancer de 15 secondes' : 'Reculer de 15 secondes',
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (forward) Transform.flip(flipX: true, child: arrow) else arrow,
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '15',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
