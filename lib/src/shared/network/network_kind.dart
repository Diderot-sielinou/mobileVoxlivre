import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le réseau du moment (ADR-0014).
enum NetworkKind { wifi, mobile, none }

/// Quel réseau l'appareil utilise.
abstract interface class NetworkProbe {
  Future<NetworkKind> current();
}

/// [NetworkProbe] sur `connectivity_plus` : Wi-Fi ou câble = Wi-Fi.
final class ConnectivityProbe implements NetworkProbe {
  const ConnectivityProbe();

  @override
  Future<NetworkKind> current() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkKind.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) return NetworkKind.mobile;
    return NetworkKind.none;
  }
}

final networkProbeProvider = Provider<NetworkProbe>(
  (ref) => const ConnectivityProbe(),
);
