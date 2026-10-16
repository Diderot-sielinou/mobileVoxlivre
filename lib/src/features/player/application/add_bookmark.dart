import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Note de plus de 2 000 caractères.
final class InvalidBookmarkNote extends Failure {
  const InvalidBookmarkNote() : super('INVALID_BOOKMARK_NOTE');
}

/// Déjà 500 marque-pages dans ce document.
final class BookmarksLimitReached extends Failure {
  const BookmarksLimitReached() : super('BOOKMARKS_LIMIT_CONFLICT');
}

/// Pose un marque-page, sur l'appareil d'abord (ADR-0012) ; il part au
/// serveur avec `SyncBookmarks`.
final class AddBookmark {
  const AddBookmark(this._store, this._clock, this._ids);

  final BookmarkStore _store;
  final Clock _clock;
  final IdGenerator _ids;

  Future<Result<Bookmark, Failure>> call(
    String documentId, {
    required int pageNumber,
    required int wordIndex,
    required String excerpt,
    String note = '',
  }) async {
    final text = note.trim();
    if (text.length > bookmarkNoteMax) {
      return const Result.err(InvalidBookmarkNote());
    }
    final active = (await _store.all(
      documentId,
    )).where((b) => !b.deleted).length;
    if (active >= bookmarksPerDocumentMax) {
      return const Result.err(BookmarksLimitReached());
    }
    final now = _clock.now();
    final bookmark = Bookmark(
      id: _ids.newId(),
      documentId: documentId,
      pageNumber: pageNumber,
      wordIndex: wordIndex,
      excerpt: excerpt,
      note: text,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
    await _store.save(bookmark);
    return Result.ok(bookmark);
  }
}
