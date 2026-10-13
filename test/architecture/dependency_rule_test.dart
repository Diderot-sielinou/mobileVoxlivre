// Règle des dépendances de l'architecture hexagonale (ADR-0001), vérifiée
// sur les imports réels de chaque fichier de `lib/src/`. Équivalent mobile
// des « boundaries » ESLint du backend : un import interdit casse la CI.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Bibliothèques techniques interdites dans `domain/` et `application/`.
const _technicalPackages = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod/',
  'package:hooks_riverpod/',
  'package:go_router/',
  'package:dio/',
  'package:drift/',
  'package:sqlite3/',
  'package:flutter_secure_storage/',
  'package:just_audio/',
  'package:audio_service/',
  'package:path_provider/',
  'dart:ui',
];

/// Couches interdites, par couche importatrice (ADR-0001, tableau).
const _forbiddenLayers = {
  'domain': ['application', 'infrastructure', 'presentation'],
  'application': ['infrastructure', 'presentation'],
  'infrastructure': ['presentation'],
  'presentation': ['infrastructure'],
};

/// Un fichier de `lib/src/` : sa zone (`core`, `shared`, `app` ou une
/// fonctionnalité) et sa couche (pour une fonctionnalité).
class _Location {
  _Location(this.zone, this.feature, this.layer);

  final String zone;
  final String? feature;
  final String? layer;
}

_Location? _locate(String pathInSrc) {
  final parts = p.split(pathInSrc);
  if (parts.isEmpty) return null;
  if (parts.first != 'features') return _Location(parts.first, null, null);
  if (parts.length < 3) return null;
  return _Location('features', parts[1], parts[2]);
}

/// Les imports d'un fichier, résolus en chemins relatifs à `lib/src/` quand
/// ils pointent dans l'app (`null` sinon), avec leur texte brut.
Iterable<({String raw, String? inSrc})> _imports(
  File file,
  String srcRoot,
) sync* {
  final pattern = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  for (final match in pattern.allMatches(file.readAsStringSync())) {
    final raw = match.group(1)!;
    if (raw.startsWith('package:voxlivre/src/')) {
      yield (raw: raw, inSrc: raw.substring('package:voxlivre/src/'.length));
    } else if (!raw.contains(':')) {
      final absolute = p.normalize(p.join(file.parent.path, raw));
      yield (
        raw: raw,
        inSrc: p.isWithin(srcRoot, absolute)
            ? p.relative(absolute, from: srcRoot)
            : null,
      );
    } else {
      yield (raw: raw, inSrc: null);
    }
  }
}

/// Violations de la règle pour tous les fichiers de [srcRoot].
List<String> violations(String srcRoot) {
  final found = <String>[];
  final files = Directory(srcRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.path.endsWith('.dart') &&
            !f.path.endsWith('.g.dart') &&
            !f.path.endsWith('.freezed.dart'),
      );
  for (final file in files) {
    final relative = p.relative(file.path, from: srcRoot);
    final from = _locate(relative);
    if (from == null) continue;
    for (final import in _imports(file, srcRoot)) {
      final pure =
          from.zone == 'core' ||
          from.layer == 'domain' ||
          from.layer == 'application';
      if (pure && _technicalPackages.any(import.raw.startsWith)) {
        found.add('$relative importe ${import.raw} (couche pure)');
      }
      final target = import.inSrc == null ? null : _locate(import.inSrc!);
      if (target == null) continue;
      if (from.zone == 'core' && target.zone != 'core') {
        found.add('$relative importe ${import.raw} (core ne dépend de rien)');
      }
      if (from.zone != 'features') continue;
      if (target.zone == 'app') {
        found.add('$relative importe ${import.raw} (app est la racine)');
      }
      if (target.zone == 'features' && target.feature != from.feature) {
        found.add('$relative importe ${import.raw} (une autre fonctionnalité)');
      }
      if (target.zone == 'features' &&
          target.feature == from.feature &&
          (_forbiddenLayers[from.layer] ?? const []).contains(target.layer)) {
        found.add(
          '$relative importe ${import.raw} (${from.layer} → ${target.layer})',
        );
      }
      if (from.layer == 'domain' && target.zone == 'shared') {
        found.add(
          "$relative importe ${import.raw} (domain n'importe que core)",
        );
      }
    }
  }
  return found;
}

void main() {
  test('lib/src respecte la règle des dépendances (ADR-0001)', () {
    expect(violations(p.join('lib', 'src')), isEmpty);
  });

  group('le contrôle détecte', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('voxlivre_arch_'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String path, String content) {
      File(p.join(root.path, path))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('Flutter dans domain, et infrastructure dans application', () {
      write(
        'features/player/domain/word.dart',
        "import 'package:flutter/widgets.dart';",
      );
      write(
        'features/player/application/play.dart',
        "import '../infrastructure/audio.dart';",
      );
      write('features/player/infrastructure/audio.dart', '');

      expect(violations(root.path), [
        contains('domain/word.dart importe package:flutter/widgets.dart'),
        contains('application/play.dart importe ../infrastructure/audio.dart'),
      ]);
    });

    test(
      "l'intérieur d'une autre fonctionnalité, et core qui dépend d'ailleurs",
      () {
        write(
          'features/player/application/play.dart',
          "import 'package:voxlivre/src/features/library/domain/book.dart';",
        );
        write('features/library/domain/book.dart', '');
        write(
          'core/x.dart',
          "import 'package:voxlivre/src/shared/theme.dart';",
        );
        write('shared/theme.dart', '');

        expect(violations(root.path), hasLength(2));
      },
    );

    test('rien pour des imports autorisés', () {
      write(
        'features/player/presentation/screen.dart',
        "import 'package:flutter/material.dart';\nimport '../application/play.dart';\nimport 'package:voxlivre/src/core/result.dart';",
      );
      write(
        'features/player/application/play.dart',
        "import '../domain/word.dart';",
      );
      write(
        'features/player/domain/word.dart',
        "import 'package:voxlivre/src/core/result.dart';",
      );
      write('core/result.dart', '');

      expect(violations(root.path), isEmpty);
    });
  });
}
