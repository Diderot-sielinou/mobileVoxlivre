import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/application/import_document.dart';
import 'package:voxlivre/src/features/library/application/pick_pdf.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

import '../fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

void main() {
  group('ImportRules', () {
    test('titre proposé d’après le nom du fichier', () {
      expect(
        ImportRules.titleFromFileName('Droit_des_obligations.PDF'),
        'Droit des obligations',
      );
      expect(ImportRules.titleFromFileName('Essai RF-05.pdf'), 'Essai RF-05');
    });

    test('refus locaux : attestation, vide, trop gros, pas un PDF', () {
      String? refused(PickedPdf file, {bool attested = true}) =>
          ImportRules.check(file, rightsAttested: attested)?.code;

      expect(refused(pdf()), isNull);
      expect(refused(pdf(), attested: false), 'RIGHTS_NOT_ATTESTED');
      expect(refused(pdf(sizeBytes: 0)), 'FILE_EMPTY');
      expect(refused(pdf(sizeBytes: ImportRules.maxSizeBytes)), isNull);
      expect(
        refused(pdf(sizeBytes: ImportRules.maxSizeBytes + 1)),
        'FILE_TOO_LARGE',
      );
      expect(refused(pdf(isPdf: false)), 'NOT_A_PDF');
    });

    test('tailles à la française', () {
      expect(VoxFormat.pages(1), '1 page');
      expect(VoxFormat.pages(84), '84 pages');
      expect(VoxFormat.bytes(500), '1 Ko');
      expect(VoxFormat.bytes(850 * 1024), '850 Ko');
      expect(VoxFormat.bytes(6710886), '6,4 Mo');
      expect(VoxFormat.bytes(50 * 1024 * 1024), '50,0 Mo');
    });
  });

  group('ImportDocument', () {
    late FakeUploads uploads;
    late FakePdfSource source;
    late List<Duration> waits;
    late List<ImportProgress> progress;

    setUp(() {
      uploads = FakeUploads();
      source = FakePdfSource();
      waits = [];
      progress = [];
    });

    ImportDocument useCase() =>
        ImportDocument(uploads, source, wait: (d) async => waits.add(d));

    Future<Result<String, Failure>> run({
      PickedPdf? file,
      String title = '  Droit   civil ',
      bool attested = true,
      Future<void>? cancel,
    }) => useCase()(
      file: file ?? pdf(),
      title: title,
      rightsAttested: attested,
      cancel: cancel,
      onProgress: progress.add,
    );

    test('crée, envoie, confirme, puis efface la copie locale', () async {
      final result = await run();

      expect(result, isA<Ok<String, Failure>>());
      expect(codeOf(result), isNull);
      expect((result as Ok<String, Failure>).value, 'doc-1');
      expect(uploads.requests.single, (
        title: 'Droit civil',
        sizeBytes: 6710886,
      ));
      expect(uploads.sends, ['doc-1']);
      expect(uploads.confirms, ['doc-1']);
      expect(source.discarded, hasLength(1));
      expect(progress.map((p) => p.stage).toSet(), ImportStage.values.toSet());
      expect(progress.last.sent, progress.last.total);
    });

    test('un refus local ou un titre invalide n’appelle rien', () async {
      expect(codeOf(await run(attested: false)), 'RIGHTS_NOT_ATTESTED');
      expect(codeOf(await run(title: '   ')), 'INVALID_DOCUMENT_TITLE');
      expect(uploads.requests, isEmpty);
    });

    test('coupure réseau : l’envoi est relancé avec la même URL', () async {
      uploads.sendCodes = ['NETWORK_UNAVAILABLE', 'TIMEOUT', null];

      final result = await run();

      expect(codeOf(result), isNull);
      expect(uploads.requests, hasLength(1));
      expect(uploads.sends, ['doc-1', 'doc-1', 'doc-1']);
      expect(waits, ImportDocument.retryDelays.take(2));
      expect(progress.map((p) => p.attempt).toSet(), {1, 2, 3});
    });

    test('URL expirée (403) : un nouveau document est demandé', () async {
      uploads.sendCodes = ['FORBIDDEN', null];

      final result = await run();

      expect((result as Ok<String, Failure>).value, 'doc-2');
      expect(uploads.sends, ['doc-1', 'doc-2']);
      expect(uploads.confirms, ['doc-2']);
    });

    test('après 3 relances, l’échec est rendu et la copie gardée', () async {
      uploads.sendCodes = List.filled(4, 'NETWORK_UNAVAILABLE', growable: true);

      expect(codeOf(await run()), 'NETWORK_UNAVAILABLE');
      expect(uploads.sends, hasLength(4));
      expect(uploads.confirms, isEmpty);
      expect(source.discarded, isEmpty);
    });

    test('une autre erreur d’envoi n’est pas relancée', () async {
      uploads.sendCodes = ['SERVER_ERROR'];
      expect(codeOf(await run()), 'SERVER_ERROR');
      expect(uploads.sends, hasLength(1));
    });

    test('création refusée par le backend : rien n’est envoyé', () async {
      uploads.requestCode = 'INVALID_DOCUMENT_SIZE';
      expect(codeOf(await run()), 'INVALID_DOCUMENT_SIZE');
      expect(uploads.sends, isEmpty);
    });

    test('confirmation : un essai de plus après une coupure', () async {
      uploads.confirmCodes = ['TIMEOUT'];
      expect(codeOf(await run()), isNull);
      expect(uploads.confirms, ['doc-1', 'doc-1']);

      uploads.confirmCodes = ['INVALID_DOCUMENT_UPLOAD'];
      expect(codeOf(await run()), 'INVALID_DOCUMENT_UPLOAD');
    });

    test('annuler pendant l’envoi ou pendant la pause', () async {
      final cancel = Completer<void>();
      uploads.sendGate = Completer<void>();
      final running = run(cancel: cancel.future);
      await pumpEventQueue();
      cancel.complete();
      expect(codeOf(await running), 'CANCELLED');
      expect(uploads.confirms, isEmpty);

      // Annulé pendant l'attente avant un nouvel essai.
      uploads
        ..sendGate = null
        ..sendCodes = ['NETWORK_UNAVAILABLE', null];
      final cancelLater = Completer<void>();
      final blocked = ImportDocument(
        uploads,
        source,
        wait: (_) => Completer<void>().future,
      );
      final paused = blocked(
        file: pdf(),
        title: 'Titre',
        rightsAttested: true,
        cancel: cancelLater.future,
      );
      await pumpEventQueue();
      cancelLater.complete();
      expect(codeOf(await paused), 'CANCELLED');

      // Déjà annulé avant l'envoi.
      expect(codeOf(await run(cancel: Future.value())), 'CANCELLED');
    });

    test('PickPdf choisit et efface', () async {
      source.next = pdf();
      final pick = PickPdf(source);
      final file = await pick();
      await pick.discard(file!);
      expect(source.discarded, [file]);
    });
  });
}
