import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/application/mark_document_reviewed.dart';
import 'package:voxlivre/src/features/library/application/refresh_document_pages.dart';
import 'package:voxlivre/src/features/library/application/save_document_page.dart';
import 'package:voxlivre/src/features/library/application/watch_document_pages.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';

import '../fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

void main() {
  group('DocumentPage', () {
    test('raisons du backend, l’inconnue ne casse rien', () {
      expect(
        [
          'header',
          'footer',
          'page_number',
          'footnote',
          'caption',
          'table',
          'logo',
        ].map(SetAsideReason.fromWire),
        SetAsideReason.values,
      );
    });

    test('à relire sous 80 % de confiance ; un PDF texte jamais', () {
      expect(page(1, confidence: 0.62).needsReview, isTrue);
      expect(page(1, confidence: 0.8).needsReview, isFalse);
      expect(page(1).needsReview, isFalse);
    });

    test('réintégrer : l’en-tête en haut, le reste en bas', () {
      const header = SetAsideLine('DROIT CIVIL', SetAsideReason.header);
      const note = SetAsideLine('1. Voir art. 1134', SetAsideReason.footnote);
      final p = page(3, text: 'Corps.', setAside: [header, note]);

      expect(p.withLine(header), 'DROIT CIVIL\nCorps.');
      expect(p.withLine(note), 'Corps.\n1. Voir art. 1134');
      expect(page(3, text: ' ').withLine(note), '1. Voir art. 1134');

      final back = page(3, text: p.withLine(header), setAside: [header, note]);
      expect(back.stillSetAside, [note], reason: 'déjà réintégrée');
    });

    test('PageText : mêmes règles que le backend', () {
      String? parsed(String input) => switch (PageText.parse(input)) {
        Ok(:final value) => value,
        Err() => null,
      };
      expect(parsed('  ligne 1\r\nligne\t2  '), 'ligne 1\nligne\t2');
      expect(parsed('   '), '');
      expect(parsed('a' * PageText.maxLength), hasLength(PageText.maxLength));
      expect(parsed('a' * (PageText.maxLength + 1)), isNull);
      expect(parsed('bip\u0007'), isNull);
    });
  });

  group('cas d’usage', () {
    late FakeDocumentTextRepository repository;

    setUp(
      () => repository = FakeDocumentTextRepository(
        remote: [page(1), page(2, confidence: 0.5)],
      ),
    );

    test('WatchDocumentPages suit le cache, Refresh le remplit', () async {
      final seen = <int>[];
      final subscription = WatchDocumentPages(repository)('a').listen(
        (pages) => seen.add(pages.length),
      );
      addTearDown(subscription.cancel);

      expect((await RefreshDocumentPages(repository)('a')).isOk, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(seen, [0, 2]);
    });

    test('SaveDocumentPage valide avant d’appeler', () async {
      await RefreshDocumentPages(repository)('a');
      final save = SaveDocumentPage(repository);

      expect(codeOf(await save('a', 2, 'x\u0001')), 'INVALID_PAGE_TEXT');
      expect(repository.saved, isEmpty);

      expect(codeOf(await save('a', 2, ' Texte corrigé \r\n')), isNull);
      expect(repository.saved, [(2, 'Texte corrigé')]);
    });

    test('MarkDocumentReviewed rend l’échec du backend', () async {
      repository.failure = 'DOCUMENT_TEXT_NOT_READY';
      expect(
        codeOf(await MarkDocumentReviewed(repository)('a')),
        'DOCUMENT_TEXT_NOT_READY',
      );
      repository.failure = null;
      expect(codeOf(await MarkDocumentReviewed(repository)('a')), isNull);
      expect(repository.reviews, 1);
    });
  });
}
