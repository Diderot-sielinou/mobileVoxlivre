import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Supprime un marque-page : une trace reste sur l'appareil jusqu'à l'envoi
/// (ADR-0012), pour qu'une modification plus ancienne ne le fasse pas
/// revenir.
final class DeleteBookmark {
  const DeleteBookmark(this._store, this._clock);

  final BookmarkStore _store;
  final Clock _clock;

  Future<void> call(Bookmark bookmark) => _store.save(
    bookmark.copyWith(deletedAt: _clock.now(), pending: true),
  );
}
