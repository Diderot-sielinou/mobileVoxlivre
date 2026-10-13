import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voxlivre/src/app/home_shell.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_routes.dart';
import 'package:voxlivre/src/features/auth/presentation/code_screen.dart';
import 'package:voxlivre/src/features/auth/presentation/sign_in_screen.dart';
import 'package:voxlivre/src/features/auth/presentation/widgets/account_summary.dart';
import 'package:voxlivre/src/features/onboarding/onboarding_providers.dart';
import 'package:voxlivre/src/features/onboarding/presentation/onboarding_routes.dart';
import 'package:voxlivre/src/features/onboarding/presentation/onboarding_screen.dart';

/// Chemins des onglets : une constante par route, jamais de chaîne répétée.
abstract final class AppRoutes {
  static const library = '/library';
  static const import = '/import';
  static const stats = '/stats';
  static const profile = '/profile';
}

/// Garde de connexion (ADR-0005) : au premier lancement sans session,
/// l'onboarding ; sans session, seule la connexion est ouverte ; avec une
/// session, connexion et onboarding ramènent à la Bibliothèque.
@visibleForTesting
String? guard({
  required bool signedIn,
  required bool onboarded,
  required String location,
}) {
  final onWelcome = location == OnboardingRoutes.welcome;
  final onSignIn = location.startsWith(AuthRoutes.signIn);
  if (signedIn) return onSignIn || onWelcome ? AppRoutes.library : null;
  if (!onboarded) return onWelcome ? null : OnboardingRoutes.welcome;
  return onSignIn ? null : AuthRoutes.signIn;
}

GoRoute _tab(String path, String title, [Widget? child]) => GoRoute(
  path: path,
  builder: (context, state) => PlaceholderPage(title: title, child: child),
);

/// Routeur de l'app, rafraîchi à chaque changement de session.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final onboarding = ref.watch(onboardingStoreProvider);
  final refresh = _StreamListenable(session.changes);
  final router = GoRouter(
    initialLocation: AppRoutes.library,
    refreshListenable: refresh,
    redirect: (context, state) => guard(
      signedIn: session.state is SignedIn,
      onboarded: onboarding.completed,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: OnboardingRoutes.welcome,
        builder: (context, state) => OnboardingScreen(
          onFinished: (context) => context.go(AuthRoutes.signIn),
        ),
      ),
      GoRoute(
        path: AuthRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
        routes: [
          GoRoute(
            path: 'code',
            builder: (context, state) => const CodeScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [_tab(AppRoutes.library, 'Bibliothèque')],
          ),
          StatefulShellBranch(routes: [_tab(AppRoutes.import, 'Importer')]),
          StatefulShellBranch(routes: [_tab(AppRoutes.stats, 'Statistiques')]),
          StatefulShellBranch(
            routes: [
              _tab(AppRoutes.profile, 'Profil', const AccountSummary()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Prévient go_router à chaque évènement du flux reçu.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
