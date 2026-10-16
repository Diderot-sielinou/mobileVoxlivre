import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Envoie les positions écrites sans réseau (ADR-0011). Le serveur garde la
/// plus récente : un envoi tardif ne remplace pas une position plus neuve.
final class FlushPositions {
  const FlushPositions(this._positions, this._gateway);

  final PositionStore _positions;
  final PlayerGateway _gateway;

  /// Rend le nombre de positions envoyées.
  Future<int> call() async {
    var sent = 0;
    for (final MapEntry(key: id, value: position)
        in (await _positions.pending()).entries) {
      final result = await _gateway.savePosition(id, position);
      // Réseau toujours absent : inutile d'insister pour les suivantes.
      if (result is Err) break;
      await _positions.markSent(id, position.recordedAt);
      sent++;
    }
    return sent;
  }
}
