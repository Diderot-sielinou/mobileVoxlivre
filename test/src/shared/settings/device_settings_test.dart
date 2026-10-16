import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:voxlivre/src/shared/settings/device_settings.dart';

void main() {
  test('par défaut : voix du serveur, 1×, seulement en Wi-Fi', () {
    const settings = DeviceSettings();
    expect(settings.defaultVoiceId, isNull);
    expect(settings.speed, 1);
    expect(settings.wifiOnly, isTrue);
    final changed = settings.copyWith(speed: 1.5);
    expect(changed.wifiOnly, isTrue, reason: 'le reste ne bouge pas');
  });

  test('gardés sur l’appareil, relus au démarrage suivant', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = await PrefsDeviceSettingsStore.open();
    expect(store.read().speed, 1);

    await store.write(
      const DeviceSettings(
        defaultVoiceId: 'fr-m2',
        speed: 1.25,
        wifiOnly: false,
      ),
    );
    final again = (await PrefsDeviceSettingsStore.open()).read();
    expect(again.defaultVoiceId, 'fr-m2');
    expect(again.speed, 1.25);
    expect(again.wifiOnly, isFalse);

    await store.write(const DeviceSettings());
    expect(
      (await PrefsDeviceSettingsStore.open()).read().defaultVoiceId,
      isNull,
    );
  });

  test('le contrôleur relit le magasin et y écrit', () async {
    final store = MemoryDeviceSettingsStore();
    final container = ProviderContainer(
      overrides: [deviceSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container
        .read(deviceSettingsProvider.notifier)
        .update(const DeviceSettings(wifiOnly: false));
    expect(container.read(deviceSettingsProvider).wifiOnly, isFalse);
    expect(store.read().wifiOnly, isFalse);
  });
}
