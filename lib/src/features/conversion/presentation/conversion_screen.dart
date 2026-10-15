import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/presentation/conversion_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_timeline.dart';

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

/// Les quatre étapes, tirées du statut réel (frise partagée).
class _Steps extends StatelessWidget {
  const _Steps({required this.conversion});

  final Conversion conversion;

  @override
  Widget build(BuildContext context) {
    final step = conversion.step;
    final parts = conversion.partCount;
    final ratio = conversion.synthesisRatio;
    VoxStepState state(int index) => index < step || step == 4
        ? VoxStepState.done
        : index == step
        ? VoxStepState.active
        : VoxStepState.pending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                'Étape $step sur 4',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.vox.accent,
                ),
              ),
            ),
            const SizedBox(height: VoxSpacing.sm),
            VoxTimeline(
              steps: [
                VoxStep(
                  title: 'Préparation du texte',
                  detail: 'Découpage en phrases pour la voix',
                  state: state(1),
                ),
                VoxStep(
                  title: 'Synthèse vocale',
                  detail: step == 2
                      ? [
                          if (parts != null && parts > 0)
                            _partLabel(conversion.partsReady, parts),
                          if (ratio != null) '${(ratio * 100).floor()} %',
                        ].join(' · ')
                      : 'La voix lit votre texte',
                  state: state(2),
                  progress: ratio,
                ),
                VoxStep(
                  title: 'Assemblage',
                  detail: 'Parties audio et texte synchronisé mot à mot',
                  state: state(3),
                ),
                VoxStep(
                  title: 'Livre audio prêt',
                  detail: parts != null && step == 4
                      ? (parts > 1 ? '$parts parties' : '$parts partie')
                      : 'À écouter, même hors ligne',
                  state: state(4),
                ),
              ],
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
