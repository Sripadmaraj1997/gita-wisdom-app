import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/services/content_quality_framework.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bannedPhrases = [
    'this verse teaches',
    'in modern life',
    'the gita reminds us',
    'the gita offers',
    'the gita points',
    'the gita teaches',
    'this wisdom shows',
    'follow karma yoga',
    'practice detachment',
    'ai translation',
    'lorem ipsum',
    'placeholder',
  ];

  test('top 100 important verses have reviewed human reflection content',
      () async {
    final bundle = await GitaRepository.load();
    final seen = <String>{};

    expect(ContentQualityFramework.topImportantVerseIds, hasLength(100));
    expect(ContentQualityFramework.reviewedReflections(), hasLength(100));

    for (final verseId in ContentQualityFramework.topImportantVerseIds) {
      expect(seen.add(verseId), isTrue, reason: 'Duplicate $verseId');
      final verse = bundle.verseById(verseId);
      expect(verse, isNotNull, reason: verseId);
      expect(verse!.reflectionText.trim(), isNotEmpty, reason: verseId);
      expect(verse.practiceToday.trim(), isNotEmpty, reason: verseId);
      expect(verse.reflectionTags, isNotEmpty, reason: verseId);

      final sentenceCount =
          RegExp(r'[.!?]').allMatches(verse.reflectionText).length;
      expect(sentenceCount, inInclusiveRange(2, 4), reason: verseId);
      expect(
        verse.practiceToday.trim().split(RegExp(r'\s+')),
        hasLength(lessThan(20)),
        reason: verseId,
      );

      final visible = [
        verse.reflectionText,
        verse.practiceToday,
        verse.reflectionTags.join(' '),
      ].join('\n').toLowerCase();
      for (final phrase in bannedPhrases) {
        expect(visible, isNot(contains(phrase)), reason: verseId);
      }
    }
  });

  test('framework exposes reusable content models and emotional intents', () {
    final content = ContentQualityFramework.contentForVerse('2.47');

    expect(content, isNotNull);
    expect(content!.reflection, isA<Reflection>());
    expect(content.practiceToday, isA<PracticeToday>());
    expect(content.topicTags, isA<TopicTags>());
    expect(content.reflection.intent, EmotionalIntent.attachment);
    expect(content.practiceToday.category, EmotionalIntent.attachment);
    expect(content.gitaWisdomInterpretation, isNotEmpty);
  });

  test('curated priority verses have reviewed interpretation and topic tags',
      () async {
    final bundle = await GitaRepository.load();
    const requiredPriorityVerses = [
      '2.14',
      '2.47',
      '2.50',
      '2.56',
      '2.70',
      '3.19',
      '3.30',
      '4.7',
      '4.8',
      '4.38',
      '5.10',
      '6.5',
      '6.6',
      '6.26',
      '9.22',
      '9.26',
      '12.13',
      '12.14',
      '12.15',
      '18.66',
    ];
    const expectedTopics = [
      'peace',
      'fear',
      'anger',
      'discipline',
      'attachment',
      'purpose',
      'devotion',
      'clarity',
    ];

    for (final verseId in requiredPriorityVerses) {
      expect(
        ContentQualityFramework.topImportantVerseIds,
        contains(verseId),
        reason: verseId,
      );
      final content = ContentQualityFramework.contentForVerse(verseId);
      final verse = bundle.verseById(verseId);
      expect(content, isNotNull, reason: verseId);
      expect(verse, isNotNull, reason: verseId);
      expect(content!.gitaWisdomInterpretation.trim(), isNotEmpty,
          reason: verseId);
      expect(verse!.gitaWisdomInterpretation, content.gitaWisdomInterpretation);

      final searchableTags = content.topicTags.values.join(' ').toLowerCase();
      expect(
        expectedTopics.any(searchableTags.contains),
        isTrue,
        reason: verseId,
      );
    }
  });
}
