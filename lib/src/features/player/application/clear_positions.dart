import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Fin de session : les positions quittent l'appareil (ADR-0006).
final class ClearPositions {
  const ClearPositions(this._positions);

  final PositionStore _positions;

  Future<void> call() => _positions.clear();
}
