import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Branche les journaux de l'app (paquet `logging`) sur `debugPrint`.
///
/// Chaque zone a son `Logger('<nom>')` ; rien n'est écrit avec `print`.
/// `debugPrint` plutôt que `dart:developer` : ses lignes s'affichent dans le
/// terminal de `flutter run` comme dans VS Code (`dart:developer` n'est vu
/// que par DevTools). [enabled] vaut `false` en release : aucun journal ne
/// sort du téléphone. À appeler une seule fois, au démarrage.
void configureLogging({required bool enabled}) {
  Logger.root.level = enabled ? Level.ALL : Level.OFF;
  Logger.root.onRecord.listen((record) => debugPrint(formatRecord(record)));
}

/// Une ligne de journal : `[zone] NIVEAU message`, puis l'erreur éventuelle.
String formatRecord(LogRecord record) {
  final line = '[${record.loggerName}] ${record.level.name} ${record.message}';
  return record.error == null ? line : '$line — ${record.error}';
}
