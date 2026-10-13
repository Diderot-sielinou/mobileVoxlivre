import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/app/router.dart';
import 'package:voxlivre/src/shared/design/vox_theme.dart';

/// Racine visuelle : thèmes, langue, routeur.
class VoxlivreApp extends ConsumerWidget {
  const VoxlivreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Voxlivre',
      debugShowCheckedModeBanner: false,
      theme: VoxTheme.paper,
      darkTheme: VoxTheme.dark,
      // Sombre par défaut (design system) ; le choix « Papier » viendra des
      // réglages d'affichage.
      themeMode: ThemeMode.dark,
      // Français seulement : libellés Material (« Retour »…) lus en français
      // par TalkBack.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
