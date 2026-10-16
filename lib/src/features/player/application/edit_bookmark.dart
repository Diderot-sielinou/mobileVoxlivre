import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/application/add_bookmark.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Change la note d'un marque-page (l'ancrage, lui, ne bouge pas).
final class EditBookmark {
  const EditBookmark(this._store, this._clock);

  final BookmarkStore _store;
  final Clock _clock;

  Future<Result<Bookmark, Failure>> call(Bookmark bookmark, String note) async {
    final text = note.trim();
    if (text.length > bookmarkNoteMax) {
      return const Result.err(InvalidBookmarkNote());
    }
    final edited = bookmark.copyWith(
      note: text,
      updatedAt: _clock.now(),
      pending: true,
    );
    await _store.save(edited);
    return Result.ok(edited);
  }
}
