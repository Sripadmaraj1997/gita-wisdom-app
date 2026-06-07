import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/services/journey_service.dart';
import 'package:gita_wisdom/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reflection activity is counted locally once per day', () async {
    expect(await LocalStorageService.reflectionStreak(), 0);

    await LocalStorageService.recordVerseReadForReflection();
    expect(await LocalStorageService.reflectionStreak(), 1);

    await LocalStorageService.recordDailyGuidanceOpened();
    await LocalStorageService.recordPracticeCompleted();
    await LocalStorageService.upsertJournalEntry(
      LocalJournalEntry.create(
        title: 'Evening reflection',
        text: 'A quiet note from today.',
        mood: 'Peaceful',
      ),
    );

    expect(await LocalStorageService.reflectionStreak(), 1);
  });

  test('journey progress is stored locally by journey and day', () async {
    await LocalStorageService.setJourneyDayComplete(
      journeyId: 'journey_peace_7',
      day: 1,
      complete: true,
    );
    await LocalStorageService.setJourneyDayComplete(
      journeyId: 'journey_peace_7',
      day: 2,
      complete: true,
    );

    final progress = await LocalStorageService.journeyProgress();
    expect(progress['journey_peace_7'], {1, 2});

    await LocalStorageService.setJourneyDayComplete(
      journeyId: 'journey_peace_7',
      day: 1,
      complete: false,
    );

    expect(await LocalStorageService.completedJourneyDays('journey_peace_7'), {
      2,
    });
  });

  test('current journey resumes the first active journey gently', () async {
    expect(JourneyService.journeys.map((journey) => journey.title), [
      'Journey to Peace',
      'Journey of Discipline',
      'Journey of Karma Yoga',
      'Journey Through Anxiety',
      'Journey to Inner Clarity',
    ]);

    await LocalStorageService.setJourneyDayComplete(
      journeyId: 'journey_discipline_14',
      day: 1,
      complete: true,
    );

    final current = await JourneyService.currentJourney();
    expect(current.journey.title, 'Journey of Discipline');
    expect(current.nextDay, 2);
    expect(current.completedCount, 1);
  });
}
