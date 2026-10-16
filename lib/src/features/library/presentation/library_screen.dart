import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/library/domain/library_shelf.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/features/library/presentation/library_controller.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/empty_library.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/library_card.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/library_skeleton.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/resume_card.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/format/durations.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Rythme du rafraîchissement tant qu'un livre se prépare (ADR-0006).
const processingRefresh = Duration(seconds: 15);

/// Onglet Bibliothèque : le cache d'abord, le réseau ensuite (ADR-0006).
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({
    required this.onImport,
    required this.onOpenDocument,
    required this.onListen,
    super.key,
  });

  /// Ouvre l'onglet Importer.
  final VoidCallback onImport;

  /// Ouvre la fiche d'un document.
  final ValueChanged<String> onOpenDocument;

  /// Ouvre le lecteur d'une conversion (ADR-0010).
  final void Function(String conversionId, String title) onListen;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  Timer? _poll;

  /// Les cartes apparaissent en cascade une seule fois : au premier
  /// affichage d'une bibliothèque remplie.
  bool _cascadeDone = false;

  LibraryController get _controller =>
      ref.read(libraryControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.refresh());
    });
    _poll = Timer.periodic(processingRefresh, (_) => _pollIfNeeded());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Un livre se prépare et l'onglet est à l'écran (les onglets cachés ont
  /// leurs animations coupées : `TickerMode`).
  void _pollIfNeeded() {
    if (!mounted || !TickerMode.of(context)) return;
    final items = ref.read(librarySnapshotProvider).value?.items ?? const [];
    if (LibraryShelf.hasWorkInProgress(items)) {
      unawaited(_controller.refresh(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot =
        ref.watch(librarySnapshotProvider).value ?? LibrarySnapshot.empty;
    final view = ref.watch(libraryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque')),
      body: RefreshIndicator(
        onRefresh: () => _controller.refresh(force: true),
        child: ListView(
          // Toujours défilable : « tirer pour rafraîchir » marche aussi sur
          // une liste courte.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            VoxSpacing.screenMargin,
            VoxSpacing.sm,
            VoxSpacing.screenMargin,
            VoxSpacing.xl,
          ),
          children: _content(snapshot, view),
        ),
      ),
    );
  }

  List<Widget> _content(LibrarySnapshot snapshot, LibraryViewState view) {
    final error = view.errorCode;
    if (!snapshot.loaded) {
      // Rien en cache : squelettes, ou l'erreur avec « Réessayer ».
      if (error == null) return const [LibrarySkeleton()];
      return [
        _ErrorBanner(code: error),
        const SizedBox(height: VoxSpacing.md),
        Center(
          child: OutlinedButton.icon(
            onPressed: view.refreshing
                ? null
                : () => _controller.refresh(force: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
      ];
    }

    final items = snapshot.items;
    final banner = error == null
        ? null
        : _ErrorBanner(
            code: error,
            refreshedAt: snapshot.refreshedAt,
            now: ref.read(clockProvider).now(),
          );
    if (items.isEmpty) {
      return [
        ?banner,
        EmptyLibrary(onImport: widget.onImport),
      ];
    }

    final resume = LibraryShelf.resume(items);
    final counts = LibraryShelf.counts(items);
    final shown = items.where(view.filter.matches).toList();
    final animate = !_cascadeDone && !MediaQuery.disableAnimationsOf(context);
    if (!_cascadeDone) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _cascadeDone = true,
      );
    }

    return [
      if (banner != null) ...[banner, const SizedBox(height: VoxSpacing.md)],
      if (resume != null) ...[
        ResumeCard(
          item: resume,
          onTap: switch (resume.conversion) {
            final conversion? => () => widget.onListen(
              conversion.id,
              resume.title,
            ),
            null => null,
          },
        ),
        const SizedBox(height: VoxSpacing.lg),
      ],
      _Filters(
        selected: view.filter,
        counts: counts,
        onSelected: _controller.select,
      ),
      const SizedBox(height: VoxSpacing.md),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: VoxSpacing.lg),
          child: Text(
            'Aucun livre dans cette catégorie.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      for (final (index, item) in shown.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
          child: _Cascade(
            index: index,
            animate: animate,
            child: LibraryCard(
              key: ValueKey(item.documentId),
              item: item,
              onTap: () => widget.onOpenDocument(item.documentId),
            ),
          ),
        ),
    ];
  }
}

/// Puces de filtre, avec le nombre de livres.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final LibraryFilter selected;
  final Map<LibraryFilter, int> counts;
  final ValueChanged<LibraryFilter> onSelected;

  static const Map<LibraryFilter, String> _labels = {
    LibraryFilter.all: 'Tous',
    LibraryFilter.inProgress: 'En cours',
    LibraryFilter.ready: 'Prêts',
    LibraryFilter.finished: 'Terminés',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in LibraryFilter.values) ...[
            ChoiceChip(
              label: Text('${_labels[filter]} (${counts[filter] ?? 0})'),
              selected: filter == selected,
              showCheckmark: false,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: VoxSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Bandeau d'échec du rafraîchissement : hors ligne (avertissement, les
/// livres en cache restent là) ou serveur indisponible.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.code, this.refreshedAt, this.now});

  final String code;
  final DateTime? refreshedAt;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final offline = code == 'NETWORK_UNAVAILABLE' || code == 'TIMEOUT';
    final since = refreshedAt != null && now != null
        ? ' Dernière mise à jour ${VoxFormat.ago(refreshedAt!, now!)}.'
        : '';
    final message = offline
        ? 'Hors ligne : vos livres restent disponibles.$since'
        : 'Service momentanément indisponible. Tirez vers le bas pour '
              'réessayer.$since';
    return VoxBanner(
      message: message,
      tone: offline ? VoxBannerTone.warning : VoxBannerTone.error,
      icon: offline ? Icons.cloud_off_outlined : null,
    );
  }
}

/// Apparition en cascade (design system §2, n° 4) : 60 ms d'écart, 0,96 → 1,
/// au premier chargement seulement.
class _Cascade extends StatelessWidget {
  const _Cascade({
    required this.index,
    required this.animate,
    required this.child,
  });

  final int index;
  final bool animate;
  final Widget child;

  static const _base = Duration(milliseconds: 350);
  static const _stagger = Duration(milliseconds: 60);

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    // Au-delà de 8 cartes, plus de décalage : la liste ne traîne pas.
    final delay = _stagger * index.clamp(0, 8);
    final total = _base + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      ),
      child: child,
    );
  }
}
