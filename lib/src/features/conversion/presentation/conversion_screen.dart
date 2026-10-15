import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/presentation/conversion_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';

/// Rythme du suivi tant que la conversion travaille.
const conversionRefresh = Duration(seconds: 10);

/// Raison d'un échec de conversion, par code stable.
String conversionFailureText(String? reason) => switch (reason) {
  'text_changed' =>
    'Le texte a été corrigé pendant la préparation : relancez la '
        'conversion.',
  'source_unavailable' => 'Le texte de ce document n’est plus disponible.',
  'empty_text' => 'Il n’y a aucun mot à lire dans ce document.',
  'tts_rejected' => 'La voix a refusé ce texte.',
  _ => 'Un problème technique a interrompu la conversion.',
};

/// « Génération en cours » (maquette) : quatre étapes tirées du statut
/// réel, partie n sur N, relu toutes les 10 s tant que l'écran est visible.
class ConversionScreen extends ConsumerStatefulWidget {
  const ConversionScreen({
    required this.conversionId,
    required this.title,
    required this.onLibrary,
    required this.onRetry,
    this.onFinished,
    super.key,
  });

  final String conversionId;
  final String title;
  final VoidCallback onLibrary;

  /// Échec : revenir choisir une voix.
  final VoidCallback onRetry;

  /// La conversion vient de se terminer (prête ou en échec).
  final VoidCallback? onFinished;

  @override
  ConsumerState<ConversionScreen> createState() => _ConversionScreenState();
}

class _ConversionScreenState extends ConsumerState<ConversionScreen> {
  Timer? _poll;

  ConversionController get _controller =>
      ref.read(conversionControllerProvider(widget.conversionId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.refresh());
    });
    _poll = Timer.periodic(conversionRefresh, (_) {
      final conversion = ref
          .read(conversionControllerProvider(widget.conversionId))
          .conversion;
      final visible = mounted && TickerMode.of(context);
      if (visible && (conversion?.stage.working ?? true)) {
        unawaited(_controller.refresh());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(conversionControllerProvider(widget.conversionId), (
      previous,
      next,
    ) {
      final was = previous?.conversion?.stage.working ?? true;
      final now = next.conversion?.stage.working ?? true;
      if (was && !now) widget.onFinished?.call();
    });
    final view = ref.watch(conversionControllerProvider(widget.conversionId));
    final conversion = view.conversion;
    final text = Theme.of(context).textTheme;
    final colors = context.vox;
    final stage = conversion?.stage;

    return Scaffold(
      appBar: AppBar(title: const Text('Conversion')),
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
            Semantics(
              header: true,
              child: Text(
                switch (stage) {
                  ConversionStage.ready => 'Livre audio prêt',
                  ConversionStage.failed => 'La conversion a échoué',
                  _ => 'Génération en cours',
                },
                style: text.headlineSmall,
              ),
            ),
            const SizedBox(height: VoxSpacing.xs),
            Text(
              widget.title,
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: VoxSpacing.lg),
            if (view.errorCode != null) ...[
              VoxBanner(
                icon: Icons.cloud_off_outlined,
                message: conversion == null
                    ? 'Hors ligne : l’état s’affichera au retour du réseau.'
                    : 'Hors ligne : dernier état connu.',
              ),
              const SizedBox(height: VoxSpacing.md),
            ],
            if (conversion == null && view.errorCode == null) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: VoxSpacing.sm),
              const Text('Lecture de l’état…', textAlign: TextAlign.center),
            ],
            if (conversion != null &&
                conversion.stage == ConversionStage.failed) ...[
              VoxBanner(
                tone: VoxBannerTone.error,
                message: conversionFailureText(conversion.failureReason),
              ),
              const SizedBox(height: VoxSpacing.sm),
              Text(
                'Les unités non utilisées vous sont rendues.',
                style: text.bodySmall,
              ),
              const SizedBox(height: VoxSpacing.md),
              VoxPrimaryButton(
                label: 'Réessayer',
                icon: Icons.refresh,
                onPressed: widget.onRetry,
              ),
            ],
            if (conversion != null &&
                conversion.stage != ConversionStage.failed)
              _Steps(conversion: conversion),
            if (conversion?.stage.working ?? false) ...[
              const SizedBox(height: VoxSpacing.md),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.cloud_done_outlined,
                    color: colors.accent,
                  ),
                  title: const Text('Vous pouvez quitter cet écran.'),
                  subtitle: const Text(
                    'La conversion continue sur nos serveurs ; la '
                    'bibliothèque affiche son avancement.',
                  ),
                ),
              ),
            ],
            if (stage == ConversionStage.ready) ...[
              const SizedBox(height: VoxSpacing.md),
              const VoxPrimaryButton(
                label: 'Écouter',
                icon: Icons.headphones,
                onPressed: null,
              ),
              const SizedBox(height: VoxSpacing.xs),
              Text(
                'Disponible avec le lecteur.',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
            const SizedBox(height: VoxSpacing.lg),
            OutlinedButton.icon(
              onPressed: widget.onLibrary,
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Retour à la bibliothèque'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les quatre étapes : icône **et** état écrit (jamais la couleur seule).
class _Steps extends StatelessWidget {
  const _Steps({required this.conversion});

  final Conversion conversion;

  @override
  Widget build(BuildContext context) {
    final step = conversion.step;
    final parts = conversion.partCount;
    final ratio = conversion.synthesisRatio;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                step == 4 ? 'Étape 4 sur 4' : 'Étape $step sur 4',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.vox.accent,
                ),
              ),
            ),
            const SizedBox(height: VoxSpacing.sm),
            _Step(
              index: 1,
              current: step,
              title: 'Préparation du texte',
              detail: 'Découpage en phrases pour la voix',
            ),
            _Step(
              index: 2,
              current: step,
              title: 'Synthèse vocale',
              detail: step == 2
                  ? [
                      if (parts != null && parts > 0)
                        _partLabel(conversion.partsReady, parts),
                      if (ratio != null) '${(ratio * 100).floor()} %',
                    ].join(' · ')
                  : 'La voix lit votre texte',
              progress: step == 2 ? ratio : null,
            ),
            _Step(
              index: 3,
              current: step,
              title: 'Assemblage',
              detail: 'Parties audio et texte synchronisé mot à mot',
            ),
            _Step(
              index: 4,
              current: step,
              title: 'Livre audio prêt',
              detail: parts != null && step == 4
                  ? (parts > 1 ? '$parts parties' : '$parts partie')
                  : 'À écouter, même hors ligne',
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Partie en cours de synthèse : la suivante des parties prêtes.
String _partLabel(int ready, int total) =>
    'Partie ${ready + 1 > total ? total : ready + 1} sur $total';

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.current,
    required this.title,
    required this.detail,
    this.progress,
    this.last = false,
  });

  final int index;
  final int current;
  final String title;
  final String detail;
  final double? progress;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final done = index < current || (last && current == 4);
    final active = index == current && !done;
    final (icon, color, status) = done
        ? (Icons.check_circle, colors.success, 'Terminé')
        : active
        ? (Icons.timelapse, colors.accent, 'En cours')
        : (Icons.radio_button_unchecked, colors.textSecondary, 'En attente');
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : VoxSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: VoxSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleSmall?.copyWith(
                          color: done || active ? null : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: VoxSpacing.xs),
                    Text(
                      status,
                      style: text.labelSmall?.copyWith(color: color),
                    ),
                  ],
                ),
                Text(detail, style: text.bodySmall),
                if (active && progress != null) ...[
                  const SizedBox(height: VoxSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: colors.border,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
