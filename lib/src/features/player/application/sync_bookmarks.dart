import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Synchronise les marque-pages (ADR-0012) : envoie ceux « à envoyer »,
/// puis, pour un document, aligne l'appareil sur le serveur — le plus récent
/// gagne, marque-page par marque-page.
final class SyncBookmarks {
  const SyncBookmarks(this._store, this._gateway);

  final BookmarkStore _store;
  final PlayerGateway _gateway;

  /// [documentId] : celui du livre ouvert, à relire ensuite. Rend `false`
  /// si le réseau a manqué (rien n'est perdu, on réessaiera).
  Future<bool> call({String? documentId}) async {
    if (!await _push()) return false;
    if (documentId == null) return true;
    return _pull(documentId);
  }

  Future<bool> _push() async {
    for (final bookmark in await _store.pending()) {
      if (bookmark.deleted) {
        switch (await _gateway.deleteBookmark(bookmark)) {
          case Ok() || Err(error: BookmarkRejected()):
            await _store.remove(bookmark.id);
          case Err():
            return false;
        }
      } else {
        switch (await _gateway.putBookmark(bookmark)) {
          case Ok(value: final kept) when kept.deleted:
            // Supprimé ailleurs, plus récemment.
            await _store.remove(bookmark.id);
          case Ok(value: final kept):
            await _saveUnlessChanged(bookmark, kept);
          case Err(error: BookmarkRejected()):
            // Refus définitif : la relecture du serveur fera foi.
            await _saveUnlessChanged(
              bookmark,
              bookmark.copyWith(pending: false),
            );
          case Err():
            return false;
        }
      }
    }
    return true;
  }

  /// Enregistre [kept], sauf si l'utilisateur a modifié le marque-page
  /// pendant l'envoi (il reste alors « à envoyer »).
  Future<void> _saveUnlessChanged(Bookmark sent, Bookmark kept) async {
    final now = (await _store.all(
      sent.documentId,
    )).where((b) => b.id == sent.id).firstOrNull;
    if (now == null || now.updatedAt != sent.updatedAt || now.deleted) return;
    await _store.save(kept.copyWith(pending: false));
  }

  Future<bool> _pull(String documentId) async {
    final remote = await _gateway.bookmarks(documentId);
    if (remote case Ok(value: final items)) {
      final local = {for (final b in await _store.all(documentId)) b.id: b};
      for (final item in items) {
        final mine = local.remove(item.id);
        if (mine != null && mine.pending) continue;
        await _store.save(item.copyWith(pending: false));
      }
      // Absents du serveur et déjà envoyés : supprimés ailleurs.
      for (final rest in local.values) {
        if (!rest.pending) await _store.remove(rest.id);
      }
      return true;
    }
    return false;
  }
}
