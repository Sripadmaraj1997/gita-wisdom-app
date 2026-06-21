import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/pages/home_page/home_page_widget.dart';
import 'package:gita_wisdom/pages/transformation_page/transformation_page_widget.dart';
import 'package:gita_wisdom/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitaDataService.resetForTests();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePageWidget(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpJourneys(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TransformationPageWidget(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 24; i += 1) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('fresh install Continue opens Journey to Peace Day 1', (
    tester,
  ) async {
    await tester.runAsync(GitaRepository.load);

    await pumpHome(tester);
    final homeContinue = find.byKey(const ValueKey('home_journey_continue'));
    await pumpUntilFound(tester, homeContinue);

    expect(await tester.runAsync(LocalStorageService.currentJourneyId), isNull);

    await tester.ensureVisible(homeContinue);
    await tester.pump();
    await tester.tap(homeContinue);
    await tester.pumpAndSettle();

    expect(find.byType(HomePageWidget), findsNothing);
    expect(find.byType(TransformationPageWidget), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 1 of 7'), findsOneWidget);
    expect(find.text("Today's Theme"), findsOneWidget);
    expect(find.text('Verse Reference'), findsOneWidget);
    expect(find.text('Sanskrit'), findsOneWidget);
    expect(find.text('Transliteration'), findsOneWidget);
    expect(find.text('Translation'), findsOneWidget);
    expect(find.text('Gita Wisdom Interpretation'), findsOneWidget);
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Practice Today'), findsOneWidget);
    expect(find.text('Mark Day Complete'), findsOneWidget);
    expect(find.text("Read Today's Verse"), findsNothing);

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);

    expect(currentJourneyId, 'journey_peace_7');
    expect(currentJourneyDay, 1);
  });

  testWidgets('active journey Day 1 incomplete shows full reading inline', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      await LocalStorageService.startJourney('journey_peace_7');
    });

    await pumpJourneys(tester);
    await pumpUntilFound(tester, find.text('Day 1 of 7'));

    expect(find.byType(HomePageWidget), findsNothing);
    expect(find.byType(TransformationPageWidget), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 1 of 7'), findsOneWidget);
    expect(find.text("Today's Theme"), findsOneWidget);
    expect(find.text('Verse Reference'), findsOneWidget);
    expect(find.text('Sanskrit'), findsOneWidget);
    expect(find.text('Transliteration'), findsOneWidget);
    expect(find.text('Translation'), findsOneWidget);
    expect(find.text('Gita Wisdom Interpretation'), findsOneWidget);
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Practice Today'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Mark Day Complete'), findsOneWidget);
    expect(find.text("Read Today's Verse"), findsNothing);
  });

  testWidgets('active journey Day 1 complete continues to Day 2 from Home', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      await LocalStorageService.startJourney('journey_peace_7');
      await LocalStorageService.setJourneyDayComplete(
        journeyId: 'journey_peace_7',
        day: 1,
        complete: true,
        totalDays: 7,
      );
    });

    await pumpHome(tester);
    final homeContinue = find.byKey(const ValueKey('home_journey_continue'));
    await pumpUntilFound(tester, homeContinue);

    await tester.ensureVisible(homeContinue);
    await tester.pump();
    await tester.tap(homeContinue);
    await tester.pumpAndSettle();

    expect(find.byType(HomePageWidget), findsNothing);
    expect(find.byType(TransformationPageWidget), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 2 of 7'), findsOneWidget);
  });

  testWidgets(
      'active complete journey chooses next journey from completed state', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      await LocalStorageService.setCurrentJourneyId('journey_peace_7');
      for (var day = 1; day <= 7; day += 1) {
        await LocalStorageService.setJourneyDayComplete(
          journeyId: 'journey_peace_7',
          day: day,
          complete: true,
          totalDays: 7,
        );
      }
    });

    await pumpJourneys(tester);
    await pumpUntilFound(
      tester,
      find.text('You completed this journey with sincerity and practice.'),
    );

    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('🌸 Journey Complete'), findsWidgets);
    expect(find.text('7 Days of Reflection'), findsWidgets);
    expect(
      find.text('You completed this journey with sincerity and practice.'),
      findsWidgets,
    );
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Choose Next Journey'), findsOneWidget);
    expect(find.text('Save Reflection'), findsNothing);

    final chooseNext = find.byKey(const ValueKey('journey_choose_next'));
    await tester.ensureVisible(chooseNext);
    await tester.pump();
    await tester.tap(chooseNext);
    await tester.pumpAndSettle();

    expect(find.text('Choose Next Journey'), findsWidgets);
    final discipline =
        find.byKey(const ValueKey('journey_next_journey_discipline_14'));
    await tester.ensureVisible(discipline);
    await tester.pump();
    await tester.tap(discipline);
    await tester.pumpAndSettle();

    await pumpUntilFound(tester, find.text('Day 1 of 14'));
    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Day 1 of 14'), findsOneWidget);
    expect(
      find.text('You completed this journey with sincerity and practice.'),
      findsNothing,
    );

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);
    final completedIds = await tester.runAsync(
      LocalStorageService.completedJourneyIds,
    );
    expect(currentJourneyId, 'journey_discipline_14');
    expect(currentJourneyDay, 1);
    expect(completedIds, contains('journey_peace_7'));

    await pumpHome(tester);
    await pumpUntilFound(tester, find.text('Journey of Discipline'));
    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Day 1 of 14'), findsOneWidget);
  });

  testWidgets(
      'Choose Next Journey overrides stale completed initial journey route', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      await LocalStorageService.setCurrentJourneyId('journey_peace_7');
      for (var day = 1; day <= 7; day += 1) {
        await LocalStorageService.setJourneyDayComplete(
          journeyId: 'journey_peace_7',
          day: day,
          complete: true,
          totalDays: 7,
        );
      }
    });

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TransformationPageWidget(initialJourneyId: 'journey_peace_7'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 2));
    await pumpUntilFound(
      tester,
      find.text('You completed this journey with sincerity and practice.'),
    );

    final chooseNext = find.byKey(const ValueKey('journey_choose_next'));
    await tester.ensureVisible(chooseNext);
    await tester.pump();
    await tester.tap(chooseNext);
    await tester.pumpAndSettle();

    final discipline =
        find.byKey(const ValueKey('journey_next_journey_discipline_14'));
    await tester.ensureVisible(discipline);
    await tester.pump();
    await tester.tap(discipline);
    await tester.pumpAndSettle();

    await pumpUntilFound(tester, find.text('Day 1 of 14'));
    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Day 1 of 14'), findsOneWidget);
    expect(
      find.text('You completed this journey with sincerity and practice.'),
      findsNothing,
    );

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);
    expect(currentJourneyId, 'journey_discipline_14');
    expect(currentJourneyDay, 1);
  });

  testWidgets('Home updates and persists completed Journey to Peace', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      for (var day = 1; day <= 6; day += 1) {
        await LocalStorageService.setJourneyDayComplete(
          journeyId: 'journey_peace_7',
          day: day,
          complete: true,
        );
      }
    });

    await pumpHome(tester);
    await pumpUntilFound(tester, find.text('Journey to Peace'));

    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 7 of 7'), findsOneWidget);
    expect(
      find.text('You completed this journey with sincerity and practice.'),
      findsNothing,
    );

    await tester.runAsync(() async {
      await LocalStorageService.setJourneyDayComplete(
        journeyId: 'journey_peace_7',
        day: 7,
        complete: true,
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Continue Your Journey'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home_journey_continue')),
      findsOneWidget,
    );
    expect(find.text('Day 7 of 7'), findsOneWidget);
    expect(
      find.text('You completed this journey with sincerity and practice.'),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpHome(tester);
    await pumpUntilFound(tester, find.text('Journey to Peace'));

    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 7 of 7'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home_journey_continue')),
      findsOneWidget,
    );
  });

  testWidgets('Journeys screen completes final day and continues automatically',
      (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      for (var day = 1; day <= 6; day += 1) {
        await LocalStorageService.setJourneyDayComplete(
          journeyId: 'journey_peace_7',
          day: day,
          complete: true,
          totalDays: 7,
        );
      }
      await LocalStorageService.setJourneyDayComplete(
        journeyId: 'journey_peace_7',
        day: 7,
        complete: true,
        totalDays: 7,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TransformationPageWidget(
          completedJourneyId: 'journey_peace_7',
          completedJourneyDay: 7,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 2));
    await pumpUntilFound(tester, find.text('Day 7 of 7'));

    expect(
      find.text('You completed this journey with sincerity and practice.'),
      findsWidgets,
    );
    expect(find.text('What insight will you carry forward?'), findsWidgets);
    expect(find.text('7 Days of Reflection'), findsWidgets);
    expect(find.text('Choose Next Journey'), findsOneWidget);
    expect(find.text('Journey of Discipline'), findsNothing);
    expect(find.text('Journey Through Anxiety'), findsNothing);
    expect(find.text('Journey of Karma Yoga'), findsNothing);
    expect(find.text('Journey to Inner Clarity'), findsNothing);
    expect(
      find.byKey(const ValueKey('journey_completion_continue')),
      findsNothing,
    );
    expect(find.text('Save Reflection'), findsNothing);

    final completedIds = await tester.runAsync(
      LocalStorageService.completedJourneyIds,
    );
    expect(completedIds, contains('journey_peace_7'));

    final chooseNext = find.byKey(const ValueKey('journey_choose_next'));
    await tester.ensureVisible(chooseNext);
    await tester.pump();
    await tester.tap(chooseNext);
    await tester.pumpAndSettle();

    final nextDiscipline =
        find.byKey(const ValueKey('journey_next_journey_discipline_14'));
    await tester.ensureVisible(nextDiscipline);
    await tester.pump();
    await tester.tap(nextDiscipline);
    await tester.pumpAndSettle();

    await pumpUntilFound(tester, find.text('Day 1 of 14'));
    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Day 1 of 14'), findsOneWidget);
  });

  testWidgets('all completed journeys show reflective continuation state', (
    tester,
  ) async {
    const journeyTotals = {
      'journey_peace_7': 7,
      'journey_discipline_14': 14,
      'journey_karma_yoga_14': 14,
      'journey_anxiety_7': 7,
      'journey_clarity_21': 21,
    };

    await tester.runAsync(() async {
      await GitaRepository.load();
      for (final entry in journeyTotals.entries) {
        for (var day = 1; day <= entry.value; day += 1) {
          await LocalStorageService.setJourneyDayComplete(
            journeyId: entry.key,
            day: day,
            complete: true,
            totalDays: entry.value,
          );
        }
      }
      await LocalStorageService.setCurrentJourneyId('journey_clarity_21');
    });

    await pumpJourneys(tester);
    await pumpUntilFound(tester, find.text('🌸 All Journeys Complete'));

    expect(find.text('🌸 All Journeys Complete'), findsOneWidget);
    expect(find.text('Journey to Peace'), findsOneWidget);
    expect(find.text('Journey of Discipline'), findsOneWidget);
    expect(find.text('Journey of Karma Yoga'), findsOneWidget);
    expect(find.text('Journey Through Anxiety'), findsOneWidget);
    expect(find.text('Journey to Inner Clarity'), findsOneWidget);
    expect(find.textContaining('The journey of wisdom continues every day.'),
        findsNothing);
    expect(
      find.textContaining('Wisdom is not something we finish.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('It is something we return to again and again.'),
      findsOneWidget,
    );
    expect(find.text('Restart a Journey'), findsOneWidget);
    expect(find.text("Today's Guidance"), findsOneWidget);
    expect(find.text('Open Journal'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('100%'), findsNothing);
    expect(find.textContaining('trophy'), findsNothing);

    final restart = find.byKey(const ValueKey('journey_restart'));
    await tester.ensureVisible(restart);
    await tester.pump();
    await tester.tap(restart);
    await tester.pumpAndSettle();

    expect(find.text('Restart a Journey'), findsWidgets);
    expect(find.text('Reflected before'), findsWidgets);

    final peace = find.byKey(const ValueKey('journey_next_journey_peace_7'));
    await tester.ensureVisible(peace);
    await tester.pump();
    await tester.tap(peace);
    await tester.pumpAndSettle();

    expect(find.text('Restart Journey?'), findsOneWidget);
    await tester.tap(find.text('Restart Journey'));
    await tester.pumpAndSettle();

    await pumpUntilFound(tester, find.text('Day 1 of 7'));
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 1 of 7'), findsOneWidget);

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);
    final peaceDays = await tester.runAsync(
      () => LocalStorageService.completedJourneyDays('journey_peace_7'),
    );
    final completedIds = await tester.runAsync(
      LocalStorageService.completedJourneyIds,
    );

    expect(currentJourneyId, 'journey_peace_7');
    expect(currentJourneyDay, 1);
    expect(peaceDays, isEmpty);
    expect(completedIds, contains('journey_peace_7'));
    expect(completedIds, contains('journey_discipline_14'));
    expect(completedIds, contains('journey_karma_yoga_14'));
    expect(completedIds, contains('journey_anxiety_7'));
    expect(completedIds, contains('journey_clarity_21'));
  });

  testWidgets('completing a journey day advances current day guidance', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      await LocalStorageService.startJourney('journey_peace_7');
    });

    await pumpJourneys(tester);
    await pumpUntilFound(tester, find.text('Day 1 of 7'));

    final markComplete = find.byKey(
      const ValueKey('journey_mark_day_complete'),
    );
    await tester.ensureVisible(markComplete);
    await tester.pump();
    await tester.tap(markComplete);
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Day Complete'));

    expect(find.text('Day Complete'), findsOneWidget);
    expect(find.text('Next: Feelings pass'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('View Journey Overview'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('journey_completion_continue')));
    await tester.pumpAndSettle();

    expect(find.text('Day 2 of 7'), findsOneWidget);

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);
    final completedDays = await tester.runAsync(
      () => LocalStorageService.completedJourneyDays('journey_peace_7'),
    );

    expect(currentJourneyId, 'journey_peace_7');
    expect(currentJourneyDay, 2);
    expect(completedDays, contains(1));
  });

  testWidgets('completed journey Continue starts next journey from Home', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      for (var day = 1; day <= 7; day += 1) {
        await LocalStorageService.setJourneyDayComplete(
          journeyId: 'journey_peace_7',
          day: day,
          complete: true,
          totalDays: 7,
        );
      }
      await LocalStorageService.setJourneyDayComplete(
        journeyId: 'journey_discipline_14',
        day: 3,
        complete: true,
        totalDays: 14,
      );
      await LocalStorageService.setCurrentJourneyId('journey_peace_7');
    });

    await pumpHome(tester);
    final homeContinue = find.byKey(const ValueKey('home_journey_continue'));
    await pumpUntilFound(tester, homeContinue);

    await tester.ensureVisible(homeContinue);
    await tester.pump();
    await tester.tap(homeContinue);
    await tester.pumpAndSettle();

    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Day 1 of 14'), findsOneWidget);

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);
    final disciplineDays = await tester.runAsync(
      () => LocalStorageService.completedJourneyDays('journey_discipline_14'),
    );
    final completedIds = await tester.runAsync(
      LocalStorageService.completedJourneyIds,
    );
    expect(currentJourneyId, 'journey_discipline_14');
    expect(currentJourneyDay, 1);
    expect(disciplineDays, isEmpty);
    expect(completedIds, contains('journey_peace_7'));

    Navigator.of(tester.element(find.byType(TransformationPageWidget))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Day 1 of 14'), findsOneWidget);
  });
}
