import 'package:drift/drift.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';

/// [BookmarkStore] dans `player.sqlite` (ADR-0012).
final class DriftBookmarkStore implements BookmarkStore {
  const DriftBookmarkStore(this._db);

  final PlayerDatabase _db;

  @override
  Stream<List<Bookmark>> watch(String documentId) =>
      (_db.select(_db.bookmarks)
            ..where(
              (t) => t.documentId.equals(documentId) & t.deletedAt.isNull(),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.pageNumber),
              (t) => OrderingTerm(expression: t.wordIndex),
            ]))
          .watch()
          .map((rows) => rows.map(_bookmark).toList());

  @override
  Future<List<Bookmark>> all(String documentId) async => [
    for (final row in await (_db.select(
      _db.bookmarks,
    )..where((t) => t.documentId.equals(documentId))).get())
      _bookmark(row),
  ];

  @override
  Future<List<Bookmark>> pending() async => [
    for (final row in await (_db.select(
      _db.bookmarks,
    )..where((t) => t.pending)).get())
      _bookmark(row),
  ];

  @override
  Future<void> save(Bookmark b) => _db
      .into(_db.bookmarks)
      .insertOnConflictUpdate(
        BookmarksCompanion.insert(
          id: b.id,
          documentId: b.documentId,
          pageNumber: b.pageNumber,
          wordIndex: b.wordIndex,
          excerpt: b.excerpt,
          note: b.note,
          needsReview: Value(b.needsReview),
          createdAt: b.createdAt,
          updatedAt: b.updatedAt,
          deletedAt: Value(b.deletedAt),
          pending: Value(b.pending),
        ),
      );

  @override
  Future<void> remove(String id) =>
      (_db.delete(_db.bookmarks)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> clear() => _db.delete(_db.bookmarks).go();

  // drift relit en heure locale : tout est UTC dans l'app.
  static Bookmark _bookmark(StoredBookmark row) => Bookmark(
    id: row.id,
    documentId: row.documentId,
    pageNumber: row.pageNumber,
    wordIndex: row.wordIndex,
    excerpt: row.excerpt,
    note: row.note,
    needsReview: row.needsReview,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    pending: row.pending,
  );
}
