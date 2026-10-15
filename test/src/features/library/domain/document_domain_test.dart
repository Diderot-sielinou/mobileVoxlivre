import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/domain/document_title.dart';

import '../fakes.dart';

void main() {
  test('les étapes du backend sont lues, l’inconnue ne casse rien', () {
    expect(
      [
        'awaiting_upload',
        'uploaded',
        'extracting',
        'text_ready',
        'extraction_failed',
        'archived',
      ].map(DocumentStage.fromWire),
      DocumentStage.values,
    );
    expect(
      DocumentStage.values.where((s) => s.working),
      [
        DocumentStage.awaitingUpload,
        DocumentStage.uploaded,
        DocumentStage.extracting,
      ],
    );
  });

  test('la relecture n’est due que si elle est imposée et pas faite', () {
    expect(sheet('a').reviewPending, isFalse);
    expect(sheet('a', reviewRequired: true).reviewPending, isTrue);
    expect(
      sheet(
        'a',
        reviewRequired: true,
        reviewedAt: DateTime.utc(2026, 10, 14),
      ).reviewPending,
      isFalse,
    );
  });

  test('étape de l’analyse déduite du backend', () {
    AnalysisStep step(
      DocumentStage stage, {
      ExtractionMethod? method,
      ({int done, int total})? ocr,
    }) => sheet(
      'a',
      stage: stage,
      method: method,
      ocrProgress: ocr,
    ).analysisStep;

    expect(step(DocumentStage.awaitingUpload), AnalysisStep.received);
    expect(step(DocumentStage.uploaded), AnalysisStep.reading);
    expect(step(DocumentStage.extracting), AnalysisStep.reading);
    expect(
      step(DocumentStage.extracting, method: ExtractionMethod.ocr),
      AnalysisStep.recognizing,
    );
    expect(
      step(DocumentStage.extracting, ocr: (done: 20, total: 120)),
      AnalysisStep.recognizing,
    );
    expect(
      step(DocumentStage.extracting, ocr: (done: 120, total: 120)),
      AnalysisStep.cleaning,
    );
    expect(step(DocumentStage.textReady), AnalysisStep.ready);
    expect(sheet('a', method: null).scanned, isFalse);
  });

  group('DocumentTitle (mêmes règles que le backend)', () {
    String? parsed(String input) => switch (DocumentTitle.parse(input)) {
      Ok(:final value) => value,
      Err() => null,
    };

    test('normalise les espaces', () {
      expect(parsed('  Droit   civil\n L2 '), 'Droit civil L2');
    });

    test('refuse le vide, plus de 200 caractères, les caractères de '
        'contrôle', () {
      expect(parsed('   '), isNull);
      expect(parsed('a' * 200), hasLength(200));
      expect(parsed('a' * 201), isNull);
      expect(parsed('Droit\u0007civil'), isNull);
      expect(parsed('Droit\u0085civil'), isNull);
      expect(
        const InvalidDocumentTitle().code,
        'INVALID_DOCUMENT_TITLE',
      );
    });
  });
}
