import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';

/// « Table des matières » (maquette) : les 5 premières entrées, en retrait
/// par niveau, page à droite ; « Tout voir (n) » ouvre la liste complète.
class OutlineSection extends StatelessWidget {
  const OutlineSection({required this.entries, super.key});

  final List<OutlineEntry> entries;

  /// Entrées montrées sur la fiche.
  static const preview = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_bulleted, color: colors.accent),
            const SizedBox(width: VoxSpacing.sm),
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Table des matières', style: text.titleMedium),
              ),
            ),
            if (entries.length > preview)
              TextButton(
                onPressed: () => _showAll(context),
                child: Text('Tout voir (${entries.length})'),
              ),
          ],
        ),
        const SizedBox(height: VoxSpacing.sm),
        Card(
          child: Column(
            children: [
              for (final entry in entries.take(preview)) OutlineRow(entry),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAll(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Ouverture 300 ms / fermeture 200 ms (design system §2).
      sheetAnimationStyle: AnimationStyle(
        duration: reduceMotion ? Duration.zero : VoxMotion.sheetIn,
        reverseDuration: reduceMotion ? Duration.zero : VoxMotion.sheetOut,
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            VoxSpacing.md,
            0,
            VoxSpacing.md,
            VoxSpacing.xl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(VoxSpacing.sm),
              child: Text(
                'Table des matières',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final entry in entries) OutlineRow(entry),
          ],
        ),
      ),
    );
  }
}

/// Une entrée : retrait selon le niveau, page en chiffres tabulaires.
class OutlineRow extends StatelessWidget {
  const OutlineRow(this.entry, {super.key});

  final OutlineEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final top = entry.level <= 1;
    return Semantics(
      label: '${entry.title}, page ${entry.pageNumber}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          VoxSpacing.md + (entry.level.clamp(1, 3) - 1) * VoxSpacing.md,
          VoxSpacing.sm + VoxSpacing.xs,
          VoxSpacing.md,
          VoxSpacing.sm + VoxSpacing.xs,
        ),
        child: Row(
          children: [
            if (top) ...[
              Icon(Icons.bookmark_outline, size: 18, color: colors.accent),
              const SizedBox(width: VoxSpacing.sm),
            ],
            Expanded(
              child: Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: top ? text.titleSmall : text.bodyMedium,
              ),
            ),
            const SizedBox(width: VoxSpacing.sm),
            Text(
              'p. ${entry.pageNumber}',
              style: text.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontFeatures: VoxTypography.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
