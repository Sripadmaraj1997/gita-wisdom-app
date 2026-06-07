// Legacy personalized plan generator.
//
// Builds a simple local practice plan from PersonalizationService preferences.
// The current Bible-app-level habit feature is Journeys, but these models can
// still inform future richer journeys or onboarding personalization.
//
// TODO(richer-journeys): Fold useful personalized-plan ideas into the Journey
// content model after editorial review.
import 'personalization_service.dart';

class PersonalizedPlan {
  const PersonalizedPlan({
    required this.title,
    required this.subtitle,
    required this.dailyPractice,
    required this.weeklySteps,
    required this.reflectionPrompt,
  });

  final String title;
  final String subtitle;
  final String dailyPractice;
  final List<String> weeklySteps;
  final String reflectionPrompt;
}

class PersonalizedPlanService {
  const PersonalizedPlanService._();

  static Future<PersonalizedPlan> currentPlan() async {
    final profile = await PersonalizationService.loadProfile();
    return switch (profile.seeking.toLowerCase()) {
      'purpose' => const PersonalizedPlan(
          title: 'Purpose Plan',
          subtitle: 'A 7-day dharma and action practice',
          dailyPractice:
              'Begin each day by naming one duty you can perform with sincerity.',
          weeklySteps: [
            'Name one responsibility you are avoiding.',
            'Choose one small action without waiting for certainty.',
            'Reflect on whether your motive is service or approval.',
          ],
          reflectionPrompt: 'What action feels aligned with dharma today?',
        ),
      'discipline' => const PersonalizedPlan(
          title: 'Discipline Plan',
          subtitle: 'A 7-day mind and habit practice',
          dailyPractice:
              'Choose one repeatable practice and complete it before distraction.',
          weeklySteps: [
            'Set one non-negotiable 10-minute practice.',
            'Remove one avoidable distraction.',
            'Review the moment your mind resisted practice.',
          ],
          reflectionPrompt: 'Where can I train the mind gently today?',
        ),
      'devotion' => const PersonalizedPlan(
          title: 'Devotion Plan',
          subtitle: 'A 7-day bhakti and surrender practice',
          dailyPractice:
              'Offer one ordinary action as devotion before beginning it.',
          weeklySteps: [
            'Start the day with one remembered virtue.',
            'Offer one act of service quietly.',
            'End the day with gratitude instead of self-judgment.',
          ],
          reflectionPrompt: 'What can I offer with love today?',
        ),
      'clarity' => const PersonalizedPlan(
          title: 'Clarity Plan',
          subtitle: 'A 7-day wisdom and discernment practice',
          dailyPractice:
              'Pause before one decision and separate fact, fear, and duty.',
          weeklySteps: [
            'Write the decision plainly.',
            'Identify what is in your control.',
            'Choose the next right action without overthinking.',
          ],
          reflectionPrompt: 'What is clear when I release fear?',
        ),
      _ => const PersonalizedPlan(
          title: 'Peace Plan',
          subtitle: 'A 7-day steadiness and calm practice',
          dailyPractice:
              'Take three slow breaths before one important action today.',
          weeklySteps: [
            'Notice where anxiety appears in the body.',
            'Return to one verse or phrase when the mind races.',
            'Complete one duty without bargaining with the result.',
          ],
          reflectionPrompt: 'What can I release from my control today?',
        ),
    };
  }
}
