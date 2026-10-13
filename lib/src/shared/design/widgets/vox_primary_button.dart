import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// Action principale d'un écran, sur le dégradé « Braise » avec un halo
/// ambre (en sombre, l'élévation passe par la lumière, pas par l'ombre).
///
/// [onPressed] `null` : désactivé. [loading] : l'action est en cours, le
/// bouton ne réagit plus et l'annonce aux lecteurs d'écran.
class VoxPrimaryButton extends StatelessWidget {
  const VoxPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final enabled = onPressed != null && !loading;
    final foreground = onPressed == null
        ? colors.textSecondary
        : VoxGradients.onBraise;
    final radius = BorderRadius.circular(VoxRadius.chip);
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: foreground);

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, en cours' : label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : VoxGradients.braise,
          color: onPressed == null ? colors.elevated : null,
          borderRadius: radius,
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: radius,
            child: SizedBox(
              height: VoxSizes.primaryButtonHeight,
              width: double.infinity,
              child: Center(
                child: loading
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: labelStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: VoxSpacing.sm),
                            Icon(icon, size: 20, color: foreground),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
