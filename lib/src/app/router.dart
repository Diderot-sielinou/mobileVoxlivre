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
import 'package:voxlivre/src/features/conversion/presentation/conversion_screen.dart';
import 'package:voxlivre/src/features/conversion/presentation/convert_screen.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/features/library/presentation/document_screen.dart';
import 'package:voxlivre/src/features/library/presentation/import_screen.dart';
import 'package:voxlivre/src/features/library/presentation/library_screen.dart';
import 'package:voxlivre/src/features/library/presentation/review_screen.dart';
import 'package:voxlivre/src/features/onboarding/onboarding_providers.dart';
import 'package:voxlivre/src/features/onboarding/presentation/onboarding_routes.dart';
import 'package:voxlivre/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/features/player/presentation/offline_card.dart';
import 'package:voxlivre/src/features/player/presentation/player_screen.dart';

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

/// Ouvre le lecteur d'une conversion (ADR-0010).
void _listen(BuildContext context, String conversionId, String title) =>
    unawaited(
      context.push(
        Uri(
          path: '${AppRoutes.library}/listen/$conversionId',
          queryParameters: {'title': title},
        ).toString(),
      ),
    );

/// Conversions lisibles sans réseau (ADR-0011).
Set<String> _downloaded(WidgetRef ref) =>
    ref.watch(downloadedBooksProvider).value ?? const {};

/// Routeur de l'app, rafraîchi à chaque changement de session.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);
  final onboarding = ref.watch(onboardingStoreProvider);
  final refresh = _StreamListenable(session.changes);
  final root = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: root,
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
            routes: [
              GoRoute(
                path: AppRoutes.library,
                // Livres téléchargés fournis par le lecteur (ADR-0011).
                builder: (context, state) => Consumer(
                  builder: (context, ref, _) => LibraryScreen(
                    onImport: () => context.go(AppRoutes.import),
                    onOpenDocument: (id) =>
                        context.push('${AppRoutes.library}/documents/$id'),
                    onListen: (conversionId, title) =>
                        _listen(context, conversionId, title),
                    downloaded: _downloaded(ref),
                  ),
                ),
                routes: [
                  // Lecteur (ADR-0010), ouvert par la route comme la
                  // conversion (ADR-0008). Plein écran : au-dessus du shell.
                  GoRoute(
                    path: 'listen/:conversionId',
                    parentNavigatorKey: root,
                    builder: (context, state) => PlayerScreen(
                      key: ValueKey(state.pathParameters['conversionId']),
                      conversionId: state.pathParameters['conversionId']!,
                      title: state.uri.queryParameters['title'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'documents/:id',
                    // Une clé par document : passer d'une fiche à une autre
                    // (après un import) donne un nouvel état, donc une
                    // nouvelle lecture.
                    builder: (context, state) => Consumer(
                      builder: (context, ref, _) => DocumentScreen(
                        key: ValueKey(state.pathParameters['id']),
                        documentId: state.pathParameters['id']!,
                        onOpenText: () => context.push(
                          '${AppRoutes.library}/documents/'
                          '${state.pathParameters['id']}/text',
                        ),
                        onConvert: (title, chars) => context.push(
                          Uri(
                            path:
                                '${AppRoutes.library}/documents/'
                                '${state.pathParameters['id']}/convert',
                            queryParameters: {
                              'title': title,
                              'chars': '$chars',
                            },
                          ).toString(),
                        ),
                        onOpenConversion: (conversionId) => context.push(
                          '${AppRoutes.library}/documents/'
                          '${state.pathParameters['id']}/conversions/'
                          '$conversionId',
                        ),
                        onListen: (conversionId, title) =>
                            _listen(context, conversionId, title),
                        // Écoute hors ligne, fournie par le lecteur (ADR-0011).
                        offlineCard: (conversionId) =>
                            OfflineCard(conversionId: conversionId),
                        downloaded: _downloaded(ref),
                        onRemoveDownload: (conversionId, title) async {
                          if (!await confirmRemoveDownload(context, title)) {
                            return false;
                          }
                          await ref.read(removeDownloadProvider)(conversionId);
                          return true;
                        },
                        onDeleted: (conversionId) => unawaited(
                          ref.read(removeDownloadProvider)(conversionId),
                        ),
                      ),
                    ),
                    routes: [
                      // Passage vers la conversion par la route (ADR-0008).
                      GoRoute(
                        path: 'convert',
                        builder: (context, state) => ConvertScreen(
                          documentId: state.pathParameters['id']!,
                          title: state.uri.queryParameters['title'] ?? '',
                          chars:
                              int.tryParse(
                                state.uri.queryParameters['chars'] ?? '',
                              ) ??
                              0,
                          onStarted: (conversionId) {
                            unawaited(
                              ref.read(refreshLibraryProvider)(force: true),
                            );
                            context.pushReplacement(
                              Uri(
                                path:
                                    '${AppRoutes.library}/documents/'
                                    '${state.pathParameters['id']}/'
                                    'conversions/$conversionId',
                                queryParameters: {
                                  'title':
                                      state.uri.queryParameters['title'] ?? '',
                                },
                              ).toString(),
                            );
                          },
                        ),
                      ),
                      GoRoute(
                        path: 'conversions/:conversionId',
                        builder: (context, state) => ConversionScreen(
                          conversionId: state.pathParameters['conversionId']!,
                          title: state.uri.queryParameters['title'] ?? '',
                          onLibrary: () => context.go(AppRoutes.library),
                          onRetry: context.pop,
                          onListen: () => _listen(
                            context,
                            state.pathParameters['conversionId']!,
                            state.uri.queryParameters['title'] ?? '',
                          ),
                          onFinished: () => unawaited(
                            ref.read(refreshLibraryProvider)(force: true),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'text',
                        builder: (context, state) => ReviewScreen(
                          documentId: state.pathParameters['id']!,
                          onReviewed: context.pop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.import,
                builder: (context, state) => ImportScreen(
                  onImported: (id) =>
                      context.go('${AppRoutes.library}/documents/$id'),
                ),
              ),
            ],
          ),
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
