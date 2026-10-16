import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/presentation/document_screen.dart';
import 'package:voxlivre/src/features/library/presentation/library_texts.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_cover.dart';

/// Un livre : couverture générée, titre, statut (icône + texte), détail,
/// et anneau de progression quand la lecture a commencé.
class LibraryCard extends StatelessWidget {
  const LibraryCard({
    required this.item,
    this.onTap,
    this.downloaded = false,
    this.needsConnection = false,
    super.key,
  });

  final LibraryItem item;

  /// Audio sur le téléphone : écoutable sans réseau (ADR-0011).
  final bool downloaded;

  /// Hors ligne et pas téléchargé : atténué, non cliquable.
  final bool needsConnection;

  /// Ouvre la fiche du document.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final look = statusLook(item.status, colors);
    final detail = needsConnection
        ? 'Nécessite une connexion'
        : statusDetail(item);
    final percent = item.progressPercent;
    final showRing =
        percent != null &&
        (item.status == LibraryStatus.inProgress ||
            item.status == LibraryStatus.finished);

    final card = Semantics(
      container: true,
      button: onTap != null,
      enabled: !needsConnection,
      label: [
        item.title,
        look.label,
        if (downloaded) 'Disponible hors ligne',
        if (detail.isNotEmpty) detail,
        if (showRing) '$percent % lu',
      ].join('. '),
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(VoxSpacing.sm + VoxSpacing.xs),
              child: Row(
                children: [
                  HeroMode(
                    enabled: !MediaQuery.disableAnimationsOf(context),
                    child: Hero(
                      tag: coverHeroTag(item.documentId),
                      child: VoxCover(title: item.title),
                    ),
                  ),
                  const SizedBox(width: VoxSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                        const SizedBox(height: VoxSpacing.xs),
                        Row(
                          children: [
                            Icon(look.icon, size: 16, color: look.color),
                            const SizedBox(width: VoxSpacing.xs),
                            Flexible(
                              child: Text(
                                look.label,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelMedium?.copyWith(
                                  color: look.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (needsConnection) ...[
                                Icon(
                                  Icons.cloud_off_outlined,
                                  size: 16,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: VoxSpacing.xs),
                              ],
                              Flexible(
                                child: Text(
                                  detail,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (downloaded) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.offline_pin_outlined,
                                size: 16,
                                color: colors.success,
                              ),
                              const SizedBox(width: VoxSpacing.xs),
                              Text('Hors ligne', style: text.labelMedium),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showRing) ...[
                    const SizedBox(width: VoxSpacing.sm),
                    _Ring(percent: percent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Désactivé : atténué (0,5) en plus du texte « Nécessite une connexion ».
    return needsConnection ? Opacity(opacity: 0.5, child: card) : card;
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    // Assez large pour « 100% » en 14 sp à l'intérieur de l'anneau.
    return SizedBox.square(
      dimension: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 3,
              backgroundColor: colors.border,
              color: colors.accent,
            ),
          ),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.text,
              fontSize: 14,
              fontFeatures: VoxTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
