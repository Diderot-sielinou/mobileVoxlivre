import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

import '../auth/fakes.dart';

/// WebVTT d'une partie : un mot par seconde, à partir de l'index [first].
String vttOf(List<String> words, {int first = 0}) {
  String t(int s) => '00:00:${s.toString().padLeft(2, '0')}.000';
  return [
    'WEBVTT',
    '',
    for (var i = 0; i < words.length; i++) ...[
      '${first + i}',
      '${t(i)} --> ${t(i + 1)}',
      words[i],
      '',
    ],
  ].join('\n');
}

ManifestPart part(
  int index, {
  required int startMs,
  required int firstWord,
  bool ready = true,
  int durationMs = 4000,
  List<({int page, int wordIndex})> pageStarts = const [],
}) => ManifestPart(
  index: index,
  ready: ready,
  firstWordIndex: firstWord,
  startMs: ready ? startMs : null,
  durationMs: ready ? durationMs : null,
  pageStarts: pageStarts,
  audio: ready
      ? ManifestFile(
          url: Uri.parse('https://s.test/p$index.mp3'),
          bytes: 1,
          sha256: 'a',
        )
      : null,
  vtt: ready
      ? ManifestFile(
          url: Uri.parse('https://s.test/p$index.vtt'),
          bytes: 1,
          sha256: 'b',
        )
      : null,
);

/// Deux parties de 4 mots (une seconde chacun), pages 1 et 2.
Manifest testManifest({
  bool firstReady = true,
  bool secondReady = true,
  DateTime? expiresAt,
}) => Manifest(
  conversionId: 'c-1',
  documentId: 'd-1',
  complete: secondReady,
  partCount: 2,
  urlsExpireAt: expiresAt ?? DateTime.utc(2030),
  durationMs: secondReady ? 8000 : null,
  parts: [
    part(
      0,
      startMs: 0,
      firstWord: 0,
      ready: firstReady,
      pageStarts: [(page: 1, wordIndex: 0)],
    ),
    part(
      1,
      startMs: 4000,
      firstWord: 4,
      ready: secondReady,
      pageStarts: [(page: 2, wordIndex: 4)],
    ),
  ],
);

const vtts = {
  'https://s.test/p0.vtt': ['Le', 'droit', 'civil.', 'Il'],
  'https://s.test/p1.vtt': ['règle', 'les', 'contrats.', 'Fin'],
};

/// Un fichier « sur l'appareil » : son empreinte et son contenu.
typedef DiskFile = ({String sha256, String content});

/// Backend du lecteur en mémoire. Les téléchargements s'écrivent dans
/// [disk] (partagé avec [MemoryBookFiles]).
final class FakePlayerGateway implements PlayerGateway {
  FakePlayerGateway({
    Manifest? manifest,
    this.remote,
    Map<String, DiskFile>? disk,
  }) : current = manifest ?? testManifest(),
       disk = disk ?? {};

  Manifest current;
  ReadingPosition? remote;
  String? manifestCode;
  String? vttCode;
  String? positionCode;
  String? saveCode;
  final saved = <ReadingPosition>[];
  int manifests = 0;

  final Map<String, DiskFile> disk;
  final downloads = <Uri>[];

  /// Code d'échec par URL (une fois chacun).
  final failOnce = <String, String>{};

  /// URL dont le fichier reçu est abîmé (toujours).
  final corrupt = <String>{};

  /// Bloque les téléchargements tant qu’il n’est pas complété.
  Completer<void>? hold;

  /// Bloque la lecture de la position (serveur muet).
  Completer<void>? positionHold;

