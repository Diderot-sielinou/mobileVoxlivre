import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages de l'appareil (ADR-0014) : pas du compte, aucune donnée
/// personnelle ; ils restent après la déconnexion.
@immutable
final class DeviceSettings {
  const DeviceSettings({
    this.defaultVoiceId,
    this.speed = 1,
    this.wifiOnly = true,
  });

  /// Voix préchoisie à la conversion ; `null` : celle du serveur.
  final String? defaultVoiceId;

  /// Vitesse appliquée à l'ouverture du lecteur.
  final double speed;

  /// Télécharger un livre en données mobiles demande confirmation.
  final bool wifiOnly;

  DeviceSettings copyWith({
    String? defaultVoiceId,
    double? speed,
    bool? wifiOnly,
  }) => DeviceSettings(
    defaultVoiceId: defaultVoiceId ?? this.defaultVoiceId,
    speed: speed ?? this.speed,
    wifiOnly: wifiOnly ?? this.wifiOnly,
  );
}

/// Où les réglages sont gardés.
abstract interface class DeviceSettingsStore {
  DeviceSettings read();

  Future<void> write(DeviceSettings settings);
}

/// En mémoire (tests, et avant l'ouverture du stockage).
final class MemoryDeviceSettingsStore implements DeviceSettingsStore {
  MemoryDeviceSettingsStore([this._settings = const DeviceSettings()]);

  DeviceSettings _settings;

  @override
  DeviceSettings read() => _settings;

  @override
  Future<void> write(DeviceSettings settings) async => _settings = settings;
}

/// Dans `shared_preferences`, lu une fois au démarrage.
final class PrefsDeviceSettingsStore implements DeviceSettingsStore {
  PrefsDeviceSettingsStore._(this._prefs);

  static const _voice = 'settings_default_voice';
  static const _speed = 'settings_speed';
  static const _wifiOnly = 'settings_wifi_only';

  static Future<PrefsDeviceSettingsStore> open() async =>
      PrefsDeviceSettingsStore._(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {_voice, _speed, _wifiOnly},
          ),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  DeviceSettings read() => DeviceSettings(
    defaultVoiceId: _prefs.getString(_voice),
    speed: _prefs.getDouble(_speed) ?? 1,
    wifiOnly: _prefs.getBool(_wifiOnly) ?? true,
  );

  @override
  Future<void> write(DeviceSettings settings) async {
    final voice = settings.defaultVoiceId;
    await (
      voice == null ? _prefs.remove(_voice) : _prefs.setString(_voice, voice),
      _prefs.setDouble(_speed, settings.speed),
      _prefs.setBool(_wifiOnly, settings.wifiOnly),
    ).wait;
  }
}

/// Fourni par le bootstrap ; en mémoire par défaut.
final deviceSettingsStoreProvider = Provider<DeviceSettingsStore>(
  (ref) => MemoryDeviceSettingsStore(),
);

/// Les réglages, à jour à chaque changement.
final class DeviceSettingsController extends Notifier<DeviceSettings> {
  @override
  DeviceSettings build() => ref.watch(deviceSettingsStoreProvider).read();

  Future<void> update(DeviceSettings settings) async {
    state = settings;
    await ref.read(deviceSettingsStoreProvider).write(settings);
  }
}

final deviceSettingsProvider =
    NotifierProvider<DeviceSettingsController, DeviceSettings>(
      DeviceSettingsController.new,
    );
