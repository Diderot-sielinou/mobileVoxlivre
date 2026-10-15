import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/application/delete_document.dart';
import 'package:voxlivre/src/features/library/application/refresh_document.dart';
import 'package:voxlivre/src/features/library/application/rename_document.dart';
import 'package:voxlivre/src/features/library/application/watch_document.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';

import '../fakes.dart';

String? codeOf(Result<void, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

void main() {
  late FakeDocumentRepository repository;

  setUp(() => repository = FakeDocumentRepository(remote: {'a': sheet('a')}));

  test('WatchDocument suit la fiche, RefreshDocument la remplit', () async {
    final seen = <DocumentSheet?>[];
    final subscription = WatchDocument(repository)('a').listen(seen.add);
    addTearDown(subscription.cancel);

    final result = await RefreshDocument(repository)('a');
    await Future<void>.delayed(Duration.zero);

    expect(result.isOk, isTrue);
    expect(seen.map((s) => s?.title), [null, 'Livre a']);
  });

  group('RenameDocument', () {
    test('un titre valide est normalisé puis envoyé', () async {
      final result = await RenameDocument(repository)('a', '  Droit  civil ');

      expect(result.isOk, isTrue);
      expect(repository.renamed, ['Droit civil']);
    });

    test('un titre refusé n’appelle pas le dépôt', () async {
      final result = await RenameDocument(repository)('a', '   ');

      expect(codeOf(result), 'INVALID_DOCUMENT_TITLE');
      expect(repository.renamed, isEmpty);
    });
  });

  test('DeleteDocument rend le refus du backend', () async {
    repository.failure = 'DOCUMENT_DELETION_CONFLICT';
    expect(
      codeOf(await DeleteDocument(repository)('a')),
      'DOCUMENT_DELETION_CONFLICT',
    );

    repository.failure = null;
    expect((await DeleteDocument(repository)('a')).isOk, isTrue);
    expect(repository.deleted, ['a']);
  });
}
