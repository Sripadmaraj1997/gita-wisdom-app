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

  testWidgets('fresh install Continue Journey opens Journey to Peace Day 1', (
    tester,
  ) async {
    await tester.runAsync(GitaRepository.load);

    await pumpHome(tester);
    await pumpUntilFound(tester, find.text('Continue Journey'));

    expect(await tester.runAsync(LocalStorageService.currentJourneyId), isNull);

    await tester.ensureVisible(find.text('Continue Journey'));
    await tester.pump();
    await tester.tap(find.text('Continue Journey'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePageWidget), findsNothing);
    expect(find.byType(TransformationPageWidget), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 1 of 7'), findsOneWidget);

    final currentJourneyId =
        await tester.runAsync(LocalStorageService.currentJourneyId);
    final currentJourneyDay =
        await tester.runAsync(LocalStorageService.currentJourneyDay);

    expect(currentJourneyId, 'journey_peace_7');
    expect(currentJourneyDay, 1);
  });

  testWidgets('active journey Day 1 incomplete continues Day 1 with guidance', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await GitaRepository.load();
      await LocalStorageService.startJourney('journey_peace_7');
    });

    await pumpJourneys(tester);
    await pumpUntilFound(tester, find.text('Day 1 of 7'));

    await tester.ensureVisible(find.text('Continue Journey'));
    await tester.pump();
    await tester.tap(find.text('Continue Journey'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePageWidget), findsNothing);
    expect(find.byType(TransformationPageWidget), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 1 of 7'), findsOneWidget);
    expect(
      find.text('Mark today’s practice complete to unlock the next day.'),
      findsOneWidget,
    );
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
    await pumpUntilFound(tester, find.text('Continue Journey'));

    await tester.ensureVisible(find.text('Continue Journey'));
    await tester.pump();
    await tester.tap(find.text('Continue Journey'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePageWidget), findsNothing);
    expect(find.byType(TransformationPageWidget), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('Day 2 of 7'), findsOneWidget);
  });

  testWidgets('active complete journey shows completed journey state', (
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
    await pumpUntilFound(tester, find.text('You completed Journey to Peace.'));

    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('You completed Journey to Peace.'), findsWidgets);
    expect(find.text('Start Next Journey'), findsOneWidget);
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
    expect(find.text('You completed Journey to Peace.'), findsNothing);

    await tester.runAsync(() async {
      await LocalStorageService.setJourneyDayComplete(
        journeyId: 'journey_peace_7',
        day: 7,
        complete: true,
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await pumpUntilFound(tester, find.text('You completed Journey to Peace.'));

    expect(find.text('You completed Journey to Peace.'), findsWidgets);
    expect(find.text('7 of 7 days complete'), findsOneWidget);
    expect(find.text('Start Next Journey'), findsOneWidget);
    expect(
      find.text('What insight will you carry forward?'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpHome(tester);
    await pumpUntilFound(tester, find.text('You completed Journey to Peace.'));

    expect(find.text('Journey to Peace'), findsWidgets);
    expect(find.text('You completed Journey to Peace.'), findsWidgets);
    expect(find.text('7 of 7 days complete'), findsOneWidget);
  });

  testWidgets('Journeys screen completes final day and shows next paths', (
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
    });

    await pumpJourneys(tester);
    await pumpUntilFound(tester, find.text('Day 7 of 7'));

    await tester.ensureVisible(find.text('Complete Day').first);
    await tester.pump();
    await tester.tap(find.text('Complete Day').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await pumpUntilFound(tester, find.text('Completed Journeys'));

    expect(find.text('You completed Journey to Peace.'), findsWidgets);
    expect(find.text('What insight will you carry forward?'), findsOneWidget);
    expect(find.text('What practice will you continue?'), findsOneWidget);
    expect(find.text('Completed Journeys'), findsOneWidget);
    expect(find.text('Recommended Next'), findsOneWidget);
    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Journey Through Anxiety'), findsWidgets);
    expect(find.text('Journey of Karma Yoga'), findsWidgets);
    expect(find.text('Journey to Inner Clarity'), findsWidgets);

    final completedIds = await tester.runAsync(
      LocalStorageService.completedJourneyIds,
    );
    expect(completedIds, contains('journey_peace_7'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpJourneys(tester);
    await pumpUntilFound(tester, find.text('Completed Journeys'));

    expect(find.text('Completed Journeys'), findsOneWidget);
    expect(find.text('Journey Complete'), findsOneWidget);
    expect(find.text('Journey to Peace'), findsWidgets);
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

    await tester.ensureVisible(find.text('Complete Day').first);
    await tester.pump();
    await tester.tap(find.text('Complete Day').first);
    await tester.pumpAndSettle();

    expect(find.text('Day Complete ✓'), findsOneWidget);
    expect(find.text('Next: Day 2 — Feelings pass'), findsOneWidget);
    expect(find.text('Continue Journey'), findsOneWidget);
    expect(find.text('Back to Journey'), findsOneWidget);
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

  testWidgets('completed journey opens next journey selection from Home', (
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
    await pumpUntilFound(tester, find.text('You completed Journey to Peace.'));

    await tester.ensureVisible(find.text('Start Next Journey'));
    await tester.pump();
    await tester.tap(find.text('Start Next Journey'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Next Journey'), findsOneWidget);
    expect(find.text('Journey of Discipline'), findsWidgets);
    expect(find.text('Journey of Karma Yoga'), findsWidgets);
    expect(find.text('Journey Through Anxiety'), findsWidgets);
    expect(find.text('Journey to Inner Clarity'), findsWidgets);

    await tester.tap(find.byKey(
      const ValueKey('home_next_journey_journey_discipline_14'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Journey started'), findsOneWidget);
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
