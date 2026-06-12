import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/pages/journal_page/journal_page_widget.dart';
import 'package:gita_wisdom/pages/settings_page/settings_page_widget.dart';
import 'package:gita_wisdom/pages/verse_reader_page/verse_reader_page_widget.dart';
import 'package:gita_wisdom/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitaDataService.resetForTests();
  });

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: KeyedSubtree(
          key: UniqueKey(),
          child: child,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder,
  ) async {
    for (var i = 0; i < 24; i += 1) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Verse Reader saves and highlights verses locally', (
    tester,
  ) async {
    await tester.runAsync(() => GitaRepository.load());
    await pumpScreen(tester, const VerseReaderPageWidget(verseId: '2.47'));
    await pumpUntilFound(tester, find.text('Translation'));

    expect(find.textContaining('कर्मण्येवाधिकारस्ते'), findsOneWidget);
    expect(find.textContaining('karmaṇyevādhikāraste'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);

    await scrollToAndTap(tester, find.text('Save'));

    final saved =
        await tester.runAsync(LocalStorageService.savedVerses) ?? const [];
    expect(saved.map((verse) => verse.verseId), contains('2.47'));

    await scrollToAndTap(tester, find.text('Highlight'));

    final highlighted = await tester
        .runAsync(() => LocalStorageService.isVerseHighlighted('2.47'));
    expect(highlighted, isTrue);
  });

  testWidgets('Verse Reader shows Play only for bundled audio assets', (
    tester,
  ) async {
    await tester.runAsync(() => GitaRepository.load());

    await pumpScreen(tester, const VerseReaderPageWidget(verseId: '1.1'));
    await tester.scrollUntilVisible(
      find.text('Play'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpUntilFound(tester, find.text('Play'));
    expect(find.text('Play'), findsOneWidget);

    await pumpScreen(tester, const VerseReaderPageWidget(verseId: '2.47'));
    await tester.scrollUntilVisible(
      find.text('Audio'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpUntilFound(tester, find.text('Audio'));
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
  });

  testWidgets('Journal can create, edit, and delete a local reflection', (
    tester,
  ) async {
    await pumpScreen(tester, const JournalPageWidget());
    await pumpUntilFound(tester, find.text('Create reflection'));

    await tester.tap(find.text('Create reflection'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'QA reflection');
    await tester.enterText(
      find.byType(TextField).at(1),
      'A steady action brought more peace today.',
    );
    await tester.scrollUntilVisible(
      find.text('Save reflection'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save reflection'));
    await tester.pumpAndSettle();

    expect(find.text('QA reflection'), findsOneWidget);
    expect(
      (await tester.runAsync(LocalStorageService.journalEntries) ?? const [])
          .length,
      1,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.edit_rounded).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Edited reflection');
    await tester.scrollUntilVisible(
      find.text('Save reflection'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save reflection'));
    await tester.pumpAndSettle();

    expect(find.text('Edited reflection'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Begin your reflection journey.'), findsOneWidget);
    expect(
      await tester.runAsync(LocalStorageService.journalEntries) ?? const [],
      isEmpty,
    );
  });

  testWidgets('Settings clears local data only after confirmation', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      final verse = await GitaRepository.verseById('2.47');
      expect(verse, isNotNull);
      await LocalStorageService.saveVerse(verse!);
      await LocalStorageService.setVerseHighlighted('2.47', highlighted: true);
      await LocalStorageService.setReaderFontScale(1.18);
    });

    await pumpScreen(tester, const SettingsPageWidget());
    await pumpUntilFound(tester, find.text('Clear Local Data'));

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Support'), findsWidgets);
    expect(find.text('Show Sanskrit'), findsOneWidget);
    expect(find.text('Show Transliteration'), findsOneWidget);

    await scrollToAndTap(tester, find.text('Clear Local Data'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(
      await tester.runAsync(LocalStorageService.savedVerses) ?? const [],
      isNotEmpty,
    );

    await scrollToAndTap(tester, find.text('Clear Local Data'));
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(
      await tester.runAsync(LocalStorageService.savedVerses) ?? const [],
      isEmpty,
    );
    expect(
      await tester.runAsync(
        () => LocalStorageService.isVerseHighlighted('2.47'),
      ),
      isFalse,
    );
  });

  test('Search finds verse references and emotional topics', () async {
    await GitaRepository.load();

    final referenceResults = await GitaRepository.search('2.47', limit: 5);
    expect(referenceResults, isNotEmpty);
    expect(referenceResults.first.verse.id, '2.47');

    for (final topic in ['fear', 'stress', 'anger', 'purpose']) {
      final results = await GitaRepository.search(topic, limit: 8);
      expect(results, isNotEmpty, reason: 'Expected results for $topic');
      expect(
        results.any((result) {
          final verse = result.verse;
          return verse.allTags.contains(topic) ||
              verse.reflectionText.toLowerCase().contains(topic) ||
              verse.practiceToday.toLowerCase().contains(topic) ||
              verse.gitaWisdomInterpretation.toLowerCase().contains(topic);
        }),
        isTrue,
        reason: 'Expected a tagged or content match for $topic',
      );
    }
  });
}
