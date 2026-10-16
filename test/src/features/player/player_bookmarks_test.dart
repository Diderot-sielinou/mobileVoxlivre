import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/application/add_bookmark.dart';
import 'package:voxlivre/src/features/player/application/clear_bookmarks.dart';
import 'package:voxlivre/src/features/player/application/delete_bookmark.dart';
import 'package:voxlivre/src/features/player/application/edit_bookmark.dart';
import 'package:voxlivre/src/features/player/application/sync_bookmarks.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/timed_word.dart';

import '../../../helpers/app_harness.dart';
import 'fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

void main() {
  late FakePlayerGateway gateway;
  late MemoryBookmarkStore store;
  late FixedClock clock;
  late SequenceIds ids;

  setUp(() {
    ids = SequenceIds();
    gateway = FakePlayerGateway();
    store = MemoryBookmarkStore();
    clock = FixedClock(DateTime.utc(2026, 10, 16, 9));
  });

  AddBookmark add() => AddBookmark(store, clock, ids);
  SyncBookmarks sync() => SyncBookmarks(store, gateway);

  Future<Bookmark> added({String note = ''}) async => switch (await add()(
    'd-1',
    pageNumber: 2,
    wordIndex: 1,
    excerpt: 'les contrats.',
    note: note,
  )) {
    Ok(:final value) => value,
    Err() => throw StateError('refusé'),
  };

  group('BookText : ancrage des marque-pages', () {
    final text = BookText(
      [
        for (final (i, w) in [
          'Le',
          'droit',
          'civil.',
          'Il',
          'règle',
          'les',
        ].indexed)
          TimedWord(
            index: i,
            text: w,
            startMs: i * 1000,
            endMs: i * 1000 + 900,
          ),
      ],
      [(page: 1, wordIndex: 0), (page: 2, wordIndex: 4)],
    );

    test('page et mot dans la page, extrait de 6 mots au plus', () {
      expect(text.anchorOf(5), (page: 2, wordIndex: 1));
      expect(text.anchorOf(1), (page: 1, wordIndex: 1));
      expect(text.excerptAt(3), 'Il règle les');
      expect(text.excerptAt(0), 'Le droit civil. Il règle les');
    });

    test('retrouver le mot ; partie absente ou page inconnue : -1', () {
      expect(text.positionOfAnchor(2, 1), 5);
      expect(text.positionOfAnchor(2, 7), -1, reason: 'partie pas chargée');
      expect(text.positionOfAnchor(9, 0), -1);
    });
  });

  group('poser, modifier, supprimer : sur l’appareil d’abord', () {
    test('posé « à envoyer », note nettoyée', () async {
      final b = await added(note: '  à revoir ');
      expect(b.id, 'b-1');
      expect(b.pending, isTrue);
      expect(b.note, 'à revoir');
      expect(b.createdAt, clock.instant);
      expect(store.rows.keys, ['b-1']);
    });

    test('note trop longue, ou 500 marque-pages : refusé', () async {
      final long = await add()(
        'd-1',
        pageNumber: 1,
        wordIndex: 0,
        excerpt: 'x',
        note: 'a' * (bookmarkNoteMax + 1),
      );
      expect(codeOf(long), 'INVALID_BOOKMARK_NOTE');

      final model = await added();
      for (var i = 1; i < bookmarksPerDocumentMax; i++) {
        await store.save(
          Bookmark(
            id: 'x$i',
            documentId: 'd-1',
            pageNumber: 1,
            wordIndex: i,
            excerpt: model.excerpt,
            note: '',
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
          ),
        );
      }
      Future<String?> one() async => codeOf(
        await add()('d-1', pageNumber: 1, wordIndex: 0, excerpt: 'x'),
      );
      expect(await one(), 'BOOKMARKS_LIMIT_CONFLICT');
      // Les traces de suppression ne comptent pas.
      await DeleteBookmark(store, clock)(model);
      expect(await one(), isNull);
    });

    test('modifier : nouvelle note, nouvel instant, à envoyer', () async {
      final b = (await added()).copyWith(pending: false);
      clock.advance(const Duration(minutes: 3));
      final result = await EditBookmark(store, clock)(b, 'définition');
      expect(codeOf(result), isNull);
      expect(store.rows['b-1']!.note, 'définition');
      expect(store.rows['b-1']!.updatedAt, clock.instant);
      expect(store.rows['b-1']!.pending, isTrue);
      expect(
        codeOf(await EditBookmark(store, clock)(b, 'a' * 2001)),
        'INVALID_BOOKMARK_NOTE',
      );
    });

    test('supprimer : une trace à envoyer, plus dans la liste', () async {
      final b = await added();
      await DeleteBookmark(store, clock)(b);
      expect(store.rows['b-1']!.deleted, isTrue);
      expect(await store.watch('d-1').first, isEmpty);
    });

    test('fin de session : tout part', () async {
      await added();
      await ClearBookmarks(store)();
      expect(store.rows, isEmpty);
    });
  });

  group('SyncBookmarks', () {
    test('envoie, puis le serveur fait foi (extrait recalculé)', () async {
      await added(note: 'n');
      expect(await sync()(documentId: 'd-1'), isTrue);
      expect(gateway.bookmarkCalls, ['PUT b-1', 'GET d-1']);
      expect(store.rows['b-1']!.pending, isFalse);
      expect(gateway.server['b-1']!.note, 'n');
    });

    test('sans réseau : rien n’est perdu, tout reste à envoyer', () async {
      await added();
      gateway.bookmarkCode = 'NETWORK_UNAVAILABLE';
      expect(await sync()(documentId: 'd-1'), isFalse);
      expect(store.rows['b-1']!.pending, isTrue);
      expect(gateway.bookmarkCalls, ['PUT b-1'], reason: 'arrêt au 1er échec');
    });

    test('suppression envoyée : la trace part', () async {
      final b = await added();
      await sync()();
      await DeleteBookmark(store, clock)(store.rows['b-1']!);
      expect(await sync()(), isTrue);
      expect(store.rows, isEmpty);
      expect(gateway.server[b.id]!.deleted, isTrue);
    });

    test('supprimé ailleurs plus récemment : retiré ici', () async {
      final b = await added();
      gateway.server[b.id] = b.copyWith(
        pending: false,
        deletedAt: clock.instant.add(const Duration(minutes: 1)),
      );
      await sync()();
      expect(store.rows, isEmpty);
    });

    test('refus définitif : plus à envoyer, la relecture tranche', () async {
      await added();
      gateway.rejectCode = 'INVALID_BOOKMARK_ANCHOR';
      expect(await sync()(documentId: 'd-1'), isTrue);
      expect(store.rows, isEmpty, reason: 'absent du serveur');
    });

    test('relecture : nouveau d’ailleurs ajouté, supprimé ailleurs retiré, '
        'modifié ici entre-temps gardé', () async {
      final gone = await added();
      final mine = await added(note: 'ancienne');
      await sync()();
      // Supprimé sur un autre appareil, et un autre posé là-bas.
      gateway.server.remove(gone.id);
      gateway.server['autre'] = Bookmark(
        id: 'autre',
        documentId: 'd-1',
        pageNumber: 1,
        wordIndex: 0,
        excerpt: 'Le droit civil.',
        note: '',
        createdAt: clock.instant,
        updatedAt: clock.instant,
        needsReview: true,
      );
      // Pendant la lecture du serveur, la note est changée ici.
      gateway.afterRead = () async {
        clock.advance(const Duration(seconds: 5));
        await EditBookmark(store, clock)(store.rows[mine.id]!, 'nouvelle');
      };

      expect(await sync()(documentId: 'd-1'), isTrue);

      expect(store.rows.containsKey(gone.id), isFalse);
      expect(store.rows['autre']!.needsReview, isTrue);
      expect(store.rows[mine.id]!.note, 'nouvelle');
      expect(store.rows[mine.id]!.pending, isTrue);
    });

    test('modifié pendant l’envoi : reste à envoyer', () async {
      final b = await added(note: 'avant');
      gateway.beforePut = () async {
        gateway.beforePut = null;
        clock.advance(const Duration(seconds: 5));
        await EditBookmark(store, clock)(b, 'après');
      };
      await sync()();
      expect(store.rows['b-1']!.note, 'après');
      expect(store.rows['b-1']!.pending, isTrue);
    });
  });
}
