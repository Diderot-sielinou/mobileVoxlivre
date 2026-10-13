import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_logo.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';

/// Bibliothèque vide (maquette « Bibliothèque vide ») : inviter à importer.
class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({required this.onImport, super.key});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: VoxSpacing.lg),
        Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: VoxGradients.aube.colors[1].withValues(alpha: 0.3),
                blurRadius: 48,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const ExcludeSemantics(child: VoxLogo(size: 104)),
        ),
        const SizedBox(height: VoxSpacing.lg),
        Text(
          'Importez votre premier PDF',
          style: text.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: VoxSpacing.sm),
        Text(
          'Cours, polycopiés, livres : écoutez-les en suivant le texte '
          'surligné, même hors ligne.',
          style: text.bodyLarge?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: VoxSpacing.lg),
        VoxPrimaryButton(
          label: 'Importer un PDF',
          icon: Icons.add,
          onPressed: onImport,
        ),
        const SizedBox(height: VoxSpacing.md),
        Text(
          'PDF natifs et scannés (reconnaissance du texte automatique).',
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
