import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// « Reprendre la lecture » : le livre écouté le plus récemment, sur le
/// dégradé « Aube » (en-tête de l'accueil, design system §1.2).
class ResumeCard extends StatelessWidget {
  const ResumeCard({required this.item, super.key});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const onAube = VoxGradients.onAube;
    final percent = item.progressPercent;
    final remaining = item.remaining;
    final details = [
      if (percent != null) '$percent % lu',
      if (remaining != null) 'Reste ${VoxFormat.listening(remaining)}',
    ].join(' · ');

    return Semantics(
      container: true,
      label: 'Reprendre la lecture. ${item.title}. $details',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(VoxSpacing.md + VoxSpacing.xs),
          decoration: BoxDecoration(
            gradient: VoxGradients.aube,
            borderRadius: BorderRadius.circular(VoxRadius.card),
          ),
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
                Text(details, style: text.bodyMedium?.copyWith(color: onAube)),
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
    );
  }
}
