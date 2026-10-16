import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre une page ou un e-mail hors de l'app (ADR-0014).
abstract interface class LinkOpener {
  /// `false` si rien ne peut l'ouvrir (pas de navigateur, pas de messagerie).
  Future<bool> open(Uri uri);
}

/// [LinkOpener] sur `url_launcher` : navigateur ou messagerie du téléphone.
final class UrlLauncherOpener implements LinkOpener {
  const UrlLauncherOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const UrlLauncherOpener(),
);
