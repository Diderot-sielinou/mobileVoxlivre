import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/app_config.dart';
import 'package:voxlivre/src/app/voxlivre_app.dart';
import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/account/account_providers.dart';
import 'package:voxlivre/src/features/account/domain/app_info.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/features/conversion/conversion_providers.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/features/onboarding/domain/onboarding_store.dart';
import 'package:voxlivre/src/features/onboarding/onboarding_providers.dart';
import 'package:voxlivre/src/features/payment/payment_providers.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/shared/links/link_opener.dart';
import 'package:voxlivre/src/shared/network/network_kind.dart';
import 'package:voxlivre/src/shared/settings/device_settings.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

import '../src/features/auth/fakes.dart';
import '../src/features/conversion/fakes.dart';
import '../src/features/library/fakes.dart';
import '../src/features/payment/fakes.dart';
import '../src/features/player/fakes.dart';

/// Mémoire du premier lancement, en mémoire.
final class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({required this.completed});

  @override
  bool completed;

  @override
  Future<void> complete() async => completed = true;
}

/// Configuration de test : API et site fictifs (ADR-0003, ADR-0014).
final AppConfig testConfig = switch (AppConfig.parse(
  env: 'dev',
  apiBaseUrl: 'https://api.test',
  siteUrl: 'https://site.test',
  supportEmail: 'aide@site.test',
  googleServerClientId: 'test-web.apps.googleusercontent.com',
)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError(error.message),
};

/// Réseau réglable à la main (Wi-Fi par défaut).
final class FakeNetworkProbe implements NetworkProbe {
  NetworkKind kind = NetworkKind.wifi;

  @override
  Future<NetworkKind> current() async => kind;
}

/// Liens « ouverts » (navigateur, messagerie), retenus pour les tests.
final class FakeLinkOpener implements LinkOpener {
  final opened = <Uri>[];
  bool works = true;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return works;
  }
}

final class FakeAppInfo implements AppInfo {
  @override
  Future<String> version() async => '0.1.0 (1)';
}

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
  FakeGoogleAccount google,
  AuthSession session,
  MemorySessionStore store,
  FixedClock clock,
  MemoryOnboardingStore onboarding,
  FakeLibraryRepository library,
  FakeDocumentRepository documents,
  FakePdfSource pdfs,
  FakeUploads uploads,
  FakeDocumentTextRepository texts,
  FakeConversionGateway conversions,
  FakePlayerGateway player,
  MemoryPositionStore positions,
  FakeAudioEngine audio,
  MemoryBookFiles books,
  MemoryBookmarkStore bookmarks,
  FakePaymentGateway payments,
  MemoryPaymentMemory paymentMemory,
  SequenceKeys keys,
  FakeNetworkProbe network,
  MemoryDeviceSettingsStore settings,
  FakeLinkOpener links,
});

/// Lance l'app ; avec [token], la session est déjà ouverte ; [onboarded]
/// `false` : premier lancement.
Future<Harness> pumpVoxlivre(
  WidgetTester tester, {
  String? token,
  bool onboarded = true,
  bool reduceMotion = false,
  FakeLibraryRepository? library,
  FakeDocumentRepository? documents,
  FakePdfSource? pdfs,
  FakeUploads? uploads,
  FakeDocumentTextRepository? texts,
  FakeConversionGateway? conversions,
  FakePlayerGateway? player,
  MemoryPositionStore? positions,
  FakeAudioEngine? audio,
  MemoryBookFiles? books,
  MemoryBookmarkStore? bookmarks,
  FakePaymentGateway? payments,
  MemoryPaymentMemory? paymentMemory,
  DeviceSettings deviceSettings = const DeviceSettings(),
  bool settle = true,
}) async {
  final playerGateway = player ?? FakePlayerGateway();
  final bookFiles = books ?? MemoryBookFiles(playerGateway.disk);
  final positionStore = positions ?? MemoryPositionStore();
  final bookmarkStore = bookmarks ?? MemoryBookmarkStore();
  final paymentGateway = payments ?? FakePaymentGateway();
  final memory = paymentMemory ?? MemoryPaymentMemory();
  final keys = SequenceKeys();
  final network = FakeNetworkProbe();
  final settings = MemoryDeviceSettingsStore(deviceSettings);
  final links = FakeLinkOpener();
  final audioEngine = audio ?? FakeAudioEngine();
  final conversionGateway = conversions ?? FakeConversionGateway();
  final textRepository = texts ?? FakeDocumentTextRepository();
  final pdfSource = pdfs ?? FakePdfSource();
  final uploader = uploads ?? FakeUploads();
  final shelf = library ?? FakeLibraryRepository();
  final sheets = documents ?? FakeDocumentRepository();
  final onboarding = MemoryOnboardingStore(completed: onboarded);
  final gateway = FakeAuthGateway();
  final google = FakeGoogleAccount();
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
        appConfigProvider.overrideWithValue(testConfig),
        authSessionProvider.overrideWithValue(session),
        authGatewayProvider.overrideWithValue(gateway),
        googleAccountProvider.overrideWithValue(google),
        googleServerClientIdProvider.overrideWithValue(
          testConfig.googleServerClientId,
        ),
        clockProvider.overrideWithValue(clock),
        onboardingStoreProvider.overrideWithValue(onboarding),
        libraryRepositoryProvider.overrideWithValue(shelf),
        documentRepositoryProvider.overrideWithValue(sheets),
        pdfSourceProvider.overrideWithValue(pdfSource),
        documentUploadsProvider.overrideWithValue(uploader),
        documentTextRepositoryProvider.overrideWithValue(textRepository),
        conversionGatewayProvider.overrideWithValue(conversionGateway),
        playerGatewayProvider.overrideWithValue(playerGateway),
        positionStoreProvider.overrideWithValue(positionStore),
        audioEngineProvider.overrideWithValue(audioEngine),
        bookFilesProvider.overrideWithValue(bookFiles),
        bookmarkStoreProvider.overrideWithValue(bookmarkStore),
        idGeneratorProvider.overrideWithValue(SequenceIds()),
        paymentGatewayProvider.overrideWithValue(paymentGateway),
        paymentMemoryProvider.overrideWithValue(memory),
        keyGeneratorProvider.overrideWithValue(keys),
        networkProbeProvider.overrideWithValue(network),
        deviceSettingsStoreProvider.overrideWithValue(settings),
        linkOpenerProvider.overrideWithValue(links),
        appInfoProvider.overrideWithValue(FakeAppInfo()),
      ],
      child: const VoxlivreApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Le splash animé (1,35 s) passe, le reste peut encore travailler.
    await tester.pump(const Duration(seconds: 2));
  }
  return (
    gateway: gateway,
    google: google,
    session: session,
    store: store,
    clock: clock,
    onboarding: onboarding,
    library: shelf,
    documents: sheets,
    pdfs: pdfSource,
    uploads: uploader,
    texts: textRepository,
    conversions: conversionGateway,
    player: playerGateway,
    positions: positionStore,
    audio: audioEngine,
    books: bookFiles,
    bookmarks: bookmarkStore,
    payments: paymentGateway,
    paymentMemory: memory,
    keys: keys,
    network: network,
    settings: settings,
    links: links,
  );
}
