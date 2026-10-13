import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// Couverture générée d'un document PDF sans image (design system §1.2) :
/// deux teintes de la palette « Aube » tirées du titre, et son initiale.
/// Le même titre donne toujours la même couverture. Décorative : le titre
/// est lu à côté.
class VoxCover extends StatelessWidget {
  const VoxCover({
    required this.title,
    this.width = 56,
    this.height = 72,
    super.key,
  });

  final String title;
  final double width;
  final double height;

  /// Paires de teintes, toutes assez sombres pour une initiale blanche.
  static const palettes = [
    [Color(0xFF312E81), Color(0xFF7C3AED)],
    [Color(0xFF1E1B4B), Color(0xFF6165F0)],
    [Color(0xFF4C1D95), Color(0xFFB45309)],
    [Color(0xFF312E81), Color(0xFF9D174D)],
    [Color(0xFF1E1B4B), Color(0xFFB45309)],
  ];

  /// Index de palette stable pour [title] (empreinte des points de code).
  static int paletteFor(String title) =>
      title.runes.fold(0, (sum, rune) => (sum * 31 + rune) & 0x7fffffff) %
      palettes.length;

  @override
  Widget build(BuildContext context) {
    final colors = palettes[paletteFor(title)];
    final initial = title.trim().isEmpty
        ? '?'
        : title.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoxRadius.chip),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        padding: const EdgeInsets.all(VoxSpacing.sm),
        alignment: Alignment.topLeft,
        child: Text(
          initial,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: VoxGradients.onAube,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
