import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/domain/library_repository.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_item_dto.dart';

/// [LibraryRepository] : cache drift, rafraîchi par [LibraryApi] (ADR-0006).
final class DriftLibraryRepository implements LibraryRepository {
  const DriftLibraryRepository(this._db, this._api, this._clock);

  final LibraryDatabase _db;
  final LibraryApi _api;
  final Clock _clock;

  static final _log = Logger('library');

  @override
  Stream<LibrarySnapshot> watch() {
    final items = _db.cachedLibraryItems;
    // Relu quand **l'une ou l'autre** table change : un rafraîchissement
    // d'une bibliothèque vide ne touche que la date (sinon l'écran
    // resterait en chargement pour un nouveau compte).
    return _db
        .customSelect(
          'SELECT ${items.payload.name} AS payload '
          'FROM ${items.actualTableName} '
          'ORDER BY ${items.rank.name}',
          readsFrom: {items, _db.libraryCacheState},
        )
        .watch()
        .asyncMap(
          (rows) async => LibrarySnapshot(
            items: [
              for (final row in rows) ?_decode(row.read<String>('payload')),
            ],
            refreshedAt: await lastRefresh(),
          ),
        );
  }

  @override
  Future<DateTime?> lastRefresh() async {
    final state = await (_db.select(
      _db.libraryCacheState,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    // drift rend l'heure locale : l'app compare tout en UTC (`Clock`).
    return state?.refreshedAt.toUtc();
  }

  @override
  Future<Result<void, Failure>> refresh() async {
    final fetched = await _api.fetchAll();
    switch (fetched) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final items):
        final now = _clock.now();
        await _db.transaction(() async {
          await _db.delete(_db.cachedLibraryItems).go();
          await _db.batch((batch) {
            for (final (rank, json) in items.indexed) {
              final id = (json['document'] as Map<String, Object?>?)?['id'];
              if (id is! String) continue;
              batch.insert(
                _db.cachedLibraryItems,
                CachedLibraryItemsCompanion.insert(
                  documentId: id,
                  rank: rank,
                  payload: jsonEncode(json),
                ),
              );
            }
          });
          await _db
              .into(_db.libraryCacheState)
              .insertOnConflictUpdate(
                LibraryCacheStateCompanion.insert(
                  id: const Value(0),
                  refreshedAt: now,
                ),
              );
        });
        return const Result.ok(null);
    }
  }

  @override
  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_db.cachedLibraryItems).go();
    await _db.delete(_db.libraryCacheState).go();
    await _db.delete(_db.cachedDocuments).go();
    await _db.delete(_db.cachedPages).go();
  });

  /// Un livre que l'app ne sait pas lire (backend plus récent) est écarté
  /// plutôt que de casser toute la bibliothèque.
  static LibraryItem? _decode(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, Object?>;
      return LibraryItemDto.fromJson(json).toDomain();
      // Forme inattendue : erreur de type ou de format.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _log.warning('livre en cache illisible : ${e.runtimeType}');
      return null;
    }
  }
}
