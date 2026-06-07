// Legacy transformation snapshot service.
//
// Combines old personalization and habit services into progress milestones.
// The visible transformation surface is now the local Journeys screen, but this
// service is retained for compatibility and possible future onboarding work.
import 'habit_service.dart';
import 'personalized_plan_service.dart';
import 'personalization_service.dart';

class TransformationSnapshot {
  const TransformationSnapshot({
    required this.profile,
    required this.plan,
    required this.habitStatus,
    required this.stageTitle,
    required this.stageSubtitle,
    required this.progress,
    required this.milestones,
  });

  final PersonalizationProfile profile;
  final PersonalizedPlan plan;
  final HabitStatus habitStatus;
  final String stageTitle;
  final String stageSubtitle;
  final double progress;
  final List<TransformationMilestone> milestones;
}

class TransformationMilestone {
  const TransformationMilestone({
    required this.title,
    required this.body,
    required this.completed,
  });

  final String title;
  final String body;
  final bool completed;
}

class TransformationService {
  const TransformationService._();

  static Future<TransformationSnapshot> loadSnapshot() async {
    final profile = await PersonalizationService.loadProfile();
    final plan = await PersonalizedPlanService.currentPlan();
    final habit = await HabitService.loadStatus();
    final streak = habit.streakDays;

    final stage = _stageFor(streak);
    return TransformationSnapshot(
      profile: profile,
      plan: plan,
      habitStatus: habit,
      stageTitle: stage.$1,
      stageSubtitle: stage.$2,
      progress: (streak / 21).clamp(0, 1),
      milestones: [
        TransformationMilestone(
          title: 'Begin',
          body: 'Complete one sincere daily practice.',
          completed: streak >= 1,
        ),
        TransformationMilestone(
          title: 'Return',
          body: 'Come back for three days and build trust with repetition.',
          completed: streak >= 3,
        ),
        TransformationMilestone(
          title: 'Stabilize',
          body: 'Reach seven days of reading, reflection, or guided practice.',
          completed: streak >= 7,
        ),
        TransformationMilestone(
          title: 'Embody',
          body: 'Carry one Gita teaching through ordinary action for 21 days.',
          completed: streak >= 21,
        ),
      ],
    );
  }

  static (String, String) _stageFor(int streak) {
    if (streak >= 21) {
      return (
        'Embodying wisdom',
        'Your practice is becoming part of how you move through daily life.'
      );
    }
    if (streak >= 7) {
      return (
        'Deepening practice',
        'You are turning inspiration into steady inner training.'
      );
    }
    if (streak >= 3) {
      return (
        'Building rhythm',
        'The path is becoming easier to return to each day.'
      );
    }
    return (
      'Beginning the path',
      'Transformation starts with one sincere return to practice.'
    );
  }
}
