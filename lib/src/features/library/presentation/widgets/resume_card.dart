import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// « Reprendre la lecture » : le livre écouté le plus récemment, sur le
/// dégradé « Aube » (en-tête de l'accueil, design system §1.2).
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    required this.item,
    this.onTap,
    this.needsConnection = false,
    super.key,
  });

  final LibraryItem item;

  /// Hors ligne et pas téléchargé (ADR-0011) : atténuée, non cliquable.
  final bool needsConnection;

  /// Reprend l'écoute dans le lecteur.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const onAube = VoxGradients.onAube;
    final percent = item.progressPercent;
    final remaining = item.remaining;
    final details = [
      if (percent != null) '$percent % lu',
      if (needsConnection)
        'Nécessite une connexion'
      else if (remaining != null)
        'Reste ${VoxFormat.listening(remaining)}',
    ].join(' · ');

    final radius = BorderRadius.circular(VoxRadius.card);
    final card = Semantics(
      container: true,
      button: onTap != null,
      enabled: !needsConnection,
      label: 'Reprendre la lecture. ${item.title}. $details',
      child: ExcludeSemantics(
        child: Ink(
          decoration: BoxDecoration(
            gradient: VoxGradients.aube,
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(VoxSpacing.md + VoxSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: onAube, size: 18),
                      const SizedBox(width: VoxSpacing.xs),
                      Flexible(
                        child: Text(
                          'REPRENDRE LA LECTURE',
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: onAube,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VoxSpacing.sm),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineMedium?.copyWith(color: onAube),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: VoxSpacing.xs),
                    Text(
                      details,
                      style: text.bodyMedium?.copyWith(color: onAube),
                    ),
                  ],
                  if (percent != null) ...[
                    const SizedBox(height: VoxSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 6,
                        backgroundColor: onAube.withValues(alpha: 0.25),
                        color: onAube,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return needsConnection ? Opacity(opacity: 0.5, child: card) : card;
  }
}
