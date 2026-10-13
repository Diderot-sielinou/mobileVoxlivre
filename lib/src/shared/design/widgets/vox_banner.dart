import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// Gravité d'un [VoxBanner].
enum VoxBannerTone { warning, error }

/// Bandeau d'information en haut d'un écran : icône **et** texte (un état
/// n'est jamais porté par la couleur seule), annoncé aux lecteurs d'écran.
class VoxBanner extends StatelessWidget {
  const VoxBanner({
    required this.message,
    this.tone = VoxBannerTone.warning,
    this.icon,
    super.key,
  });

  final String message;
  final VoxBannerTone tone;

  /// Icône propre au message (nuage barré pour « hors ligne »…) ; sinon
  /// celle de la gravité.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final color = switch (tone) {
      VoxBannerTone.warning => colors.warning,
      VoxBannerTone.error => colors.error,
    };
    final icon =
        this.icon ??
        switch (tone) {
          VoxBannerTone.warning => Icons.shield_outlined,
          VoxBannerTone.error => Icons.error_outline,
        };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(VoxSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(VoxRadius.chip),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: VoxSpacing.sm + VoxSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
