import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/voxlivre_app.dart';
import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

import '../src/features/auth/fakes.dart';

/// Horloge réglable à la main.
final class FixedClock implements Clock {
  FixedClock(this.instant);

  DateTime instant;

  void advance(Duration d) => instant = instant.add(d);

  @override
  DateTime now() => instant;
}

/// L'app entière, ports remplacés par des faux.
typedef Harness = ({
  FakeAuthGateway gateway,
  AuthSession session,
  MemorySessionStore store,
  FixedClock clock,
});

/// Lance l'app ; avec [token], la session est déjà ouverte.
Future<Harness> pumpVoxlivre(
  WidgetTester tester, {
  String? token,
  bool reduceMotion = false,
}) async {
  final gateway = FakeAuthGateway();
  final store = MemorySessionStore(token);
  final session = AuthSession(store, token: token);
  final clock = FixedClock(DateTime.utc(2026, 10, 13, 10));
  if (reduceMotion) {
    // Réglage « Supprimer les animations » du téléphone.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWithValue(session),
        authGatewayProvider.overrideWithValue(gateway),
        clockProvider.overrideWithValue(clock),
      ],
      child: const VoxlivreApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (gateway: gateway, session: session, store: store, clock: clock);
}
