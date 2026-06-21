import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/services/ask_gita_lite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const prompts = [
    'I am anxious.',
    'I am anxious about my future.',
    'I am worried about my future.',
    'I feel angry.',
    'I feel lost.',
    'I lost motivation.',
    'I am attached to results.',
    'I fear failure.',
    'I cannot focus.',
    'I feel overwhelmed.',
    'I feel overwhelmed at work.',
    'How do I find peace?',
    'I am afraid of failure.',
    'I feel confused about my purpose.',
    'How do I control my mind?',
    'How do I stop worrying?',
    'I am grieving a loss.',
    'I feel uncertain about what to do.',
    'I need discipline and consistency.',
    'What is my purpose?',
    'I am struggling in a relationship.',
    'How do I grow in devotion?',
    'Why am I suffering?',
  ];

  const benchmarkPrompts = [
    'How do I stop worrying?',
    'I am anxious about my future.',
    'I feel angry.',
    'I lost motivation.',
    'I feel overwhelmed.',
    'I fear failure.',
    'How do I control my mind?',
    'How do I find peace?',
    'How do I handle uncertainty?',
    'Why am I suffering?',
  ];

  const bannedPhrases = [
    'this verse teaches',
    'in modern life',
    'the gita reminds us',
    'the gita offers',
    'this wisdom shows',
    'ai translation',
    'lorem ipsum',
    'placeholder',
  ];

  test('sample prompts produce tailored six-part answers', () async {
    final answers = <String, String>{};

    for (final prompt in prompts) {
      final answer = await AskGitaLiteService.answer(prompt);
      final combined = [
        answer.gentleGuidance,
        answer.verse.reference,
        answer.verse.englishTranslation,
        answer.meaning,
        answer.reflection,
        answer.practiceToday,
        answer.source,
      ].join('\n');

      expect(answer.gentleGuidance, isNotEmpty, reason: prompt);
      expect(answer.verse.hasEnrichment, isTrue, reason: prompt);
      expect(answer.verse.reference, startsWith('Bhagavad Gita '));
      expect(answer.verse.englishTranslation, isNotEmpty, reason: prompt);
      expect(answer.meaning, isNotEmpty, reason: prompt);
      expect(answer.reflection, isNotEmpty, reason: prompt);
      expect(
          answer.practiceToday.split(RegExp(r'\s+')), hasLength(lessThan(20)));
      expect(answer.source, answer.verse.reference);
      expect(answer.meaning, isNot(answer.gentleGuidance), reason: prompt);
      expect(answer.reflection, isNot(answer.meaning), reason: prompt);

      final sentenceCount =
          RegExp(r'[.!?]').allMatches(answer.gentleGuidance).length;
      expect(sentenceCount, inInclusiveRange(2, 4), reason: prompt);

      final visible = combined.toLowerCase();
      for (final phrase in bannedPhrases) {
        expect(visible, isNot(contains(phrase)), reason: prompt);
      }

      answers[prompt] = answer.gentleGuidance;
    }

    expect(answers.values.toSet(), hasLength(prompts.length));
  });

  test('benchmark intents map to grounded topic profiles', () async {
    final benchmarkTopics = {
      'I am anxious about my future.': 'anxiety',
      'I feel angry.': 'anger',
      'I am afraid of failure.': 'fear',
      'I am grieving a loss.': 'grief',
      'I feel uncertain about what to do.': 'uncertainty',
      'I feel lost.': 'uncertainty',
      'I feel overwhelmed at work.': 'work pressure',
      'I feel overwhelmed.': 'anxiety',
      'I feel confused about my purpose.': 'purpose',
      'I am attached to results.': 'attachment',
      'I need discipline and consistency.': 'discipline',
      'I cannot focus.': 'discipline',
      'How do I control my mind?': 'self-mastery',
      'How do I find peace?': 'peace',
      'How do I handle uncertainty?': 'uncertainty',
      'Why am I suffering?': 'suffering',
      'How do I grow in devotion?': 'devotion',
      'I am anxious.': 'anxiety',
    };

    for (final entry in benchmarkTopics.entries) {
      final answer = await AskGitaLiteService.answer(entry.key);
      expect(answer.topic, entry.value, reason: entry.key);
    }
  });

  test('benchmark prompts feel directly addressed', () async {
    final expectedOpenings = {
      'I am anxious.': 'Anxiety can make even this moment feel crowded.',
      'I feel angry.':
          'Anger can feel powerful, but power is not the same as truth.',
      'I am afraid of failure.':
          'Fear of failure is heavy because it ties your worth to one result.',
      'I am grieving a loss.':
          'Grief needs room to breathe before it can become bearable.',
      'I feel overwhelmed at work.':
          'When work feels too large, return to the one responsibility directly in front of you.',
      'I am attached to results.':
          'Wanting a good result is natural; suffering begins when the result owns your peace.',
      'I need discipline and consistency.':
          'Consistency grows from small promises kept without harshness.',
      'How do I stop worrying?':
          'You do not need to solve your entire future today.',
      'I lost motivation.':
          'When motivation is low, treat the first small action as the practice.',
      'How do I control my mind?':
          'A restless mind does not mean you are failing; it means practice has begun.',
      'How do I handle uncertainty?':
          'Uncertainty can be met without forcing an answer too soon.',
      'Why am I suffering?':
          'Suffering deserves tenderness before it is asked to become wisdom.',
      'How do I grow in devotion?':
          'Devotion can be practiced quietly before it is felt deeply.',
    };

    for (final entry in expectedOpenings.entries) {
      final answer = await AskGitaLiteService.answer(entry.key);
      expect(answer.gentleGuidance, startsWith(entry.value), reason: entry.key);
    }
  });

  test('excellence benchmark answers are structured and non-repetitive',
      () async {
    final openings = <String>{};

    for (final prompt in benchmarkPrompts) {
      final answer = await AskGitaLiteService.answer(prompt);
      final sections = [
        answer.gentleGuidance,
        answer.verse.englishTranslation,
        answer.meaning,
        answer.reflection,
        answer.practiceToday,
        answer.source,
      ];

      for (final section in sections) {
        expect(section.trim(), isNotEmpty, reason: prompt);
      }

      expect(answer.verse.hasEnrichment, isTrue, reason: prompt);
      expect(answer.reflection.toLowerCase(), contains('after reading this'),
          reason: prompt);
      expect(answer.practiceToday.endsWith('.'), isTrue, reason: prompt);

      final firstWords = answer.gentleGuidance
          .split(RegExp(r'\s+'))
          .take(5)
          .join(' ')
          .toLowerCase();
      openings.add(firstWords);
    }

    expect(openings, hasLength(benchmarkPrompts.length));
  });
}
