import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/domain/library_shelf.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';

import '../fakes.dart';

void main() {
  test('les statuts du backend sont lus, l’inconnu ne casse rien', () {
    expect(
      [
        'processing',
        'failed',
        'not_converted',
        'ready',
        'in_progress',
        'finished',
        'archived',
      ].map(LibraryStatus.fromWire),
      LibraryStatus.values,
    );
  });

  test('durée restante selon la progression', () {
    expect(book('a').remaining, const Duration(minutes: 74));
    expect(
      book('a', progressPercent: 50).remaining,
      const Duration(minutes: 37),
    );
    expect(book('a', progressPercent: 130).remaining, Duration.zero);
    expect(book('a', playable: Duration.zero).remaining, isNull);
    expect(book('a', status: LibraryStatus.notConverted).remaining, isNull);
  });

  group('LibraryShelf', () {
    final old = book(
      'old',
      status: LibraryStatus.inProgress,
      listenedAt: DateTime.utc(2026, 10, 10),
    );
    final recent = book(
      'recent',
      status: LibraryStatus.inProgress,
      listenedAt: DateTime.utc(2026, 10, 12),
    );
    final items = [
      book('r'),
      old,
      recent,
      book('f', status: LibraryStatus.finished),
      book('p', status: LibraryStatus.processing),
    ];

    test('le livre à reprendre est le plus récemment écouté', () {
      expect(LibraryShelf.resume(items), recent);
      expect(LibraryShelf.resume([book('r')]), isNull);
      expect(
        LibraryShelf.resume([book('x', status: LibraryStatus.inProgress)]),
        isNull,
        reason: 'sans position, rien à reprendre',
      );
    });

    test('compte par filtre et repère un livre en préparation', () {
      expect(LibraryShelf.counts(items), {
        LibraryFilter.all: 5,
        LibraryFilter.inProgress: 2,
        LibraryFilter.ready: 1,
        LibraryFilter.finished: 1,
      });
      expect(LibraryShelf.hasWorkInProgress(items), isTrue);
      expect(LibraryShelf.hasWorkInProgress([book('r')]), isFalse);
    });
  });

  test('un cache jamais rempli n’est pas « chargé »', () {
    expect(LibrarySnapshot.empty.loaded, isFalse);
    expect(
      LibrarySnapshot(items: const [], refreshedAt: DateTime.utc(2026)).loaded,
      isTrue,
    );
  });
}
