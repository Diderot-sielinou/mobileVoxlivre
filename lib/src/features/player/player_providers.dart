import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxlivre/src/features/player/application/add_bookmark.dart';
import 'package:voxlivre/src/features/player/application/clear_bookmarks.dart';
import 'package:voxlivre/src/features/player/application/clear_downloads.dart';
import 'package:voxlivre/src/features/player/application/clear_positions.dart';
import 'package:voxlivre/src/features/player/application/delete_bookmark.dart';
import 'package:voxlivre/src/features/player/application/download_book.dart';
import 'package:voxlivre/src/features/player/application/edit_bookmark.dart';
import 'package:voxlivre/src/features/player/application/flush_positions.dart';
import 'package:voxlivre/src/features/player/application/list_downloads.dart';
import 'package:voxlivre/src/features/player/application/load_parts.dart';
import 'package:voxlivre/src/features/player/application/open_book.dart';
import 'package:voxlivre/src/features/player/application/remove_download.dart';
import 'package:voxlivre/src/features/player/application/save_position.dart';
import 'package:voxlivre/src/features/player/application/sync_bookmarks.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/infrastructure/api_player_gateway.dart';
import 'package:voxlivre/src/features/player/infrastructure/device_book_files.dart';
import 'package:voxlivre/src/features/player/infrastructure/drift_bookmark_store.dart';
import 'package:voxlivre/src/features/player/infrastructure/drift_position_store.dart';
import 'package:voxlivre/src/features/player/infrastructure/just_audio_engine.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';
import 'package:voxlivre/src/features/player/infrastructure/uuid_ids.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Composition du lecteur (ADR-0002, ADR-0010).

/// Base locale `player.sqlite`, fermée avec l'app.
final playerDatabaseProvider = Provider<PlayerDatabase>((ref) {
  final db = PlayerDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final positionStoreProvider = Provider<PositionStore>(
  (ref) => DriftPositionStore(ref.watch(playerDatabaseProvider)),
);

/// Livres téléchargés (ADR-0011).
final bookFilesProvider = Provider<BookFiles>(
  (ref) => DeviceBookFiles(
    ref.watch(playerDatabaseProvider),
    getApplicationSupportDirectory,
  ),
);

final playerGatewayProvider = Provider<PlayerGateway>(
  (ref) => ApiPlayerGateway(
    ref.watch(apiClientProvider),
    ref.watch(signedDownloadProvider),
  ),
);

/// Un moteur par lecteur ouvert, libéré à sa fermeture.
// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final audioEngineProvider = Provider.autoDispose<AudioEngine>((ref) {
  final engine = JustAudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final loadPartsProvider = Provider<LoadParts>(
  (ref) => LoadParts(
    ref.watch(playerGatewayProvider),
    ref.watch(bookFilesProvider),
  ),
);

final openBookProvider = Provider<OpenBook>(
  (ref) => OpenBook(
    ref.watch(playerGatewayProvider),
    ref.watch(positionStoreProvider),
    ref.watch(loadPartsProvider),
    ref.watch(bookFilesProvider),
  ),
);

final savePositionProvider = Provider<SavePosition>(
  (ref) => SavePosition(
    ref.watch(positionStoreProvider),
    ref.watch(playerGatewayProvider),
    ref.watch(clockProvider),
  ),
);

final clearPositionsProvider = Provider<ClearPositions>(
  (ref) => ClearPositions(ref.watch(positionStoreProvider)),
);

final flushPositionsProvider = Provider<FlushPositions>(
  (ref) => FlushPositions(
    ref.watch(positionStoreProvider),
    ref.watch(playerGatewayProvider),
  ),
);

final downloadBookProvider = Provider<DownloadBook>(
  (ref) => DownloadBook(
    ref.watch(playerGatewayProvider),
    ref.watch(bookFilesProvider),
  ),
);

final removeDownloadProvider = Provider<RemoveDownload>(
  (ref) => RemoveDownload(ref.watch(bookFilesProvider)),
);

final clearDownloadsProvider = Provider<ClearDownloads>(
  (ref) => ClearDownloads(ref.watch(bookFilesProvider)),
);

/// Les livres lisibles sans réseau.
final downloadedBooksProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(bookFilesProvider).watchComplete(),
);

/// Marque-pages (ADR-0012).
final bookmarkStoreProvider = Provider<BookmarkStore>(
  (ref) => DriftBookmarkStore(ref.watch(playerDatabaseProvider)),
);

final idGeneratorProvider = Provider<IdGenerator>((ref) => const UuidIds());

final addBookmarkProvider = Provider<AddBookmark>(
  (ref) => AddBookmark(
    ref.watch(bookmarkStoreProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final editBookmarkProvider = Provider<EditBookmark>(
  (ref) => EditBookmark(
    ref.watch(bookmarkStoreProvider),
    ref.watch(clockProvider),
  ),
);

final deleteBookmarkProvider = Provider<DeleteBookmark>(
  (ref) => DeleteBookmark(
    ref.watch(bookmarkStoreProvider),
    ref.watch(clockProvider),
  ),
);

final syncBookmarksProvider = Provider<SyncBookmarks>(
  (ref) => SyncBookmarks(
    ref.watch(bookmarkStoreProvider),
    ref.watch(playerGatewayProvider),
  ),
);

final clearBookmarksProvider = Provider<ClearBookmarks>(
  (ref) => ClearBookmarks(ref.watch(bookmarkStoreProvider)),
);

/// Les marque-pages actifs d'un document.
// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final bookmarksProvider = StreamProvider.autoDispose
    .family<List<Bookmark>, String>(
      (ref, documentId) => ref.watch(bookmarkStoreProvider).watch(documentId),
    );

final listDownloadsProvider = Provider<ListDownloads>(
  (ref) => ListDownloads(ref.watch(bookFilesProvider)),
);

/// Les livres complets sur le téléphone, avec leur place.
// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final downloadsProvider = StreamProvider.autoDispose<List<DownloadedBook>>(
  (ref) => ref.watch(listDownloadsProvider)(),
);
