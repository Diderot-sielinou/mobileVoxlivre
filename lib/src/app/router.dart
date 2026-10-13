import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voxlivre/src/app/home_shell.dart';

/// Chemins des onglets : une constante par route, jamais de chaîne répétée.
abstract final class AppRoutes {
  static const library = '/library';
  static const import = '/import';
  static const stats = '/stats';
  static const profile = '/profile';
}

GoRoute _tab(String path, String title) => GoRoute(
  path: path,
  builder: (context, state) => PlaceholderPage(title: title),
);

/// Routeur de l'app. Les écrans des fonctionnalités et la garde de connexion
/// (`redirect`) s'y ajoutent avec leurs étapes.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.library,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [_tab(AppRoutes.library, 'Bibliothèque')],
          ),
          StatefulShellBranch(routes: [_tab(AppRoutes.import, 'Importer')]),
          StatefulShellBranch(routes: [_tab(AppRoutes.stats, 'Statistiques')]),
          StatefulShellBranch(routes: [_tab(AppRoutes.profile, 'Profil')]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
