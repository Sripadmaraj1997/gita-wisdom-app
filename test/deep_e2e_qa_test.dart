import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/pages/gita_common/gita_common.dart';
import 'package:gita_wisdom/pages/journal_page/journal_page_widget.dart';
import 'package:gita_wisdom/pages/saved_verses_page/saved_verses_page_widget.dart';
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
    expect(find.text('Mark'), findsOneWidget);

    await scrollToAndTap(tester, find.text('Save'));

    final saved =
        await tester.runAsync(LocalStorageService.savedVerses) ?? const [];
    expect(saved.map((verse) => verse.verseId), contains('2.47'));

    await scrollToAndTap(tester, find.text('Mark'));

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
    await pumpUntilFound(tester, find.text('Begin reflection'));

    await tester.tap(find.text('Begin reflection'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'QA reflection');
    await tester.enterText(
      find.byType(TextField).at(1),
      'A steady action brought more peace today.',
    );
    expect(find.text('Save Reflection'), findsOneWidget);
    await tester.tap(find.text('Save Reflection'));
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
    expect(find.text('Save Reflection'), findsOneWidget);
    await tester.tap(find.text('Save Reflection'));
    await tester.pumpAndSettle();

    expect(find.text('Edited reflection'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Reflection'));
    await tester.pumpAndSettle();

    expect(find.text('Begin with one honest reflection.'), findsOneWidget);
    expect(
      await tester.runAsync(LocalStorageService.journalEntries) ?? const [],
      isEmpty,
    );
  });

  testWidgets(
      'Journal saves guided clarity intention and gratitude after restart', (
    tester,
  ) async {
    await pumpScreen(tester, const JournalPageWidget());
    await pumpUntilFound(tester, find.text('Begin reflection'));

    await tester.tap(find.text('Begin reflection'));
    await tester.pumpAndSettle();

    final saveButtonFinder = find.widgetWithText(GoldButton, 'Save Reflection');
    expect(saveButtonFinder, findsOneWidget);
    expect(tester.widget<GoldButton>(saveButtonFinder).onPressed, isNull);

    await tester.showKeyboard(find.byType(TextField).at(1));
    await tester.pump(const Duration(milliseconds: 350));
    expect(saveButtonFinder, findsOneWidget);
    await tester.enterText(
      find.byType(TextField).at(1),
      'A quiet conversation gave clarity today.',
    );
    final intentionField = find.widgetWithText(TextField, 'Intention');
    await tester.scrollUntilVisible(
      intentionField,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.showKeyboard(intentionField);
    await tester.pump(const Duration(milliseconds: 350));
    expect(saveButtonFinder, findsOneWidget);
    await tester.enterText(
      intentionField,
      'Carry patience into the next conversation.',
    );
    final gratitudeField = find.widgetWithText(TextField, 'Gratitude');
    await tester.scrollUntilVisible(
      gratitudeField,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.showKeyboard(gratitudeField);
    await tester.pump(const Duration(milliseconds: 350));
    expect(saveButtonFinder, findsOneWidget);
    await tester.enterText(
      gratitudeField,
      'I am grateful for one sincere pause.',
    );
    expect(saveButtonFinder, findsOneWidget);
    expect(tester.widget<GoldButton>(saveButtonFinder).onPressed, isNotNull);
    await tester.tap(find.text('Save Reflection'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection saved.'), findsOneWidget);
    expect(
      find.text('A quiet conversation gave clarity today.'),
      findsWidgets,
    );

    final savedEntries = await tester.runAsync(
          LocalStorageService.journalEntries,
        ) ??
        const <LocalJournalEntry>[];
    expect(savedEntries, hasLength(1));
    expect(
        savedEntries.single.text, 'A quiet conversation gave clarity today.');
    expect(
      savedEntries.single.intention,
      'Carry patience into the next conversation.',
    );
    expect(
        savedEntries.single.gratitude, 'I am grateful for one sincere pause.');

    await pumpScreen(tester, const JournalPageWidget());
    await pumpUntilFound(
      tester,
      find.text('A quiet conversation gave clarity today.'),
    );
    expect(
      find.text('A quiet conversation gave clarity today.'),
      findsWidgets,
    );

    await pumpScreen(tester, const SavedVersesPageWidget());
    await pumpUntilFound(tester, find.text('Journal Reflections'));

    expect(find.text('Journal Reflections'), findsOneWidget);
    expect(
      find.text('A quiet conversation gave clarity today.'),
      findsWidgets,
    );
    expect(find.text('Carry patience into the next conversation.'),
        findsOneWidget);
    expect(find.text('I am grateful for one sincere pause.'), findsOneWidget);
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
    await pumpUntilFound(tester, find.text('Clear Local Memory'));

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Support'), findsWidgets);
    expect(find.text('Show Sanskrit'), findsOneWidget);
    expect(find.text('Show Transliteration'), findsOneWidget);

    await scrollToAndTap(tester, find.text('Clear Local Memory'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(
      await tester.runAsync(LocalStorageService.savedVerses) ?? const [],
      isNotEmpty,
    );

    await scrollToAndTap(tester, find.text('Clear Local Memory'));
    await tester.tap(find.text('Clear Local Memory').last);
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
