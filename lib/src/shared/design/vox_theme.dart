import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';

/// Construit les `ThemeData` Material 3 à partir des jetons : les composants
/// Material (boutons, champs, feuilles) héritent du design system sans
/// réglage par écran.
abstract final class VoxTheme {
  /// Thème sombre, par défaut.
  static ThemeData get dark => _build(VoxColors.dark, Brightness.dark);

  /// Thème clair « Papier ».
  static ThemeData get paper => _build(VoxColors.paper, Brightness.light);

  static ThemeData _build(VoxColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.error,
      onError: brightness == Brightness.dark ? c.background : c.onPrimary,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.elevated,
      outline: c.border,
      outlineVariant: c.border,
    );
    final textTheme = VoxTypography.textTheme(
      text: c.text,
      textSecondary: c.textSecondary,
    );
    const buttonSize = Size(VoxSizes.minTouchTarget, VoxSizes.minTouchTarget);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VoxRadius.chip),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: VoxFonts.ui,
      textTheme: textTheme,
      // Garantit des zones tactiles de 48 dp même sur les petits composants.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VoxRadius.card),
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: c.text,
          side: BorderSide(color: c.border),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        // Ambre, comme les liens des maquettes : l'indigo primaire n'atteint
        // pas 4,5:1 en texte sur le fond sombre (4,30:1).
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: c.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: buttonSize),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoxRadius.chip),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoxRadius.chip),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoxRadius.chip),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.elevated,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VoxRadius.sheet),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primary.withValues(alpha: 0.24),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
    );
  }
}
