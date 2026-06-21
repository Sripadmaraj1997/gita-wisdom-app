import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/services/content_quality_framework.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const priorityVerseIds = [
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
  final archaicLanguagePattern = RegExp(
    r'\b(thy|thee|thou|hath|dost|shalt|ye|whence|wherefore|thereof|thine)\b',
    caseSensitive: false,
  );

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

  test('verse enrichment progress covers top 100 without duplicates', () async {
    final bundle = await GitaRepository.load();

    expect(ContentQualityFramework.topImportantVerseIds, hasLength(100));
    expect(ContentQualityFramework.enrichedVerseCount, 100);
    expect(ContentQualityFramework.duplicateVerseEnrichmentIds(), isEmpty);

    final missingOrIncomplete = <String>[];
    for (final verseId in ContentQualityFramework.topImportantVerseIds) {
      final enrichment = bundle.verseById(verseId)?.enrichment;
      if (enrichment == null || !enrichment.isComplete) {
        missingOrIncomplete.add(verseId);
        continue;
      }
      expect(enrichment.toJson(),
          containsPair('chapterNumber', int.parse(verseId.split('.').first)));
      expect(enrichment.toJson(),
          containsPair('verseNumber', int.parse(verseId.split('.').last)));
    }
    expect(missingOrIncomplete, isEmpty);
    expect(bundle.enrichedVerseCount, 100);
  });

  test('curated priority verses have reviewed interpretation and topic tags',
      () async {
    final bundle = await GitaRepository.load();
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

    expect(
      ContentQualityFramework.verseExcellencePriorityVerseIds,
      priorityVerseIds,
    );

    for (final verseId in priorityVerseIds) {
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

  test('Verse Excellence Program keeps five content layers strong', () async {
    final bundle = await GitaRepository.load();
    const actionVerbs = [
      'ask',
      'begin',
      'choose',
      'complete',
      'do',
      'focus',
      'guide',
      'let',
      'name',
      'notice',
      'offer',
      'pause',
      'place',
      'return',
      'speak',
      'surrender',
      'when',
    ];

    for (final verseId
        in ContentQualityFramework.verseExcellencePriorityVerseIds) {
      final verse = bundle.verseById(verseId);
      final content = ContentQualityFramework.contentForVerse(verseId);

      expect(verse, isNotNull, reason: verseId);
      expect(content, isNotNull, reason: verseId);

      final translation = verse!.englishTranslation.trim();
      final interpretation = content!.gitaWisdomInterpretation.trim();
      final reflection = content.reflection.text.trim();
      final practice = content.practiceToday.text.trim();
      final tags = content.topicTags.values;

      // Translation stays scripture-only. The app must not mix the practical
      // interpretation layer into the trusted local scripture translation.
      expect(translation, isNotEmpty, reason: verseId);
      expect(translation.toLowerCase(), isNot(contains('gita wisdom')),
          reason: verseId);
      expect(translation, isNot(interpretation), reason: verseId);
      expect(translation, isNot(reflection), reason: verseId);

      final interpretationSentenceCount =
          RegExp(r'[.!?]').allMatches(interpretation).length;
      expect(interpretationSentenceCount, inInclusiveRange(2, 4),
          reason: verseId);
      expect(interpretation.length, greaterThan(80), reason: verseId);

      final reflectionSentenceCount =
          RegExp(r'[.!?]').allMatches(reflection).length;
      expect(reflectionSentenceCount, inInclusiveRange(2, 4), reason: verseId);

      final combinedReviewedText = [
        interpretation,
        reflection,
        practice,
      ].join('\n').toLowerCase();
      for (final phrase in bannedPhrases) {
        expect(combinedReviewedText, isNot(contains(phrase)), reason: verseId);
      }
      expect(
        archaicLanguagePattern.hasMatch(combinedReviewedText),
        isFalse,
        reason: verseId,
      );

      expect(practice.split(RegExp(r'\s+')), hasLength(lessThan(20)),
          reason: verseId);
      expect(
        actionVerbs.any((verb) => practice.toLowerCase().startsWith(verb)),
        isTrue,
        reason: verseId,
      );

      expect(tags.length, greaterThanOrEqualTo(5), reason: verseId);
      expect(tags.toSet(), hasLength(tags.length), reason: verseId);
      expect(
        tags.any(ContentQualityFramework.emotionalSearchTags.contains),
        isTrue,
        reason: verseId,
      );
    }
  });

  test('app-authored wisdom layers use modern approachable English', () async {
    final bundle = await GitaRepository.load();

    for (final verse in bundle.verses) {
      final appAuthoredText = [
        verse.gitaWisdomInterpretation,
        verse.reflectionText,
        verse.practiceToday,
      ].join('\n');

      expect(
        archaicLanguagePattern.hasMatch(appAuthoredText),
        isFalse,
        reason: verse.id,
      );
    }
  });
}
