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
    return row == null
        ? null
        : ReadingPosition(
            wordIndex: row.wordIndex,
            audioMs: row.audioMs,
            // drift relit en heure locale : tout est UTC dans l'app.
            recordedAt: row.recordedAt.toUtc(),
          );
  }

  @override
  Future<void> write(String conversionId, ReadingPosition position) => _db
      .into(_db.readingPositions)
      .insertOnConflictUpdate(
        ReadingPositionsCompanion.insert(
          conversionId: conversionId,
          wordIndex: position.wordIndex,
          audioMs: position.audioMs,
          recordedAt: position.recordedAt,
        ),
      );

  @override
  Future<void> clear() => _db.delete(_db.readingPositions).go();
}
