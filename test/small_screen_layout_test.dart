import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/pages/ask_gita_page/ask_gita_page_widget.dart';
import 'package:gita_wisdom/pages/home_page/home_page_widget.dart';
import 'package:gita_wisdom/pages/journal_page/journal_page_widget.dart';
import 'package:gita_wisdom/pages/search_page/search_page_widget.dart';
import 'package:gita_wisdom/pages/settings_page/settings_page_widget.dart';
import 'package:gita_wisdom/pages/transformation_page/transformation_page_widget.dart';
import 'package:gita_wisdom/pages/verse_reader_page/verse_reader_page_widget.dart';
import 'package:gita_wisdom/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitaDataService.resetForTests();
  });

  Future<void> pumpSmallScreen(
    WidgetTester tester,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: child,
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder,
  ) async {
    for (var i = 0; i < 20; i += 1) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  final screens = <String, Widget>{
    'HomeScreen': const HomePageWidget(),
    'VerseReaderScreen': const VerseReaderPageWidget(verseId: '2.47'),
    'AskGitaLiteScreen': const AskGitaPageWidget(),
    'SearchScreen': const SearchPageWidget(),
    'JournalScreen': const JournalPageWidget(),
    'SettingsScreen': const SettingsPageWidget(),
    'JourneysScreen': const TransformationPageWidget(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders on small phone dimensions', (
      tester,
    ) async {
      await tester.runAsync(() => GitaRepository.load());
      await pumpSmallScreen(tester, entry.value);
    });
  }

  testWidgets('VerseReader shows reading content before scrolling', (
    tester,
  ) async {
    await tester.runAsync(() => GitaRepository.load());
    await pumpSmallScreen(
      tester,
      const VerseReaderPageWidget(verseId: '2.47'),
    );
    await pumpUntilFound(tester, find.text('Translation'));

    final sanskritRect =
        tester.getRect(find.textContaining('कर्मण्येवाधिकारस्ते'));
    final transliterationRect =
        tester.getRect(find.textContaining('karmaṇyevādhikāraste'));
    final translationRect = tester.getRect(find.text('Translation'));

    expect(sanskritRect.top, lessThan(568));
    expect(transliterationRect.top, lessThan(568));
    expect(find.text('Translation'), findsOneWidget);
    expect(translationRect.top, lessThan(568));
  });

  testWidgets('VerseReader shows compact journey context', (
    tester,
  ) async {
    await tester.runAsync(() => GitaRepository.load());
    await pumpSmallScreen(
      tester,
      const VerseReaderPageWidget(
        verseId: '2.47',
        journeyId: 'journey_peace_7',
        journeyName: 'Journey to Peace',
        journeyDay: 1,
        journeyTotalDays: 7,
        journeyDayTitle: 'Act without clinging',
        nextJourneyDayTitle: 'Feelings pass',
      ),
    );
    await pumpUntilFound(tester, find.textContaining('Journey to Peace'));

    expect(
      find.text('Journey to Peace • Day 1 of 7'),
      findsOneWidget,
    );
    expect(find.text("Complete Today's Reflection"), findsOneWidget);
    expect(find.text('Back to Journey'), findsNothing);
    expect(find.text('Mark Day Complete'), findsNothing);
    expect(find.text('Day Complete'), findsNothing);
    expect(find.text('Continue Journey'), findsNothing);
    expect(find.text('Previous Verse'), findsNothing);
    expect(find.text('Next Verse'), findsNothing);
    expect(find.textContaining('कर्मण्येवाधिकारस्ते'), findsOneWidget);
    expect(find.textContaining('karmaṇyevādhikāraste'), findsOneWidget);
    expect(find.text('Translation'), findsOneWidget);

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);

    expect(currentJourneyId, 'journey_peace_7');
    expect(currentJourneyDay, 1);
  });
}
