// Shared Journey summary and current-progress selection.
//
// The detailed daily Journey content lives in the Journeys screen, while this
// service exposes lightweight metadata for Home. Keeping the summary here lets
// Home show "Current Journey" without importing screen-private widget models.
import 'local_storage_service.dart';

class GitaJourneySummary {
  const GitaJourneySummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.totalDays,
  });

  final String id;
  final String title;
  final String subtitle;
  final int totalDays;
}

class GitaCurrentJourney {
  const GitaCurrentJourney({
    required this.journey,
    required this.completedDays,
    required this.nextDay,
  });

  final GitaJourneySummary journey;
  final Set<int> completedDays;
  final int nextDay;

  int get completedCount => completedDays.length;
}

class JourneyService {
  const JourneyService._();

  static const journeys = [
    GitaJourneySummary(
      id: 'journey_peace_7',
      title: 'Journey to Peace',
      subtitle: '7 days for steadiness, release, and gentle trust.',
      totalDays: 7,
    ),
    GitaJourneySummary(
      id: 'journey_discipline_14',
      title: 'Journey of Discipline',
      subtitle: '14 days of small, steady action.',
      totalDays: 14,
    ),
    GitaJourneySummary(
      id: 'journey_karma_yoga_14',
      title: 'Journey of Karma Yoga',
      subtitle: '14 days on action, offering, and freedom from results.',
      totalDays: 14,
    ),
    GitaJourneySummary(
      id: 'journey_anxiety_7',
      title: 'Journey Through Anxiety',
      subtitle: '7 days for courage, grounding, and trust.',
      totalDays: 7,
    ),
    GitaJourneySummary(
      id: 'journey_clarity_21',
      title: 'Journey to Inner Clarity',
      subtitle: '21 days of discernment, quiet attention, and steady seeing.',
      totalDays: 21,
    ),
  ];

  static Future<GitaCurrentJourney> currentJourney() async {
    final progress = await LocalStorageService.journeyProgress();
    return currentJourneyFromProgress(progress);
  }

  static GitaCurrentJourney currentJourneyFromProgress(
    Map<String, Set<int>> progress,
  ) {
    for (final journey in journeys) {
      final completed = progress[journey.id] ?? <int>{};
      if (completed.isNotEmpty && completed.length < journey.totalDays) {
        return GitaCurrentJourney(
          journey: journey,
          completedDays: completed,
          nextDay: _nextDay(journey, completed),
        );
      }
    }

    final first = journeys.first;
    final completed = progress[first.id] ?? <int>{};
    return GitaCurrentJourney(
      journey: first,
      completedDays: completed,
      nextDay: _nextDay(first, completed),
    );
  }

  static int _nextDay(GitaJourneySummary journey, Set<int> completedDays) {
    for (var day = 1; day <= journey.totalDays; day++) {
      if (!completedDays.contains(day)) {
        return day;
      }
    }
    return journey.totalDays;
  }
}
