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
}
