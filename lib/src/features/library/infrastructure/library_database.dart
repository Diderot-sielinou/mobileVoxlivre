import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'library_database.g.dart';

/// Un livre en cache : le JSON de l'API tel quel (ADR-0006), dans l'ordre
/// de la réponse ([rank]).
class CachedLibraryItems extends Table {
  TextColumn get documentId => text()();
  IntColumn get rank => integer()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

/// Une seule ligne (`id = 0`) : l'instant du dernier rafraîchissement.
class LibraryCacheState extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get refreshedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// La fiche d'un document en cache : le JSON de `GET /v1/documents/:id`
/// et celui de sa table des matières (ADR-0006).
class CachedDocuments extends Table {
  TextColumn get documentId => text()();
  TextColumn get payload => text()();
  TextColumn get outline => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

/// Base locale de la bibliothèque (`library.sqlite`), propre à la
/// fonctionnalité (ADR-0006).
@DriftDatabase(tables: [CachedLibraryItems, LibraryCacheState, CachedDocuments])
class LibraryDatabase extends _$LibraryDatabase {
  LibraryDatabase(super.executor);

  /// Base du téléphone, ouverte à la première requête.
  factory LibraryDatabase.open() =>
      LibraryDatabase(driftDatabase(name: 'library'));

  /// v2 : fiches des documents.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(cachedDocuments);
    },
  );
}
