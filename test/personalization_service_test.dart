import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/services/daily_companion_service.dart';
import 'package:gita_wisdom/services/personalization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local emotional searches build a private interest profile', () async {
    await PersonalizationService.recordEmotionalSearch('fear and uncertainty');
    await PersonalizationService.recordEmotionalSearch('I am worried');

    final profile = await PersonalizationService.interestProfile();

    expect(profile.hasSignals, isTrue);
    expect(profile.topThemes.first, 'fear');
  });

  test('Today guidance prefers calming content for fear signals', () async {
    await PersonalizationService.recordEmotionalSearch('anxiety about future');

    final guidance = await PersonalizationService.personalizedTodaysGuidance(
      DateTime(2026, 1, 1),
    );

    expect(guidance.topic, 'peace');
    expect(
        guidance.reference, DailyCompanionService.guidanceItems[1].reference);
  });

  test('recommendations stay quiet until local signals exist', () async {
    expect(await PersonalizationService.recommendations(), isEmpty);

    final verse = await GitaRepository.verseById('2.47');
    await PersonalizationService.recordVerseSaved(verse!);

    final recommendations = await PersonalizationService.recommendations();

    expect(recommendations, isNotEmpty);
    expect(recommendations.first.opensVerse, isTrue);
    expect(recommendations.first.reason, isNot(contains('tracked')));
  });

  test('topic profile uses the v1 spiritual themes only', () async {
    await PersonalizationService.recordEmotionalSearch(
      'karma work duty and service',
    );
    await PersonalizationService.recordAskGitaQuestion(
      'I feel angry and attached to the outcome',
    );

    final profile = await PersonalizationService.interestProfile();

    expect(
      profile.themeCounts.keys,
      everyElement(
        isIn(const [
          'peace',
          'fear',
          'anger',
          'discipline',
          'purpose',
          'devotion',
          'clarity',
          'attachment',
          'compassion',
        ]),
      ),
    );
    expect(profile.themeCounts.keys, isNot(contains('service')));
    expect(profile.topThemes, contains('purpose'));
    expect(profile.topThemes, contains('anger'));
    expect(profile.topThemes, contains('attachment'));
  });

  test('recommended verses prefer enriched local wisdom without scores',
      () async {
    await GitaRepository.load();
    await PersonalizationService.recordEmotionalSearch(
      'fear uncertainty worry',
    );

    final verses = await PersonalizationService.recommendedVerses(limit: 3);
    final recommendations =
        await PersonalizationService.recommendations(limit: 2);

    expect(verses, isNotEmpty);
    expect(verses.first.hasEnrichment, isTrue);
    expect(recommendations, isNotEmpty);
    expect(recommendations.first.reason, isNot(contains('score')));
    expect(recommendations.first.reason, isNot(contains('analytics')));
  });

  test('suggested journeys follow local topics before fallback order',
      () async {
    await PersonalizationService.recordEmotionalSearch(
      'fear uncertainty worry',
    );

    final suggested = await PersonalizationService.suggestedJourneyIds(
      excludeJourneyIds: const ['journey_peace_7'],
    );

    expect(suggested.first, 'journey_anxiety_7');
    expect(suggested, isNot(contains('journey_peace_7')));
    expect(suggested, contains('journey_discipline_14'));
  });
}
