import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'player_database.g.dart';

/// Position de lecture d'une conversion, sur l'appareil (ADR-0010).
// Nom distinct de `ReadingPosition` du domaine.
@DataClassName('StoredPosition')
class ReadingPositions extends Table {
  TextColumn get conversionId => text()();
  IntColumn get wordIndex => integer()();
  IntColumn get audioMs => integer()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {conversionId};
}

/// Base locale du lecteur (`player.sqlite`), propre à la fonctionnalité
/// (ADR-0006).
@DriftDatabase(tables: [ReadingPositions])
class PlayerDatabase extends _$PlayerDatabase {
  PlayerDatabase(super.executor);

  /// Base du téléphone, ouverte à la première requête.
  factory PlayerDatabase.open() =>
      PlayerDatabase(driftDatabase(name: 'player'));

  @override
  int get schemaVersion => 1;
}
