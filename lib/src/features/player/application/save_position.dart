import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

/// Enregistre où l'on en est : d'abord sur l'appareil (« à envoyer »), puis
/// sur le serveur. Hors ligne, elle part plus tard (`FlushPositions`).
final class SavePosition {
  const SavePosition(this._positions, this._gateway, this._clock);

  final PositionStore _positions;
  final PlayerGateway _gateway;
  final Clock _clock;

  Future<void> call(
    String conversionId, {
    required int wordIndex,
    required int audioMs,
  }) async {
    final position = ReadingPosition(
      wordIndex: wordIndex,
      audioMs: audioMs,
      recordedAt: _clock.now(),
    );
    await _positions.write(conversionId, position);
    final sent = await _gateway.savePosition(conversionId, position);
    if (sent is Ok) {
      await _positions.markSent(conversionId, position.recordedAt);
    }
  }
}
