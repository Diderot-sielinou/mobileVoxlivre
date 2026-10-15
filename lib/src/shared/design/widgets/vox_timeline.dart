import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// État d'une étape de [VoxTimeline].
enum VoxStepState { done, active, pending }

/// Une étape : titre, détail, et une barre de progression si elle avance.
@immutable
final class VoxStep {
  const VoxStep({
    required this.title,
    required this.detail,
    required this.state,
    this.progress,
  });

  final String title;
  final String detail;
  final VoxStepState state;

  /// De 0 à 1 ; affichée seulement pour l'étape en cours.
  final double? progress;
}

/// Frise verticale d'étapes (maquettes « Analyse en cours » et « Génération
/// en cours ») : icône **et** état écrit — jamais la couleur seule ; le
/// trait se remplit de haut en bas (400 ms par étape), sans animation si
/// « Réduire les animations » est activé.
class VoxTimeline extends StatelessWidget {
  const VoxTimeline({required this.steps, super.key});

  final List<VoxStep> steps;

  /// Durée du remplissage d'un trait.
  static const fill = Duration(milliseconds: 400);

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : fill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            last: i == steps.length - 1,
            duration: duration,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.last,
    required this.duration,
  });

  final VoxStep step;
  final bool last;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final (icon, color, status) = switch (step.state) {
      VoxStepState.done => (Icons.check_circle, colors.success, 'Terminé'),
      VoxStepState.active => (Icons.timelapse, colors.accent, 'En cours'),
      VoxStepState.pending => (
        Icons.radio_button_unchecked,
        colors.textSecondary,
        'En attente',
      ),
    };
    final progress = step.progress;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(icon, color: color),
              if (!last)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: step.state == VoxStepState.done ? 1 : 0),
                    duration: duration,
                    builder: (context, value, _) => CustomPaint(
                      painter: _Connector(
                        filled: value,
                        base: colors.border,
                        fill: colors.success,
                      ),
                      child: const SizedBox(width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: VoxSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : VoxSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: text.titleSmall?.copyWith(
                            color: step.state == VoxStepState.pending
                                ? colors.textSecondary
                                : null,
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
                  Text(step.detail, style: text.bodySmall),
                  if (step.state == VoxStepState.active &&
                      progress != null) ...[
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
          ),
        ],
      ),
    );
  }
}

/// Trait vertical entre deux étapes, rempli de haut en bas.
class _Connector extends CustomPainter {
  const _Connector({
    required this.filled,
    required this.base,
    required this.fill,
  });

  final double filled;
  final Color base;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    const top = gap;
    final bottom = size.height - gap;
    if (bottom <= top) return;
    final x = size.width / 2;
    final paint = Paint()
      ..strokeWidth = 2
      ..color = base;
    canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    if (filled > 0) {
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + (bottom - top) * filled),
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_Connector old) =>
      old.filled != filled || old.base != base || old.fill != fill;
}
