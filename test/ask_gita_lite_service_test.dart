import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/services/ask_gita_lite_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const prompts = [
    'I am worried about my future.',
    'I feel angry.',
    'I lost motivation.',
    'I am attached to results.',
    'I feel overwhelmed at work.',
    'How do I find peace?',
    'I am afraid of failure.',
  ];

  const bannedPhrases = [
    'This verse teaches us',
    'In modern life',
    'The Gita reminds us',
    'This wisdom shows',
    'AI Translation',
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

      for (final phrase in bannedPhrases) {
        expect(combined, isNot(contains(phrase)), reason: prompt);
      }

      answers[prompt] = answer.gentleGuidance;
    }

    expect(answers.values.toSet(), hasLength(prompts.length));
  });
}
