import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
import 'package:voxlivre/src/features/library/presentation/library_texts.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/empty_library.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/library_card.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/library_skeleton.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/resume_card.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_cover.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

import '../../../../helpers/app_harness.dart';
import '../fakes.dart';

/// Écran de téléphone haut (400 × 2000) : toutes les cartes sont
/// construites.
void tallScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1200, 6000)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  final shelf = [
    book(
      'droit',
      title: 'Droit civil et obligations',
      status: LibraryStatus.inProgress,
      progressPercent: 68,
      listenedAt: DateTime.utc(2026, 10, 12, 20),
    ),
    book('eco', title: 'Économie camerounaise'),
    book(
      'histoire',
      title: 'Histoire de l’Afrique centrale',
      status: LibraryStatus.processing,
      partsReady: 8,
      partCount: 10,
    ),
    book(
      'scan',
      title: 'Polycopié scanné',
      status: LibraryStatus.failed,
      extractionError: 'ocr_no_text',
    ),
    book('fini', status: LibraryStatus.finished, progressPercent: 100),
  ];

  Future<Harness> open(
    WidgetTester tester, {
    List<LibraryItem> remote = const [],
    String? failure,
    LibrarySnapshot? cached,
    bool reduceMotion = false,
  }) {
    tallScreen(tester);
    final library = FakeLibraryRepository(remote: remote, cached: cached)
      ..failure = failure;
    return pumpVoxlivre(
      tester,
      token: 'jeton',
      library: library,
      reduceMotion: reduceMotion,
    );
  }

  /// Le minuteur de 15 s tourne : on quitte l'écran avant la fin du test.
  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('nouveau compte : la bibliothèque vide invite à importer', (
    tester,
  ) async {
    final h = await open(tester);

    expect(h.library.refreshes, 1);
    expect(find.byType(EmptyLibrary), findsOneWidget);
    expect(find.text('Importez votre premier PDF'), findsOneWidget);

    await tester.tap(find.text('Importer un PDF'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Importer'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('les livres, la carte « Reprendre » et les filtres', (
    tester,
  ) async {
    await open(tester, remote: shelf);

    expect(find.byType(ResumeCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ResumeCard),
        matching: find.text('Droit civil et obligations'),
      ),
      findsOneWidget,
    );
    expect(find.text('68 % lu · Reste 24 min'), findsOneWidget);
    expect(find.text('Tous (5)'), findsOneWidget);
    expect(find.text('En cours (1)'), findsOneWidget);
    expect(find.text('Prêts (1)'), findsOneWidget);
    expect(find.text('Terminés (1)'), findsOneWidget);
    expect(find.text('Conversion · 8/10 parties'), findsOneWidget);
    expect(find.text('Aucun texte reconnu dans le scan'), findsOneWidget);
    expect(find.text('1 h 14 d’écoute'), findsOneWidget);

    // Les puces défilent de côté, comme sur le téléphone.
    await tester.ensureVisible(find.text('Prêts (1)'));
    await tester.tap(find.text('Prêts (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryCard), findsOneWidget);
    expect(find.text('Économie camerounaise'), findsOneWidget);

    await tester.ensureVisible(find.text('Terminés (1)'));
    await tester.tap(find.text('Terminés (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Livre fini'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('hors ligne avec un cache : les livres restent, un bandeau', (
    tester,
  ) async {
    await open(
      tester,
      failure: 'NETWORK_UNAVAILABLE',
      cached: LibrarySnapshot(
        items: shelf,
        // Deux heures avant l'horloge de test (10 h) : le cache est relu.
        refreshedAt: DateTime.utc(2026, 10, 13, 8),
      ),
    );

    expect(find.byType(LibraryCard), findsNWidgets(5));
    expect(
      find.text(
        'Hors ligne : vos livres téléchargés restent disponibles. '
        'Dernière mise à jour il y a 2 h.',
      ),
      findsOneWidget,
    );
    // Bandeau + chaque livre non téléchargé (ADR-0011).
    expect(find.byIcon(Icons.cloud_off_outlined), findsNWidgets(6));
    expect(find.text('Nécessite une connexion'), findsNWidgets(5));
    expect(
      tester
          .widget<InkWell>(
            find.descendant(
              of: find.byType(LibraryCard).first,
              matching: find.byType(InkWell),
            ),
          )
          .onTap,
      isNull,
      reason: 'non cliquable hors ligne',
    );
    await leave(tester);
  });

  testWidgets('sans cache ni serveur : l’erreur et « Réessayer »', (
    tester,
  ) async {
    final h = await open(tester, remote: shelf, failure: 'SERVER_ERROR');

    expect(find.textContaining('Service momentanément'), findsOneWidget);
    expect(find.byType(LibraryCard), findsNothing);

    h.library.failure = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryCard), findsNWidgets(5));
    expect(find.textContaining('Service momentanément'), findsNothing);
    await leave(tester);
  });

  testWidgets('pendant le chargement : des squelettes', (tester) async {
    tallScreen(tester);
    final library = FakeLibraryRepository(remote: shelf)
      ..gate = Completer<void>();
    await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: library,
      settle: false,
    );

    expect(find.byType(LibrarySkeleton), findsOneWidget);
    expect(
      find.bySemanticsLabel('Chargement de la bibliothèque'),
      findsOneWidget,
    );

    library.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LibrarySkeleton), findsNothing);
    expect(find.byType(LibraryCard), findsNWidgets(5));
    await leave(tester);
  });

  testWidgets('un livre en préparation : rafraîchi toutes les 15 s', (
    tester,
  ) async {
    final h = await open(tester, remote: shelf);
    expect(h.library.refreshes, 1);

    await tester.pump(const Duration(seconds: 15));
    expect(h.library.refreshes, 2);

    // Plus rien en préparation : on n'interroge plus le réseau.
    h.library.remote = [book('eco')];
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 15));
    expect(h.library.refreshes, 3);
    await leave(tester);
  });

  testWidgets('tirer vers le bas rafraîchit malgré un cache récent', (
    tester,
  ) async {
    final h = await open(tester, remote: [book('eco')]);

    // Le seuil vaut un quart de la hauteur de l'écran.
    await tester.drag(find.byType(LibraryCard), const Offset(0, 700));
    await tester.pumpAndSettle();

    expect(h.library.refreshes, 2);
    await leave(tester);
  });

  testWidgets('« réduire les animations » : pas de cascade', (tester) async {
    await open(tester, remote: shelf, reduceMotion: true);

    expect(
      find.ancestor(
        of: find.byType(LibraryCard).first,
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsNothing,
    );
    await leave(tester);
  });

  testWidgets('accessibilité de la bibliothèque remplie', (tester) async {
    await open(tester, remote: shelf);

    expect(
      find.bySemanticsLabel(
        RegExp('^Droit civil et obligations. À reprendre. Reste'),
      ),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await leave(tester);
  });

  group('textes', () {
    test('durées et anciennetés en français', () {
      final now = DateTime.utc(2026, 10, 13, 12);
      expect(
        VoxFormat.listening(const Duration(seconds: 20)),
        'moins d’une minute',
      );
      expect(VoxFormat.listening(const Duration(minutes: 42)), '42 min');
      expect(VoxFormat.listening(const Duration(minutes: 120)), '2 h');
      expect(VoxFormat.listening(const Duration(minutes: 74)), '1 h 14');
      expect(VoxFormat.ago(now, now), 'à l’instant');
      expect(
        VoxFormat.ago(now.subtract(const Duration(minutes: 5)), now),
        'il y a 5 min',
      );
      expect(
        VoxFormat.ago(now.subtract(const Duration(hours: 3)), now),
        'il y a 3 h',
      );
      expect(VoxFormat.ago(now.subtract(const Duration(days: 1)), now), 'hier');
      expect(
        VoxFormat.ago(now.subtract(const Duration(days: 4)), now),
        'il y a 4 jours',
      );
    });

    test('une ligne par statut, une raison par code d’échec', () {
      expect(
        statusDetail(book('a', status: LibraryStatus.notConverted)),
        '84 pages · à convertir',
      );
      expect(
        statusDetail(
          book('a', status: LibraryStatus.notConverted, pageCount: null),
        ),
        'À convertir',
      );
      expect(
        statusDetail(book('a', status: LibraryStatus.finished)),
        '1 h 14 écoutées',
      );
      expect(statusDetail(book('a', status: LibraryStatus.unknown)), '');
      for (final code in [
        'unreadable',
        'empty',
        'scanned',
        'ocr_too_many_pages',
        'ocr_quota_exceeded',
        'source_missing',
        'text_changed',
        'empty_text',
        'tts_rejected',
        'source_unavailable',
      ]) {
        expect(
          failureText(extraction: code),
          isNot(failureText(extraction: 'internal')),
          reason: code,
        );
      }
      expect(
        failureText(conversion: 'tts_rejected'),
        'La voix a refusé ce texte',
      );
    });

    test('la couverture générée est stable pour un titre', () {
      expect(
        VoxCover.paletteFor('Droit civil'),
        VoxCover.paletteFor('Droit civil'),
      );
      expect(
        {
          for (final t in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'])
            VoxCover.paletteFor(t),
        }.length,
        greaterThan(1),
      );
    });
  });
}