  @override
  Future<Result<void, Failure>> download(
    Uri url,
    String path, {
    void Function(int received)? onBytes,
    Future<void>? cancel,
  }) async {
    downloads.add(url);
    if (hold case final hold?) {
      var cancelled = false;
      await Future.any([
        hold.future,
        if (cancel != null) cancel.then((_) => cancelled = true),
      ]);
      if (cancelled) return const Result.err(FakeFailure('CANCELLED'));
    }
    final key = url.toString();
    if (failOnce.remove(key) case final code?) {
      return Result.err(FakeFailure(code));
    }
    final isVtt = url.path.endsWith('.vtt');
    final file = isVtt ? 'b' : 'a';
    onBytes?.call(1);
    final words = vtts[key.split('?').first];
    disk[path] = (
      sha256: corrupt.contains(key) ? 'bad' : file,
      content: isVtt && words != null
          ? vttOf(words, first: key.contains('p1.vtt') ? 4 : 0)
          : 'mp3',
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<Manifest, Failure>> manifest(String conversionId) async {
    manifests++;
    if (manifestCode case final code?) return Result.err(FakeFailure(code));
    return Result.ok(current);
  }

  @override
  Future<Result<String, Failure>> vtt(Uri url) async {
    if (vttCode case final code?) return Result.err(FakeFailure(code));
    final words = vtts[url.toString()]!;
    final first = url.toString().endsWith('p1.vtt') ? 4 : 0;
    return Result.ok(vttOf(words, first: first));
  }

  @override
  Future<Result<ReadingPosition?, Failure>> position(
    String conversionId,
  ) async {
    await positionHold?.future;
    if (positionCode case final code?) return Result.err(FakeFailure(code));
    return Result.ok(remote);
  }

  @override
  Future<Result<void, Failure>> savePosition(
    String conversionId,
    ReadingPosition position,
  ) async {
    if (saveCode case final code?) return Result.err(FakeFailure(code));
    saved.add(position);
    return const Result.ok(null);
  }

  /// Marque-pages du serveur, traces comprises (règles de l'ADR-0028).
  final server = <String, Bookmark>{};

  /// Échec passager de tout appel aux marque-pages.
  String? bookmarkCode;

  /// Refus définitif (422…) des envois.
  String? rejectCode;
  final bookmarkCalls = <String>[];

  /// Appelés pendant un envoi / après la lecture du serveur (gestes de
  /// l'utilisateur au même moment).
  Future<void> Function()? beforePut;
  Future<void> Function()? afterRead;

  @override
  Future<Result<List<Bookmark>, Failure>> bookmarks(String documentId) async {
    bookmarkCalls.add('GET $documentId');
    if (bookmarkCode case final code?) return Result.err(FakeFailure(code));
    final list = [
      for (final b in server.values)
        if (b.documentId == documentId && !b.deleted) b,
    ];
    await afterRead?.call();
    return Result.ok(list);
  }

  @override
  Future<Result<Bookmark, Failure>> putBookmark(Bookmark bookmark) async {
    bookmarkCalls.add('PUT ${bookmark.id}');
    await beforePut?.call();
    if (bookmarkCode case final code?) return Result.err(FakeFailure(code));
    if (rejectCode case final code?) return Result.err(BookmarkRejected(code));
    final old = server[bookmark.id];
    final kept = switch (old) {
      null => bookmark.copyWith(pending: false),
      // Supprimé plus récemment : la suppression l'emporte.
      _ when old.deleted && old.deletedAt!.isAfter(bookmark.updatedAt) => old,
      _ when old.updatedAt.isAfter(bookmark.updatedAt) => old,
      _ => Bookmark(
        id: old.id,
        documentId: old.documentId,
        pageNumber: old.pageNumber,
        wordIndex: old.wordIndex,
        excerpt: old.excerpt,
        note: bookmark.note,
        createdAt: old.createdAt,
        updatedAt: bookmark.updatedAt,
      ),
    };
    server[bookmark.id] = kept;
    return Result.ok(kept);
  }

  @override
  Future<Result<void, Failure>> deleteBookmark(Bookmark bookmark) async {
    bookmarkCalls.add('DELETE ${bookmark.id}');
    if (bookmarkCode case final code?) return Result.err(FakeFailure(code));
    if (rejectCode case final code?) return Result.err(BookmarkRejected(code));
    final old = server[bookmark.id];
    if (old != null) {
      server[bookmark.id] = old.copyWith(deletedAt: bookmark.deletedAt);
    }
    return const Result.ok(null);
  }
}

/// Marque-pages sur l'appareil, en mémoire.
final class MemoryBookmarkStore implements BookmarkStore {
  final rows = <String, Bookmark>{};
  final _changes = StreamController<void>.broadcast();
  int clears = 0;

  List<Bookmark> _active(String documentId) =>
      [
        for (final b in rows.values)
          if (b.documentId == documentId && !b.deleted) b,
      ]..sort(
        (a, b) => a.pageNumber != b.pageNumber
            ? a.pageNumber.compareTo(b.pageNumber)
            : a.wordIndex.compareTo(b.wordIndex),
      );

  @override
  Stream<List<Bookmark>> watch(String documentId) {
    // Abonné d'abord, puis l'état courant : aucun changement perdu.
    late final StreamController<List<Bookmark>> out;
    StreamSubscription<void>? sub;
    out = StreamController<List<Bookmark>>(
      onListen: () {
        sub = _changes.stream.listen((_) => out.add(_active(documentId)));
        out.add(_active(documentId));
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<List<Bookmark>> all(String documentId) async => [
    for (final b in rows.values)
      if (b.documentId == documentId) b,
  ];

  @override
  Future<List<Bookmark>> pending() async => [
    for (final b in rows.values)
      if (b.pending) b,
  ];

  @override
  Future<void> save(Bookmark bookmark) async {
    rows[bookmark.id] = bookmark;
    _changes.add(null);
  }

  @override
  Future<void> remove(String id) async {
    rows.remove(id);
    _changes.add(null);
  }

  @override
  Future<void> clear() async {
    clears++;
    rows.clear();
    _changes.add(null);
  }
}

/// Identifiants prévisibles : b-1, b-2…
final class SequenceIds implements IdGenerator {
  var _next = 0;

  @override
  String newId() => 'b-${++_next}';
}

final class MemoryPositionStore implements PositionStore {
  MemoryPositionStore([this.position]);

  ReadingPosition? position;
  int clears = 0;

  /// Positions à envoyer, par conversion.
  final unsent = <String, ReadingPosition>{};

  @override
  Future<ReadingPosition?> read(String conversionId) async => position;

  @override
  Future<void> write(String conversionId, ReadingPosition p) async {
    position = p;
    unsent[conversionId] = p;
  }

  @override
  Future<void> markSent(String conversionId, DateTime recordedAt) async {
    if (unsent[conversionId]?.recordedAt == recordedAt) {
      unsent.remove(conversionId);
    }
  }

  @override
  Future<Map<String, ReadingPosition>> pending() async => {...unsent};

  @override
  Future<void> clear() async {
    clears++;
    position = null;
    unsent.clear();
  }
}

/// Livres téléchargés en mémoire, sur le [disk] du faux backend.
final class MemoryBookFiles implements BookFiles {
  MemoryBookFiles(this.disk);

  final Map<String, DiskFile> disk;
  final _books =
      <String, ({Manifest manifest, Set<int> verified, bool complete})>{};
  final _changes = StreamController<Set<String>>.broadcast();
  int clears = 0;

  Set<String> get _complete => {
    for (final MapEntry(:key, :value) in _books.entries)
      if (value.complete) key,
  };

  void _changed() => _changes.add(_complete);

  @override
  Future<StoredBook?> read(String conversionId) async {
    final book = _books[conversionId];
    if (book == null) return null;
    ManifestFile? local(ManifestFile? f, String path, {required bool ok}) =>
        f == null
        ? null
        : ManifestFile(
            url: ok ? Uri.file(path) : null,
            bytes: f.bytes,
            sha256: f.sha256,
          );
    final m = book.manifest;
    return StoredBook(
      verified: {...book.verified},
      complete: book.complete,
      manifest: Manifest(
        conversionId: m.conversionId,
        documentId: m.documentId,
        complete: m.complete,
        partCount: m.partCount,
        durationMs: m.durationMs,
        urlsExpireAt: DateTime.utc(9999),
        parts: [
          for (final p in m.parts)
            ManifestPart(
              index: p.index,
              ready: p.ready,
              firstWordIndex: p.firstWordIndex,
              startMs: p.startMs,
              durationMs: p.durationMs,
              wordCount: p.wordCount,
              pageStarts: p.pageStarts,
              audio: local(
                p.audio,
                '/books/$conversionId/part-${p.index}.mp3',
                ok: book.verified.contains(p.index),
              ),
              vtt: local(
                p.vtt,
                '/books/$conversionId/part-${p.index}.vtt',
                ok: book.verified.contains(p.index),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Future<void> save(String conversionId, Manifest manifest) async {
    final old = _books[conversionId];
    _books[conversionId] = (
      manifest: manifest,
      verified: old?.verified ?? <int>{},
      complete: old?.complete ?? false,
    );
  }

  @override
  Future<String> pathOf(String conversionId, int index, PartFile file) async =>
      '/books/$conversionId/part-$index.${file == PartFile.audio ? 'mp3' : 'vtt'}';

  @override
  Future<bool> matches(String path, String sha256) async =>
      disk[path]?.sha256 == sha256;

  @override
  Future<void> deleteFile(String path) async => disk.remove(path);

  @override
  Future<String> readText(String path) async => disk[path]!.content;

  @override
  Future<void> markVerified(String conversionId, int index) async =>
      _books[conversionId]!.verified.add(index);

  @override
  Future<void> markComplete(String conversionId) async {
    final book = _books[conversionId]!;
    _books[conversionId] = (
      manifest: book.manifest,
      verified: book.verified,
      complete: true,
    );
    _changed();
  }

  @override
  Future<void> remove(String conversionId) async {
    _books.remove(conversionId);
    disk.removeWhere((path, _) => path.startsWith('/books/$conversionId/'));
    _changed();
  }

  @override
  Future<void> clear() async {
    clears++;
    _books.clear();
    disk.clear();
    _changed();
  }

  @override
  Stream<Set<String>> watchComplete() async* {
    yield _complete;
    yield* _changes.stream;
  }
}

/// Moteur audio piloté à la main : [emit] simule la lecture.
final class FakeAudioEngine implements AudioEngine {
  final loads = <({List<AudioPart> parts, int startMs})>[];
  final appended = <AudioPart>[];
  final seeks = <int>[];
  double speed = 1;
  bool disposed = false;
  final _positions = StreamController<int>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();

  void emit(int ms) => _positions.add(ms);

  /// Fin du dernier fichier : comme `just_audio`, reste « en lecture ».
  void finish() => _completed.add(null);

  @override
  Future<void> load(
    List<AudioPart> parts, {
    required int startMs,
    required String title,
  }) async => loads.add((parts: parts, startMs: startMs));

  @override
  Future<void> append(List<AudioPart> parts) async => appended.addAll(parts);

  @override
  Future<void> play() async => _playing.add(true);

  @override
  Future<void> pause() async => _playing.add(false);

  @override
  Future<void> seek(int ms) async => seeks.add(ms);

  @override
  Future<void> setSpeed(double value) async => speed = value;

  @override
  Stream<int> get positions => _positions.stream;

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() async => disposed = true;
}
