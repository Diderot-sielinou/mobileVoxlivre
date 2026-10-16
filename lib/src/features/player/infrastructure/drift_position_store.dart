import 'package:drift/drift.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';

/// [PositionStore] dans `player.sqlite`.
final class DriftPositionStore implements PositionStore {
  const DriftPositionStore(this._db);

  final PlayerDatabase _db;

  @override
  Future<ReadingPosition?> read(String conversionId) async {
    final row = await (_db.select(
      _db.readingPositions,
    )..where((t) => t.conversionId.equals(conversionId))).getSingleOrNull();
    return row == null ? null : _position(row);
  }

  static ReadingPosition _position(StoredPosition row) => ReadingPosition(
    wordIndex: row.wordIndex,
    audioMs: row.audioMs,
    // drift relit en heure locale : tout est UTC dans l'app.
    recordedAt: row.recordedAt.toUtc(),
  );

  @override
  Future<void> write(String conversionId, ReadingPosition position) => _db
      .into(_db.readingPositions)
      .insertOnConflictUpdate(
        ReadingPositionsCompanion.insert(
          conversionId: conversionId,
          wordIndex: position.wordIndex,
          audioMs: position.audioMs,
          recordedAt: position.recordedAt,
          pending: const Value(true),
        ),
      );

  @override
  Future<void> markSent(String conversionId, DateTime recordedAt) =>
      (_db.update(_db.readingPositions)..where(
            (t) =>
                t.conversionId.equals(conversionId) &
                t.recordedAt.equals(recordedAt),
          ))
          .write(const ReadingPositionsCompanion(pending: Value(false)));

  @override
  Future<Map<String, ReadingPosition>> pending() async {
    final rows = await (_db.select(
      _db.readingPositions,
    )..where((t) => t.pending)).get();
    return {for (final row in rows) row.conversionId: _position(row)};
  }

  @override
  Future<void> clear() => _db.delete(_db.readingPositions).go();
}
