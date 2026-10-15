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

    group('par morceaux (ADR-0009)', () {
      const mib = 1024 * 1024;
      // 12 Mio : morceaux de 5, 5 et 2 Mio.
      final big = pdf(sizeBytes: 12 * mib);

      setUp(() => uploads.partSize = 5 * mib);

      test('envoie chaque morceau, puis confirme', () async {
        final result = await run(file: big);

        expect(codeOf(result), isNull);
        expect(uploads.sentParts, [1, 2, 3]);
        expect(uploads.sends, isEmpty, reason: 'pas de PUT unique');
        expect(uploads.confirms, ['doc-1']);
        expect(progress.where((p) => p.resumable), isNotEmpty);
        final last = progress.lastWhere((p) => p.stage == ImportStage.sending);
        expect(last.sent, 12 * mib);
      });

      test('coupure : la reprise n’envoie que les morceaux absents', () async {
        uploads.partCodes = [null, 'NETWORK_UNAVAILABLE'];

        final result = await run(file: big);

        expect(codeOf(result), isNull);
        expect(uploads.sentParts, [1, 2, 2, 3], reason: '1 n’est pas renvoyé');
        expect(uploads.prepares, 2);
        expect(waits, [ImportDocument.retryDelays.first]);
        final resumed = progress.firstWhere((p) => p.attempt == 2);
        expect(resumed.sent, 5 * mib, reason: 'repart des octets reçus');
      });

      test(
        'un morceau qui passe remet le compteur de relances à zéro',
        () async {
          uploads.partCodes = [
            'TIMEOUT',
            null,
            'TIMEOUT',
            null,
            'TIMEOUT',
            'TIMEOUT',
            null,
          ];

          expect(codeOf(await run(file: big)), isNull);
          expect(uploads.storedParts, {1, 2, 3});
        },
      );

      test('trois échecs d’affilée sans progrès arrêtent l’import', () async {
        uploads.partCodes = List.filled(
          4,
          'NETWORK_UNAVAILABLE',
          growable: true,
        );

        expect(codeOf(await run(file: big)), 'NETWORK_UNAVAILABLE');
        expect(uploads.confirms, isEmpty);
        expect(source.discarded, isEmpty);
      });

      test(
        'reprise impossible à préparer puis rétablie ; URL expirée',
        () async {
          uploads
            ..prepareCodes = ['TIMEOUT']
            ..partCodes = ['FORBIDDEN'];

          expect(codeOf(await run(file: big)), isNull);
          expect(uploads.prepares, 3);
          expect(uploads.sentParts, [1, 1, 2, 3]);
        },
      );

      test('déjà assemblé (409) : on confirme ; autre refus : rendu', () async {
        uploads.prepareCodes = ['DOCUMENT_UPLOAD_CONFLICT'];
        expect(codeOf(await run(file: big)), isNull);
        expect(uploads.sentParts, isEmpty);
        expect(uploads.confirms, ['doc-1']);

        uploads.prepareCodes = ['DOCUMENT_NOT_FOUND'];
        expect(codeOf(await run(file: big)), 'DOCUMENT_NOT_FOUND');

        uploads.partCodes = ['SERVER_ERROR'];
        expect(codeOf(await run(file: big)), 'SERVER_ERROR');
      });

      test('tout est déjà reçu : confirmation directe', () async {
        uploads.storedParts.addAll([1, 2, 3]);
        expect(codeOf(await run(file: big)), isNull);
        expect(uploads.sentParts, isEmpty);
      });

      test('annuler pendant un morceau', () async {
        uploads.partCodes = ['CANCELLED'];
        expect(codeOf(await run(file: big)), 'CANCELLED');
        expect(
          codeOf(await run(file: big, cancel: Future.value())),
          'CANCELLED',
        );
      });

      test('plan des morceaux', () {
        expect(PartPlan.offsetOf(3, 5 * mib), 10 * mib);
        expect(PartPlan.lengthOf(3, 5 * mib, 12 * mib), 2 * mib);
        expect(PartPlan.lengthOf(1, 5 * mib, 12 * mib), 5 * mib);
      });
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
