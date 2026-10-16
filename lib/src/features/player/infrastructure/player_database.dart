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

  /// Pas encore reçue par le serveur (ADR-0011).
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {conversionId};
}

/// Un livre téléchargé (ADR-0011) : son manifeste, sans URL.
@DataClassName('StoredBookRow')
class DownloadedBooks extends Table {
  TextColumn get conversionId => text()();
  TextColumn get manifestJson => text()();
  BoolColumn get complete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {conversionId};
}

/// Partie dont les deux fichiers ont la bonne empreinte.
@DataClassName('VerifiedPartRow')
class VerifiedParts extends Table {
  TextColumn get conversionId => text()();
  IntColumn get partIndex => integer()();

  @override
  Set<Column<Object>> get primaryKey => {conversionId, partIndex};
}

/// Un marque-page (ADR-0012), trace de suppression comprise.
@DataClassName('StoredBookmark')
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text()();
  IntColumn get pageNumber => integer()();
  IntColumn get wordIndex => integer()();
  TextColumn get excerpt => text()();
  TextColumn get note => text()();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Base locale du lecteur (`player.sqlite`), propre à la fonctionnalité
/// (ADR-0006).
@DriftDatabase(
  tables: [ReadingPositions, DownloadedBooks, VerifiedParts, Bookmarks],
)
class PlayerDatabase extends _$PlayerDatabase {
  PlayerDatabase(super.executor);

  /// Base du téléphone, ouverte à la première requête.
  factory PlayerDatabase.open() =>
      PlayerDatabase(driftDatabase(name: 'player'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 (ADR-0011) : positions à envoyer, livres hors ligne.
      if (from < 2) {
        await m.addColumn(readingPositions, readingPositions.pending);
        await m.createTable(downloadedBooks);
        await m.createTable(verifiedParts);
      }
      // v3 (ADR-0012) : marque-pages.
      if (from < 3) await m.createTable(bookmarks);
    },
  );
}
