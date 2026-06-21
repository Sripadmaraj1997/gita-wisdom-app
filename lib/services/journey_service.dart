/// ------------------------------------------------------------
/// JourneyService
///
/// Purpose:
/// Shared Journey metadata and current-progress selection.
///
/// Responsibilities:
/// - Expose lightweight Journey summaries for Home.
/// - Derive the active Journey and next incomplete day from local progress.
/// - Identify completed Journeys without importing screen-private day models.
///
/// State model:
/// - currentJourneyId chooses the active guided path.
/// - currentJourneyDay stores the day the user should resume.
/// - completedDays comes from LocalStorageService.journeyProgress().
/// - completedJourneys remains separate so completion is visible after the next
///   Journey starts.
///
/// Notes:
/// TransformationPageWidget owns day-level UI because Continue Journey, Start
/// Next Journey, and Journey Complete require the full daily content.
/// ------------------------------------------------------------
library;

import 'package:flutter/foundation.dart';

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
  bool get isComplete => completedCount >= journey.totalDays;
  String get progressLabel =>
      '$completedCount of ${journey.totalDays} days complete';
}

class JourneyService {
  const JourneyService._();

  static const journeys = [
    GitaJourneySummary(
      id: 'journey_peace_7',
      title: 'Journey to Peace',
      subtitle: 'Find calm and steadiness.',
      totalDays: 7,
    ),
    GitaJourneySummary(
      id: 'journey_discipline_14',
      title: 'Journey of Discipline',
      subtitle: 'Build focus and consistency.',
      totalDays: 14,
    ),
    GitaJourneySummary(
      id: 'journey_karma_yoga_14',
      title: 'Journey of Karma Yoga',
      subtitle: 'Act without attachment to results.',
      totalDays: 14,
    ),
    GitaJourneySummary(
      id: 'journey_anxiety_7',
      title: 'Journey Through Anxiety',
      subtitle: 'Move from worry to steadiness.',
      totalDays: 7,
    ),
    GitaJourneySummary(
      id: 'journey_clarity_21',
      title: 'Journey to Inner Clarity',
      subtitle: 'Develop deeper self-understanding.',
      totalDays: 21,
    ),
  ];

  static const recommendedAfterCompletionIds = [
    'journey_discipline_14',
    'journey_karma_yoga_14',
    'journey_anxiety_7',
    'journey_clarity_21',
  ];

  static Future<GitaCurrentJourney> currentJourney() async {
    // Home calls this during build. Keep it fast and side-effect free: read the
    // selected journey and progress, then derive the next incomplete day.
    final progress = await LocalStorageService.journeyProgress();
    final selectedJourneyId = await LocalStorageService.currentJourneyId();
    return currentJourneyFromProgress(
      progress,
      selectedJourneyId: selectedJourneyId,
    );
  }

  static List<GitaJourneySummary> recommendedAfterCompletion() {
    return [
      for (final id in recommendedAfterCompletionIds)
        journeys.firstWhere((journey) => journey.id == id),
    ];
  }

  static List<GitaJourneySummary> completedJourneysFromProgress(
    Map<String, Set<int>> progress,
  ) {
    return [
      for (final journey in journeys)
        if ((progress[journey.id] ?? <int>{}).length >= journey.totalDays)
          journey,
    ];
  }

  static GitaCurrentJourney currentJourneyFromProgress(
    Map<String, Set<int>> progress, {
    String? selectedJourneyId,
  }) {
    if (selectedJourneyId != null) {
      final selected = _journeyById(selectedJourneyId);
      if (selected != null) {
        final completed = progress[selected.id] ?? <int>{};
        return GitaCurrentJourney(
          journey: selected,
          completedDays: completed,
          nextDay: _nextDay(selected, completed),
        );
      }
    }

    for (final journey in journeys) {
      final completed = progress[journey.id] ?? <int>{};
      if (kDebugMode && completed.length >= journey.totalDays) {
        debugPrint('Journey completion detected: ${journey.id}');
      }
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

  static GitaJourneySummary? _journeyById(String id) {
    for (final journey in journeys) {
      if (journey.id == id) {
        return journey;
      }
    }
    return null;
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
