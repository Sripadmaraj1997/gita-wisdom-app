import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/services/ask_gita_lite_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prompts = [
    'I am anxious.',
    'I am anxious about my future.',
    'I am worried about my future.',
    'I feel angry.',
    'I lost motivation.',
    'I am attached to results.',
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
      expect(answer.verse.reference, startsWith('Bhagavad Gita '));
      expect(answer.verse.englishTranslation, isNotEmpty, reason: prompt);
      expect(answer.meaning, isNotEmpty, reason: prompt);
      expect(answer.reflection, isNotEmpty, reason: prompt);
      expect(
          answer.practiceToday.split(RegExp(r'\s+')), hasLength(lessThan(20)));
      expect(answer.source, answer.verse.reference);

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
      'I feel overwhelmed at work.': 'work pressure',
      'I feel confused about my purpose.': 'purpose',
      'I am attached to results.': 'attachment',
      'I need discipline and consistency.': 'discipline',
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
      'How do I grow in devotion?':
          'Devotion can be practiced quietly before it is felt deeply.',
    };

    for (final entry in expectedOpenings.entries) {
      final answer = await AskGitaLiteService.answer(entry.key);
      expect(answer.gentleGuidance, startsWith(entry.value), reason: entry.key);
    }
  });
}
