import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Fin de session : les marque-pages quittent l'appareil.
final class ClearBookmarks {
  const ClearBookmarks(this._store);

  final BookmarkStore _store;

  Future<void> call() => _store.clear();
}
