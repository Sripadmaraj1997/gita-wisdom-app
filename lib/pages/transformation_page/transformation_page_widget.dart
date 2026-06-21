/// ------------------------------------------------------------
/// JourneyScreen
///
/// Purpose:
/// Guided local spiritual paths with daily verse, reflection, practice, and
/// journal prompts.
///
/// Responsibilities:
/// - Show all available Journeys and the active current day.
/// - Keep completed days, current day, and future days understandable.
/// - Persist day completion immediately.
/// - Handle Continue Journey, Continue Your Journey, Day Reflected On, and Journey
///   Complete flows.
/// - Keep Journey day reading and completion on one guided screen.
///
/// State model:
/// - currentJourneyId: active guided path.
/// - currentJourneyDay: day Home/Journeys should resume.
/// - completedDays: completed day numbers for each journey.
/// - completedJourneys: completed journey IDs retained after the next path starts.
///
/// User flow:
/// Read -> Reflect -> Practice -> Return. A Journey day is self-contained so
/// the user does not have to browse chapters or choose the next navigation step
/// while trying to practice.
///
/// Completion logic:
/// Completing a non-final day advances the active day. Completing the final day
/// persists the journey in completedJourneys, keeps its completedDays, and
/// replaces generic Continue with Choose Next Journey or Restart a Journey when
/// every path has been completed.
///
/// Notes:
/// Users should never feel lost. Journey flow should always show where they are,
/// what comes next, and how to return.
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart' as gita_data;
import '../../services/local_storage_service.dart';
import '../../services/personalization_service.dart';
import '../gita_common/gita_common.dart';

void _journeyDebugLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

class TransformationPageWidget extends StatefulWidget {
  const TransformationPageWidget({
    super.key,
    this.initialJourneyId,
    this.completedJourneyId,
    this.completedJourneyDay,
  });

  static String routeName = 'TransformationPage';
  static String routePath = '/transformationPage';

  final String? initialJourneyId;
  final String? completedJourneyId;
  final int? completedJourneyDay;

  @override
  State<TransformationPageWidget> createState() =>
      _TransformationPageWidgetState();
}

class _TransformationPageWidgetState extends State<TransformationPageWidget> {
  late Future<_JourneyProgressState> _progressFuture;
  final ScrollController _scrollController = ScrollController();
  _JourneyCompletionNotice? _completionNotice;

  static const _journeys = [
    _Journey(
      id: 'journey_peace_7',
      title: 'Journey to Peace',
      subtitle: 'Find calm and steadiness.',
      icon: Icons.local_florist_rounded,
      days: [
        _JourneyDay(
            1,
            '2.47',
            'Act without clinging',
            'Let effort be sincere, then loosen the grip on the result.',
            'Complete one action with full attention.',
            'Where can I release control today?'),
        _JourneyDay(
            2,
            '2.14',
            'Feelings pass',
            'Pleasure and pain move through life. Peace grows when you do not become every wave.',
            'Pause and name one passing feeling.',
            'What disturbed my peace, and what helped it return?'),
        _JourneyDay(
            3,
            '2.48',
            'Practice evenness',
            'Evenness is not indifference. It is steady presence while life changes.',
            'Meet one outcome calmly today.',
            'Where can I practice balance?'),
        _JourneyDay(
            4,
            '6.5',
            'Lift the mind gently',
            'The mind becomes a friend when guided with patience rather than force.',
            'Speak to yourself with kindness once.',
            'What thought needs gentler guidance?'),
        _JourneyDay(
            5,
            '9.22',
            'Rest in trust',
            'Devotion softens the need to carry everything alone.',
            'Offer one worry in prayer.',
            'What burden can I place before the Divine?'),
        _JourneyDay(
            6,
            '12.13',
            'Choose kindness',
            'Peace deepens when the heart lets go of hostility.',
            'Offer one quiet act of kindness.',
            'Where can I be less harsh?'),
        _JourneyDay(
            7,
            '18.66',
            'Return to refuge',
            'Surrender is a movement toward trust, not a defeat.',
            'Sit quietly for one minute in surrender.',
            'What does refuge mean for me today?'),
      ],
    ),
    _Journey(
      id: 'journey_discipline_14',
      title: 'Journey of Discipline',
      subtitle: 'Build focus and consistency.',
      icon: Icons.shield_rounded,
      days: [
        _JourneyDay(
            1,
            '3.8',
            'Begin with duty',
            'Discipline starts with the duty nearest to you.',
            'Finish one necessary duty first.',
            'What duty is asking for my attention?'),
        _JourneyDay(
            2,
            '2.47',
            'Focus on effort',
            'Your part is the action. Let the result come in its time.',
            'Work for 20 minutes without checking results.',
            'Where am I attached to an outcome?'),
        _JourneyDay(
            3,
            '6.26',
            'Return the mind',
            'A wandering mind is not failure. Returning is the practice.',
            'Gently return from one distraction.',
            'What pulls my attention away most often?'),
        _JourneyDay(
            4,
            '6.35',
            'Practice and detachment',
            'Steadiness grows through repeated practice and soft release.',
            'Repeat one good habit today.',
            'What habit needs patient repetition?'),
        _JourneyDay(
            5,
            '3.30',
            'Offer the work',
            'Work becomes lighter when it is offered beyond ego.',
            'Begin one action with a quiet offering.',
            'How does offering change my work?'),
        _JourneyDay(
            6,
            '17.14',
            'Discipline of action',
            'Care for body, speech, and conduct is a sacred discipline.',
            'Choose one disciplined physical action.',
            'Where does my conduct need refinement?'),
        _JourneyDay(
            7,
            '17.15',
            'Discipline of speech',
            'Words can be truthful, kind, and useful at once.',
            'Speak one sentence more carefully.',
            'What words should I soften?'),
        _JourneyDay(
            8,
            '17.16',
            'Discipline of mind',
            'Quietness, sincerity, and self-control make the mind clear.',
            'Take three quiet breaths before reacting.',
            'What mental habit needs steadiness?'),
        _JourneyDay(
            9,
            '18.33',
            'Firm resolve',
            'Discipline holds steady when purpose is clear.',
            'Keep one promise to yourself.',
            'What promise matters today?'),
        _JourneyDay(
            10,
            '18.46',
            'Worship through work',
            'Ordinary work becomes meaningful when done with devotion.',
            'Do one ordinary action beautifully.',
            'How can my work become worship?'),
        _JourneyDay(
            11,
            '2.50',
            'Skill in action',
            'Wisdom shapes action into something clean and careful.',
            'Do one action slowly and well.',
            'Where can I bring more skill?'),
        _JourneyDay(
            12,
            '6.17',
            'Balance sustains',
            'Discipline lasts when food, rest, work, and practice are balanced.',
            'Choose one balanced rhythm today.',
            'Where am I overdoing or neglecting?'),
        _JourneyDay(
            13,
            '14.11',
            'Choose clarity',
            'Clarity grows when attention is clean and awake.',
            'Remove one small source of clutter.',
            'What helps my inner light become clearer?'),
        _JourneyDay(
            14,
            '18.66',
            'Return with humility',
            'The deepest discipline is the willingness to return.',
            'Begin again gently where you slipped.',
            'Where can I begin again without shame?'),
      ],
    ),
    _Journey(
      id: 'journey_karma_yoga_14',
      title: 'Journey of Karma Yoga',
      subtitle: 'Act without attachment to results.',
      icon: Icons.balance_rounded,
      days: [
        _JourneyDay(
            1,
            '2.47',
            'Right to action',
            'Act sincerely, without making the result your identity.',
            'Focus on effort, not outcome.',
            'What result am I holding too tightly?'),
        _JourneyDay(
            2,
            '2.48',
            'Evenness in action',
            'Yoga steadies action by freeing it from agitation.',
            'Practice calm during one action.',
            'What would evenness look like today?'),
        _JourneyDay(
            3,
            '2.50',
            'Skillful work',
            'Karma Yoga is not passive. It is careful, wise action.',
            'Improve one small detail in your work.',
            'Where can I act with more care?'),
        _JourneyDay(
            4,
            '3.8',
            'Necessary action',
            'Avoiding duty does not bring freedom. Right action purifies.',
            'Do the necessary thing first.',
            'What have I been postponing?'),
        _JourneyDay(
            5,
            '3.9',
            'Work as offering',
            'Action offered beyond self-interest becomes freeing.',
            'Dedicate one action before starting.',
            'Who or what can I serve today?'),
        _JourneyDay(
            6,
            '3.19',
            'Act without attachment',
            'Detached action is full action without inner bargaining.',
            'Serve without seeking praise.',
            'Where do I need recognition?'),
        _JourneyDay(
            7,
            '3.30',
            'Surrender action',
            'Place action and burden before the Divine, then continue steadily.',
            'Release one burden before working.',
            'What action can I surrender today?'),
        _JourneyDay(
            8,
            '4.18',
            'Stillness in action',
            'The wise can act without inner noise.',
            'Work quietly for ten minutes.',
            'Where can I reduce inner restlessness?'),
        _JourneyDay(
            9,
            '4.24',
            'Sacred offering',
            'When the heart is aligned, action becomes sacred.',
            'Treat one action as an offering.',
            'How can ordinary work become sacred?'),
        _JourneyDay(
            10,
            '5.10',
            'Untouched by action',
            'Offering action frees the heart from stickiness.',
            'Let go after completing one action.',
            'What am I still carrying after action?'),
        _JourneyDay(
            11,
            '5.12',
            'Peace through release',
            'Peace comes when the fruits of action are released.',
            'Finish and leave one outcome alone.',
            'What outcome can I stop replaying?'),
        _JourneyDay(
            12,
            '12.6',
            'Action with devotion',
            'Devotion gives action direction and warmth.',
            'Do one duty with devotion.',
            'Where can love enter my work?'),
        _JourneyDay(
            13,
            '18.46',
            'Work as worship',
            'Your own work can become a path toward the highest.',
            'Honor one responsibility as sacred.',
            'What work is my path right now?'),
        _JourneyDay(
            14,
            '18.66',
            'Final release',
            'Karma Yoga matures into trustful surrender.',
            'Offer the day and rest.',
            'What am I ready to release?'),
      ],
    ),
    _Journey(
      id: 'journey_anxiety_7',
      title: 'Journey Through Anxiety',
      subtitle: 'Move from worry to steadiness.',
      icon: Icons.self_improvement_rounded,
      days: [
        _JourneyDay(
            1,
            '2.14',
            'This will pass',
            'Anxiety rises like weather. You can meet it without becoming it.',
            'Take five slow breaths.',
            'What feeling is passing through me?'),
        _JourneyDay(
            2,
            '2.47',
            'Return to today',
            'You do not need to solve the whole future. Do today’s action.',
            'Complete one clear next step.',
            'What is mine to do today?'),
        _JourneyDay(
            3,
            '4.10',
            'Let fear soften',
            'Fear loosens when the heart turns toward trust.',
            'Name one fear, then soften your shoulders.',
            'What fear needs compassion?'),
        _JourneyDay(
            4,
            '6.5',
            'Be a friend to yourself',
            'The mind needs guidance, not punishment.',
            'Replace one harsh thought with a kind one.',
            'How can I support myself today?'),
        _JourneyDay(
            5,
            '6.26',
            'Return again',
            'Each anxious loop is an invitation to return gently.',
            'Come back to your breath once.',
            'What helps me return?'),
        _JourneyDay(
            6,
            '9.22',
            'Held in care',
            'Trust grows when you remember you are not carrying life alone.',
            'Offer one worry before sleep.',
            'Where do I need to feel held?'),
        _JourneyDay(
            7,
            '18.66',
            'Rest in refuge',
            'At the edge of fear, surrender can become rest.',
            'Whisper a simple prayer of trust.',
            'What can I entrust today?'),
      ],
    ),
    _Journey(
      id: 'journey_clarity_21',
      title: 'Journey to Inner Clarity',
      subtitle: 'Develop deeper self-understanding.',
      icon: Icons.spa_rounded,
      days: [
        _JourneyDay(
            1,
            '2.11',
            'Begin with wisdom',
            'Clarity begins when confusion is met honestly.',
            'Write one honest sentence.',
            'Where do I feel unclear?'),
        _JourneyDay(
            2,
            '2.13',
            'See change clearly',
            'The body and circumstances change; awareness learns to witness.',
            'Notice one change without resisting it.',
            'What is changing in me?'),
        _JourneyDay(
            3,
            '2.20',
            'Remember the Self',
            'The deepest Self is not destroyed by passing events.',
            'Sit quietly with the word “steady.”',
            'What feels deeper than my current mood?'),
        _JourneyDay(
            4,
            '2.47',
            'Clarify your part',
            'Confusion softens when you know what action is yours.',
            'Name your next right action.',
            'What is mine, and what is not mine?'),
        _JourneyDay(
            5,
            '2.48',
            'Balance the mind',
            'A balanced mind sees more clearly than a hurried one.',
            'Delay one impulsive response.',
            'Where do I need balance?'),
        _JourneyDay(
            6,
            '2.55',
            'Simplify desire',
            'Clarity grows as unnecessary craving quiets.',
            'Release one unnecessary want today.',
            'What desire is clouding me?'),
        _JourneyDay(
            7,
            '2.58',
            'Draw inward',
            'Sometimes clarity requires withdrawing attention from noise.',
            'Spend five minutes without input.',
            'What noise can I step away from?'),
        _JourneyDay(
            8,
            '3.30',
            'Offer confusion',
            'You can offer even uncertainty and continue with sincerity.',
            'Begin one action with surrender.',
            'What confusion can I offer?'),
        _JourneyDay(
            9,
            '4.7',
            'Trust restoration',
            'When dharma declines, renewal begins.',
            'Repair one small disorder.',
            'What needs restoration in my life?'),
        _JourneyDay(
            10,
            '4.34',
            'Seek with humility',
            'Clarity opens through sincere inquiry and reverence.',
            'Ask one honest question.',
            'What do I need to learn?'),
        _JourneyDay(
            11,
            '4.38',
            'Knowledge purifies',
            'True knowledge quiets the heart over time.',
            'Read one verse slowly.',
            'What truth is becoming clearer?'),
        _JourneyDay(
            12,
            '5.18',
            'See with equality',
            'Wisdom sees beyond surface differences.',
            'Look at one person with fresh respect.',
            'Where do I judge too quickly?'),
        _JourneyDay(
            13,
            '6.5',
            'Guide the mind',
            'Your mind can lift you when guided patiently.',
            'Redirect one unhelpful thought.',
            'How can my mind become a friend?'),
        _JourneyDay(
            14,
            '6.26',
            'Return to center',
            'Clarity is practiced each time attention returns.',
            'Return from distraction without self-blame.',
            'What keeps calling my mind away?'),
        _JourneyDay(
            15,
            '7.7',
            'See the thread',
            'The Divine holds life together like a thread through pearls.',
            'Notice one hidden connection today.',
            'Where do I sense unity?'),
        _JourneyDay(
            16,
            '9.22',
            'Trust what is needed',
            'When devotion is steady, life feels less fragmented.',
            'Ask for what is truly needed.',
            'What do I truly need today?'),
        _JourneyDay(
            17,
            '10.20',
            'Look within',
            'The Divine presence is not far from the heart.',
            'Place one hand on your heart and pause.',
            'What does my heart know quietly?'),
        _JourneyDay(
            18,
            '12.13',
            'Clarify through kindness',
            'A kind heart often sees what pride cannot.',
            'Choose kindness before certainty.',
            'Where can kindness guide me?'),
        _JourneyDay(
            19,
            '14.22',
            'Witness the gunas',
            'Clarity watches moods and qualities without being trapped by them.',
            'Observe one mood without naming it “me.”',
            'What quality is active in me today?'),
        _JourneyDay(
            20,
            '18.63',
            'Reflect and choose',
            'Wisdom invites reflection, then responsible choice.',
            'Make one choice after a quiet pause.',
            'What choice is becoming clear?'),
        _JourneyDay(
            21,
            '18.66',
            'Rest in clarity',
            'The final clarity is trustful surrender.',
            'End the day with one act of surrender.',
            'What clarity can I carry forward?'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressFuture = _initializeProgress();
  }

  @override
  void didUpdateWidget(covariant TransformationPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedJourneyId != widget.completedJourneyId ||
        oldWidget.completedJourneyDay != widget.completedJourneyDay) {
      setState(() {
        _completionNotice = null;
        _restoreCompletionNoticeFromRoute();
        _refresh();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<_JourneyProgressState> _initializeProgress() async {
    final initialJourneyId = widget.initialJourneyId;
    if (initialJourneyId != null) {
      final currentJourneyId = await LocalStorageService.currentJourneyId();
      if (currentJourneyId != initialJourneyId) {
        await LocalStorageService.startJourney(initialJourneyId);
      }
    }
    final state = await _loadProgressState();
    _restoreCompletionNoticeFromRoute();
    return state;
  }

  void _refresh() {
    _progressFuture = _loadProgressState();
  }

  Future<_JourneyProgressState> _loadProgressState() async {
    return _JourneyProgressState(
      progress: await LocalStorageService.journeyProgress(),
      currentJourneyId: await LocalStorageService.currentJourneyId(),
      currentJourneyDay: await LocalStorageService.currentJourneyDay(),
      suggestedJourneyIds: await PersonalizationService.suggestedJourneyIds(),
    );
  }

  void _restoreCompletionNoticeFromRoute() {
    final completedJourneyId = widget.completedJourneyId;
    final completedJourneyDay = widget.completedJourneyDay;
    if (completedJourneyId == null || completedJourneyDay == null) {
      return;
    }
    for (final journey in _journeys) {
      if (journey.id != completedJourneyId) {
        continue;
      }
      final completedDay = journey.days
          .where((day) => day.day == completedJourneyDay)
          .firstOrNull;
      if (completedDay == null) {
        return;
      }
      final nextDay = completedDay.day < journey.days.length
          ? journey.days[completedDay.day]
          : journey.days.last;
      _completionNotice = _JourneyCompletionNotice(
        journey: journey,
        completedDay: completedDay,
        nextDay: nextDay,
      );
      if (completedDay.day >= journey.days.length) {
        HapticFeedback.lightImpact();
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: ListView(
        controller: _scrollController,
        key: const PageStorageKey('journeys_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          const PageHeader(
            title: 'Journeys',
            subtitle: 'Gentle paths for daily reflection',
            showBack: true,
            trailing: Icon(Icons.route_rounded, color: kGold),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: FutureBuilder<_JourneyProgressState>(
              future: _progressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingStateCard(
                    message: 'Preparing journeys...',
                  );
                }
                final state = snapshot.data;
                final progress = state?.progress ?? <String, Set<int>>{};
                // Daily progress:
                // Prefer the explicitly selected Journey. This lets a newly
                // started path with no completed days still appear as current
                // after restart.
                final current = _currentJourney(
                  progress,
                  selectedJourneyId: state?.currentJourneyId,
                );
                final currentCompleted = progress[current.id] ?? <int>{};
                final currentDay = _nextJourneyDay(current, currentCompleted);
                final highlightedDay = _highlightedDay(
                  current,
                  currentDay,
                  state?.currentJourneyDay,
                  currentCompleted,
                );
                final currentComplete =
                    currentCompleted.length >= current.days.length;
                final completedJourneys = _completedJourneys(progress);
                final allJourneysComplete =
                    completedJourneys.length >= _journeys.length;
                final recommendedJourneys = _recommendedJourneys(
                  progress,
                  state?.suggestedJourneyIds ?? const <String>[],
                );
                if (allJourneysComplete) {
                  return _AllJourneysCompleteScreen(
                    completedJourneys: completedJourneys,
                    onTodaysGuidance: () => context.go('/homePage'),
                    onRestartJourney: () => _chooseRestartJourney(_journeys),
                    onOpenJournal: () => context.go('/journalPage'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CurrentJourneyCard(
                      journey: current,
                      day: highlightedDay,
                      completedDays: currentCompleted,
                      completionNotice: _completionNotice,
                      recommendedJourneys: recommendedJourneys,
                      onContinue: () {
                        _handleContinueJourney(
                          activeJourneyId: state?.currentJourneyId,
                          current: current,
                          highlightedDay: highlightedDay,
                          nextIncompleteDay: currentDay,
                          completedDays: currentCompleted,
                          isComplete: currentComplete,
                          recommendedJourneys: recommendedJourneys,
                        );
                      },
                      onCompletionContinue: () {
                        final notice = _completionNotice;
                        if (notice == null) {
                          return;
                        }
                        _selectJourneyDay(
                          notice.journey,
                          notice.nextDay,
                          scrollToTop: true,
                        );
                      },
                      onSelectNextJourney: (journey) {
                        _startNextJourneyFromJourneys(
                          sheetContext: context,
                          journey: journey,
                          closeSheet: false,
                        );
                      },
                      onChooseNextJourney: () =>
                          _chooseNextJourney(recommendedJourneys),
                      onMarkDayComplete: () => _markJourneyDayComplete(
                        current,
                        highlightedDay,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _Journey _currentJourney(
    Map<String, Set<int>> progress, {
    String? selectedJourneyId,
  }) {
    // Journey state priority:
    // 1. persisted current journey
    // 2. explicit route entry from Home/selection
    // 3. any in-progress journey
    // 4. the first bundled journey as a calm default for first launch
    if (selectedJourneyId != null) {
      for (final journey in _journeys) {
        if (journey.id == selectedJourneyId) {
          return journey;
        }
      }
    }
    final initialJourneyId = widget.initialJourneyId;
    if (initialJourneyId != null) {
      for (final journey in _journeys) {
        if (journey.id == initialJourneyId) {
          return journey;
        }
      }
    }
    for (final journey in _journeys) {
      final completed = progress[journey.id] ?? <int>{};
      if (completed.isNotEmpty && completed.length < journey.days.length) {
        return journey;
      }
    }
    return _journeys.first;
  }

  List<_Journey> _completedJourneys(Map<String, Set<int>> progress) {
    // Completion is derived from completed day counts so old installs do not
    // depend on a separate completion flag being perfectly in sync.
    return [
      for (final journey in _journeys)
        if ((progress[journey.id] ?? <int>{}).length >= journey.days.length)
          journey,
    ];
  }

  List<_Journey> _recommendedJourneys(
    Map<String, Set<int>> progress,
    List<String> suggestedJourneyIds,
  ) {
    const fallbackIds = [
      'journey_discipline_14',
      'journey_karma_yoga_14',
      'journey_anxiety_7',
      'journey_clarity_21',
    ];
    final completedIds =
        _completedJourneys(progress).map((journey) => journey.id).toSet();
    final seen = <String>{};
    return [
      for (final id in [...suggestedJourneyIds, ...fallbackIds])
        if (seen.add(id))
          for (final journey in _journeys)
            if (journey.id == id && !completedIds.contains(journey.id)) journey,
    ];
  }

  _JourneyDay _nextJourneyDay(_Journey journey, Set<int> completedDays) {
    // Continue Journey always targets the earliest incomplete day. This keeps
    // the path guided and avoids dropping users into a random chapter reader.
    for (final day in journey.days) {
      if (!completedDays.contains(day.day)) {
        return day;
      }
    }
    return journey.days.last;
  }

  _JourneyDay _highlightedDay(
    _Journey journey,
    _JourneyDay fallback,
    int? storedDay,
    Set<int> completedDays,
  ) {
    // A stored day keeps the user's place stable across app restarts. If that
    // day is already complete, fall back to the next incomplete day.
    if (storedDay == null) {
      return fallback;
    }
    for (final day in journey.days) {
      if (day.day == storedDay && !completedDays.contains(day.day)) {
        return day;
      }
    }
    return fallback;
  }

  Future<void> _handleContinueJourney({
    required String? activeJourneyId,
    required _Journey current,
    required _JourneyDay highlightedDay,
    required _JourneyDay nextIncompleteDay,
    required Set<int> completedDays,
    required bool isComplete,
    required List<_Journey> recommendedJourneys,
  }) async {
    _journeyDebugLog('Continue Journey tapped');
    _journeyDebugLog('activeJourneyId: ${activeJourneyId ?? 'none'}');
    _journeyDebugLog('currentDay: ${highlightedDay.day}');
    final highlightedCompleted = completedDays.contains(highlightedDay.day);
    _journeyDebugLog('currentDayCompleted: $highlightedCompleted');

    if (activeJourneyId == null || activeJourneyId.isEmpty) {
      await LocalStorageService.setCurrentJourneyDay(
        journeyId: current.id,
        day: highlightedDay.day,
      );
      _journeyDebugLog('selected journey saved: ${current.id}');
      if (!mounted) {
        return;
      }
    }

    if (isComplete) {
      _journeyDebugLog('navigation target: Journey Complete');
      if (recommendedJourneys.isNotEmpty) {
        _chooseNextJourney(recommendedJourneys);
      } else {
        _showJourneyMessage('You completed ${current.title}.');
      }
      return;
    }

    final targetDay = highlightedCompleted ? nextIncompleteDay : highlightedDay;
    _journeyDebugLog('navigation target: Day ${targetDay.day}');
    await _selectJourneyDay(current, targetDay, scrollToTop: true);
    if (!mounted) {
      return;
    }
  }

  Future<void> _startNextJourneyFromJourneys({
    required BuildContext sheetContext,
    required _Journey journey,
    bool closeSheet = true,
    bool confirmIfCompleted = true,
  }) async {
    _journeyDebugLog('selectedJourneyId: ${journey.id}');
    final currentBefore = await LocalStorageService.currentJourneyId();
    _journeyDebugLog('currentJourneyId before: ${currentBefore ?? 'none'}');
    final completedIds = await LocalStorageService.completedJourneyIds();
    if (confirmIfCompleted && completedIds.contains(journey.id)) {
      final shouldRestart = await _confirmRestartJourney(journey);
      if (shouldRestart != true) {
        _journeyDebugLog('navigation target: restart cancelled');
        return;
      }
    }
    // Starting a new Journey resets only that Journey's active day. Previously
    // completed Journeys remain complete so Home can show meaningful continuity.
    await LocalStorageService.startJourney(journey.id);
    final currentAfter = await LocalStorageService.currentJourneyId();
    _journeyDebugLog('currentJourneyId after: ${currentAfter ?? 'none'}');
    _journeyDebugLog('navigation target: JourneyDay ${journey.id} Day 1');
    if (!mounted || !sheetContext.mounted) {
      return;
    }
    if (closeSheet) {
      Navigator.of(sheetContext).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'One sincere step is enough today.',
          style: gitaBody(color: kText, weight: FontWeight.w800),
        ),
        backgroundColor: kRoyalPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _completionNotice = null;
      _refresh();
    });
    _scrollToCurrentJourney();
  }

  Future<bool?> _confirmRestartJourney(_Journey journey) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Restart Journey?', style: gitaTitle(22)),
        content: Text(
          '${journey.title} was completed before. Restart from Day 1?',
          style: gitaBody(color: kText).copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: gitaBody(color: kGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Restart Journey',
              style: gitaBody(color: kGold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseNextJourney(List<_Journey> journeys) async {
    if (journeys.isEmpty) {
      _showJourneyMessage('The journey of wisdom continues every day.');
      return;
    }
    _journeyDebugLog('Choose Next Journey tapped');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _NextJourneySheet(
        journeys: journeys,
        onSelectJourney: (journey) => _startNextJourneyFromJourneys(
          sheetContext: sheetContext,
          journey: journey,
        ),
      ),
    );
  }

  Future<void> _chooseRestartJourney(List<_Journey> journeys) async {
    _journeyDebugLog('Restart a Journey tapped');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _NextJourneySheet(
        title: 'Restart a Journey',
        subtitle: 'Choose a path to begin again from Day 1.',
        journeys: journeys,
        showCompletedBeforeBadge: true,
        onSelectJourney: (journey) => _startNextJourneyFromJourneys(
          sheetContext: sheetContext,
          journey: journey,
        ),
      ),
    );
  }

  Future<void> _selectJourneyDay(
    _Journey journey,
    _JourneyDay day, {
    bool scrollToTop = false,
  }) async {
    // Selecting a day updates the persisted current Journey/day before the UI
    // refreshes, so Home and Verse Reader receive the same navigation context.
    await LocalStorageService.setCurrentJourneyDay(
      journeyId: journey.id,
      day: day.day,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _completionNotice = null;
      _refresh();
    });
    if (scrollToTop) {
      _scrollToCurrentJourney();
    }
  }

  void _scrollToCurrentJourney() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showJourneyMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: gitaBody(color: kText, weight: FontWeight.w800),
          ),
          backgroundColor: kRoyalPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _markJourneyDayComplete(
    _Journey journey,
    _JourneyDay day,
  ) async {
    _journeyDebugLog('Mark journey day complete tapped');
    _journeyDebugLog('journeyId: ${journey.id}');
    _journeyDebugLog('day: ${day.day}');
    HapticFeedback.lightImpact();
    await LocalStorageService.setJourneyDayComplete(
      journeyId: journey.id,
      day: day.day,
      complete: true,
      totalDays: journey.days.length,
    );
    final nextDay = day.day < journey.days.length
        ? journey.days[day.day]
        : journey.days.last;
    await LocalStorageService.setCurrentJourneyDay(
      journeyId: journey.id,
      day: nextDay.day,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _completionNotice = _JourneyCompletionNotice(
        journey: journey,
        completedDay: day,
        nextDay: nextDay,
      );
      _refresh();
    });
    _scrollToCurrentJourney();
  }
}

class _CurrentJourneyCard extends StatelessWidget {
  const _CurrentJourneyCard({
    required this.journey,
    required this.day,
    required this.completedDays,
    required this.completionNotice,
    required this.recommendedJourneys,
    required this.onContinue,
    required this.onCompletionContinue,
    required this.onSelectNextJourney,
    required this.onChooseNextJourney,
    required this.onMarkDayComplete,
  });

  final _Journey journey;
  final _JourneyDay day;
  final Set<int> completedDays;
  final _JourneyCompletionNotice? completionNotice;
  final List<_Journey> recommendedJourneys;
  final VoidCallback onContinue;
  final VoidCallback onCompletionContinue;
  final ValueChanged<_Journey> onSelectNextJourney;
  final VoidCallback onChooseNextJourney;
  final VoidCallback onMarkDayComplete;

  @override
  Widget build(BuildContext context) {
    final activeDay = completionNotice?.completedDay ?? day;
    final completedCount = completedDays.length;
    final isCompleted = completedDays.contains(activeDay.day);
    final isJourneyComplete = completedCount >= journey.days.length;
    final notice = completionNotice;
    if (notice != null &&
        notice.completedDay.day >= notice.journey.days.length) {
      return _JourneyCompleteScreen(
        notice: notice,
        onChooseNextJourney: onChooseNextJourney,
      );
    }
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccentPill(
              isJourneyComplete ? 'Journey Complete' : 'Current Journey'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconMedallion(icon: journey.icon, size: 50),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      style: gitaTitle(24).copyWith(color: kText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isJourneyComplete
                          ? '${journey.days.length} of ${journey.days.length} days complete'
                          : 'Day ${activeDay.day} of ${journey.days.length}',
                      style: gitaBody(
                        color: kAntiqueGold,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              AccentPill('$completedCount/${journey.days.length}'),
            ],
          ),
          const SizedBox(height: 16),
          _JourneyProgressDots(
            totalDays: journey.days.length,
            completedDays: completedDays,
            currentDay: activeDay.day,
          ),
          const SizedBox(height: 18),
          if (isJourneyComplete && completionNotice == null) ...[
            _JourneyCompletionDetail(
              journeyTitle: journey.title,
              daysOfReflection: journey.days.length,
            ),
          ] else if (!isJourneyComplete && completionNotice == null)
            _JourneyDayReading(day: activeDay),
          if (completionNotice != null) ...[
            const SizedBox(height: 14),
            _DayCompleteCard(
              notice: completionNotice!,
              onContinue: onCompletionContinue,
            ),
          ],
          if (completionNotice == null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (isJourneyComplete)
                  GoldButton(
                    key: const ValueKey('journey_choose_next'),
                    label: 'Choose Next Journey',
                    icon: Icons.route_rounded,
                    onPressed: onChooseNextJourney,
                  )
                else if (isCompleted)
                  GoldButton(
                    key: const ValueKey('journey_continue'),
                    label: 'Continue',
                    icon: Icons.route_rounded,
                    onPressed: onContinue,
                  )
                else
                  GoldButton(
                    key: const ValueKey('journey_mark_day_complete'),
                    label: 'Mark Day Complete',
                    icon: Icons.check_rounded,
                    onPressed: onMarkDayComplete,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneyProgressDots extends StatelessWidget {
  const _JourneyProgressDots({
    required this.totalDays,
    required this.completedDays,
    required this.currentDay,
  });

  final int totalDays;
  final Set<int> completedDays;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (var day = 1; day <= totalDays; day += 1)
          Container(
            width: day == currentDay ? 18 : 9,
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: completedDays.contains(day) || day == currentDay
                  ? kGold
                  : kGold.withValues(alpha: 0.18),
            ),
          ),
      ],
    );
  }
}

class _AllJourneysCompleteScreen extends StatelessWidget {
  const _AllJourneysCompleteScreen({
    required this.completedJourneys,
    required this.onTodaysGuidance,
    required this.onRestartJourney,
    required this.onOpenJournal,
  });

  final List<_Journey> completedJourneys;
  final VoidCallback onTodaysGuidance;
  final VoidCallback onRestartJourney;
  final VoidCallback onOpenJournal;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: PremiumCard(
        accent: true,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.center,
              child: _GoldenLotusCompletionSeal(),
            ),
            const SizedBox(height: 18),
            Text(
              '🌸 All Journeys Complete',
              textAlign: TextAlign.center,
              style: gitaTitle(25).copyWith(color: kText),
            ),
            const SizedBox(height: 18),
            _CompletedJourneyList(journeys: completedJourneys),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kGold.withValues(alpha: 0.22)),
              ),
              child: Text(
                'Wisdom is not something we finish.\n'
                'It is something we return to again and again.',
                textAlign: TextAlign.center,
                style: gitaBody(
                  color: kDarkText.withValues(alpha: 0.86),
                  size: 15,
                  weight: FontWeight.w800,
                ).copyWith(height: 1.58),
              ),
            ),
            const SizedBox(height: 18),
            GoldButton(
              key: const ValueKey('journey_restart'),
              label: 'Restart a Journey',
              icon: Icons.refresh_rounded,
              onPressed: onRestartJourney,
            ),
            const SizedBox(height: 10),
            _QuietJourneyActionButton(
              label: "Today's Guidance",
              icon: Icons.wb_sunny_rounded,
              onPressed: onTodaysGuidance,
            ),
            const SizedBox(height: 10),
            _QuietJourneyActionButton(
              label: 'Open Journal',
              icon: Icons.edit_note_rounded,
              onPressed: onOpenJournal,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedJourneyList extends StatelessWidget {
  const _CompletedJourneyList({required this.journeys});

  final List<_Journey> journeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final journey in journeys) ...[
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: kCream.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGold.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                IconMedallion(icon: journey.icon, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.title,
                        style: gitaBody(
                          color: kDarkText,
                          weight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${journey.days.length} Days',
                        style: gitaBody(
                          color: kAntiqueGold,
                          size: 12,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_rounded,
                  color: kGold,
                  size: 20,
                ),
              ],
            ),
          ),
          if (journey != journeys.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _QuietJourneyActionButton extends StatelessWidget {
  const _QuietJourneyActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: kRoyalPurple,
        side: BorderSide(color: kGold.withValues(alpha: 0.34)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        textStyle: gitaBody(weight: FontWeight.w900),
      ),
    );
  }
}

class _JourneyCompleteScreen extends StatelessWidget {
  const _JourneyCompleteScreen({
    required this.notice,
    required this.onChooseNextJourney,
  });

  final _JourneyCompletionNotice notice;
  final VoidCallback onChooseNextJourney;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 760),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: scale.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kGold.withValues(alpha: 0.36)),
              boxShadow: [
                BoxShadow(
                  color: kGold.withValues(alpha: 0.24),
                  blurRadius: 42,
                  spreadRadius: 1,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: kRoyalPurple.withValues(alpha: 0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _GoldenLotusCompletionSeal(),
                const SizedBox(height: 16),
                Text(
                  '🌸 Journey Complete',
                  textAlign: TextAlign.center,
                  style: gitaTitle(25).copyWith(color: kDarkText),
                ),
                const SizedBox(height: 10),
                Text(
                  notice.journey.title,
                  textAlign: TextAlign.center,
                  style: gitaBody(
                    color: kRoyalPurple,
                    size: 18,
                    weight: FontWeight.w900,
                  ).copyWith(height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: kGold.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    '${notice.journey.days.length} Days of Reflection',
                    style: gitaBody(
                      color: kAntiqueGold,
                      size: 13,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You completed this journey with sincerity and practice.',
                  textAlign: TextAlign.center,
                  style: gitaBody(
                    color: kDarkText.withValues(alpha: 0.84),
                    size: 15,
                    weight: FontWeight.w700,
                  ).copyWith(height: 1.55),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: kGold.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    'What insight will you carry forward?',
                    textAlign: TextAlign.center,
                    style: gitaBody(
                      color: kRoyalPurple,
                      size: 15,
                      weight: FontWeight.w900,
                    ).copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        GoldButton(
          key: const ValueKey('journey_choose_next'),
          label: 'Choose Next Journey',
          icon: Icons.route_rounded,
          onPressed: onChooseNextJourney,
        ),
      ],
    );
  }
}

class _GoldenLotusCompletionSeal extends StatelessWidget {
  const _GoldenLotusCompletionSeal();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.82 + (value * 0.18),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kGold.withValues(alpha: 0.18),
                  kGold.withValues(alpha: 0.08),
                  kCream,
                ],
              ),
              border: Border.all(color: kGold.withValues(alpha: 0.26)),
              boxShadow: [
                BoxShadow(
                  color: kGold.withValues(alpha: 0.14 * value),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.86 + (value * 0.14),
                  child: Icon(
                    Icons.local_florist_rounded,
                    color: kGold.withValues(alpha: 0.44),
                    size: 58,
                  ),
                ),
                const Icon(
                  Icons.check_rounded,
                  color: kRoyalPurple,
                  size: 25,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NextJourneySheet extends StatelessWidget {
  const _NextJourneySheet({
    this.title = 'Choose Next Journey',
    this.subtitle = 'Begin again with one clear path.',
    required this.journeys,
    required this.onSelectJourney,
    this.showCompletedBeforeBadge = false,
  });

  final String title;
  final String subtitle;
  final List<_Journey> journeys;
  final ValueChanged<_Journey> onSelectJourney;
  final bool showCompletedBeforeBadge;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: PremiumCard(
          accent: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: gitaTitle(22).copyWith(color: kText),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: gitaBody(
                  color: kMuted.withValues(alpha: 0.88),
                  weight: FontWeight.w700,
                ).copyWith(height: 1.45),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final journey in journeys) ...[
                        _NextJourneyTile(
                          journey: journey,
                          completedBefore: showCompletedBeforeBadge,
                          onTap: () => onSelectJourney(journey),
                        ),
                        if (journey != journeys.last)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextJourneyTile extends StatelessWidget {
  const _NextJourneyTile({
    required this.journey,
    required this.onTap,
    this.completedBefore = false,
  });

  final _Journey journey;
  final VoidCallback onTap;
  final bool completedBefore;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        key: ValueKey('journey_next_${journey.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGold.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            IconMedallion(icon: journey.icon, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.title,
                    style: gitaBody(
                      color: kDarkText,
                      weight: FontWeight.w900,
                    ).copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${journey.days.length} Days',
                    style: gitaBody(
                      color: kAntiqueGold,
                      size: 12,
                      weight: FontWeight.w900,
                    ),
                  ),
                  if (completedBefore) ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: kGold.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        'Reflected before',
                        style: gitaBody(
                          color: kAntiqueGold,
                          size: 11,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    journey.subtitle,
                    style: gitaBody(
                      color: kDarkText.withValues(alpha: 0.68),
                      size: 12,
                      weight: FontWeight.w700,
                    ).copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: kGold,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyCompletionDetail extends StatelessWidget {
  const _JourneyCompletionDetail({
    required this.journeyTitle,
    required this.daysOfReflection,
  });

  final String journeyTitle;
  final int daysOfReflection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGold.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CompletionSeal(),
          const SizedBox(height: 14),
          Text(
            '🌸 Journey Complete',
            style: gitaTitle(22).copyWith(color: kDarkText),
          ),
          const SizedBox(height: 8),
          Text(
            journeyTitle,
            style: gitaBody(
              color: kRoyalPurple,
              size: 16,
              weight: FontWeight.w900,
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            '$daysOfReflection Days of Reflection',
            style: gitaBody(
              color: kDarkText,
              size: 15,
              weight: FontWeight.w900,
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed this journey with sincerity and practice.',
            style: gitaBody(color: kDarkText, size: 14).copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          const _DetailLine(
            label: 'Reflection',
            text: 'What insight will you carry forward?',
          ),
          const SizedBox(height: 12),
          _DetailLine(
            label: journeyTitle,
            text: 'Completed',
          ),
        ],
      ),
    );
  }
}

class _CompletionSeal extends StatelessWidget {
  const _CompletionSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kGold.withValues(alpha: 0.18),
        border: Border.all(color: kGold.withValues(alpha: 0.42)),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: kGold,
        size: 28,
      ),
    );
  }
}

class _DayCompleteCard extends StatelessWidget {
  const _DayCompleteCard({
    required this.notice,
    required this.onContinue,
  });

  final _JourneyCompletionNotice notice;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isFinalDay = notice.completedDay.day >= notice.journey.days.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGold.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFinalDay ? Icons.local_florist_rounded : Icons.check_rounded,
                color: kGold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFinalDay ? 'Journey Complete' : 'Day Complete',
                  style: gitaBody(color: kDarkText, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isFinalDay ? notice.journey.title : 'Next: ${notice.nextDay.title}',
            style: gitaBody(
              color: kRoyalPurple,
              weight: FontWeight.w900,
            ).copyWith(height: 1.45),
          ),
          if (isFinalDay) ...[
            const SizedBox(height: 8),
            Text(
              '${notice.journey.days.length} Days of Reflection',
              style: gitaBody(
                color: kDarkText,
                size: 15,
                weight: FontWeight.w900,
              ).copyWith(height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'You completed this journey with sincerity and practice.',
              style: gitaBody(color: kDarkText, size: 13).copyWith(
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            const _DetailLine(
              label: 'Reflection',
              text: 'What insight will you carry forward?',
            ),
            const SizedBox(height: 12),
            _DetailLine(
              label: notice.journey.title,
              text: 'Completed',
            ),
          ],
          const SizedBox(height: 14),
          GoldButton(
            key: const ValueKey('journey_completion_continue'),
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _JourneyDayReading extends StatelessWidget {
  const _JourneyDayReading({required this.day});

  final _JourneyDay day;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<gita_data.GitaVerse?>(
      future: gita_data.GitaRepository.verseById(day.verseId),
      builder: (context, snapshot) {
        final verse = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateCard(message: 'Preparing today’s verse...');
        }
        if (verse == null) {
          return _JourneyDayDetail(day: day);
        }
        final sanskrit = verse.sanskrit.trim();
        final transliteration = verse.transliteration.trim();
        final translation = verse.englishTranslation.trim();
        final interpretation = verse.gitaWisdomInterpretation.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kGold.withValues(alpha: 0.24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailLine(label: "Today's Theme", text: day.title),
                  const SizedBox(height: 12),
                  _DetailLine(
                    label: 'Verse Reference',
                    text: verse.reference,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kNavy.withValues(alpha: 0.98),
                    kCard.withValues(alpha: 0.98),
                    kDeepBrinjal.withValues(alpha: 0.96),
                  ],
                ),
                border: Border.all(color: kGold.withValues(alpha: 0.28)),
                boxShadow: [
                  BoxShadow(
                    color: kGold.withValues(alpha: 0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sanskrit.isNotEmpty) ...[
                    const _JourneyReadingLabel('Sanskrit'),
                    const SizedBox(height: 8),
                    Text(
                      sanskrit,
                      style: gitaSanskrit(25).copyWith(
                        color: kAntiqueGold,
                        height: 1.72,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (transliteration.isNotEmpty) ...[
                    const _JourneyReadingLabel('Transliteration'),
                    const SizedBox(height: 8),
                    Text(
                      transliteration,
                      style: gitaTransliteration(
                        size: 17,
                        color: kText.withValues(alpha: 0.92),
                      ).copyWith(height: 1.58, letterSpacing: 0),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (translation.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kGold.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _JourneyStudyLabel(
                            icon: Icons.translate_rounded,
                            label: 'Translation',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            translation,
                            style: gitaBody(
                              color: kDarkText,
                              size: 16,
                              weight: FontWeight.w700,
                            ).copyWith(height: 1.58),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (interpretation.isNotEmpty) ...[
              _JourneyStudyPanel(
                icon: Icons.notes_rounded,
                title: 'Gita Wisdom Interpretation',
                text: interpretation,
              ),
              const SizedBox(height: 14),
            ],
            _JourneyStudyPanel(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Reflection',
              text: day.reflection,
              footer: 'Carry one insight from this verse into your day.',
            ),
            const SizedBox(height: 14),
            _JourneyStudyPanel(
              icon: Icons.spa_rounded,
              title: 'Practice Today',
              text: day.practiceToday,
              softlyHighlighted: true,
            ),
          ],
        );
      },
    );
  }
}

class _JourneyReadingLabel extends StatelessWidget {
  const _JourneyReadingLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: gitaBody(
        color: kGold,
        size: 12,
        weight: FontWeight.w900,
      ),
    );
  }
}

class _JourneyStudyPanel extends StatelessWidget {
  const _JourneyStudyPanel({
    required this.icon,
    required this.title,
    required this.text,
    this.footer,
    this.softlyHighlighted = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? footer;
  final bool softlyHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softlyHighlighted ? null : kCream,
        gradient: softlyHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kCream,
                  kSoftGold.withValues(alpha: 0.28),
                  kCream,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGold.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JourneyStudyLabel(icon: icon, label: title),
          const SizedBox(height: 12),
          Text(
            text,
            style: gitaBody(
              color: kDarkText,
              size: 16,
              weight: FontWeight.w700,
            ).copyWith(height: 1.58),
          ),
          if (footer != null) ...[
            const SizedBox(height: 14),
            Text(
              footer!,
              style: gitaTransliteration(
                color: kRoyalPurple.withValues(alpha: 0.78),
                size: 14,
              ).copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneyStudyLabel extends StatelessWidget {
  const _JourneyStudyLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gitaBody(color: kDarkText, weight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _JourneyDayDetail extends StatelessWidget {
  const _JourneyDayDetail({required this.day});

  final _JourneyDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGold.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailLine(label: "Today's focus", text: day.title),
          const SizedBox(height: 12),
          _DetailLine(
            label: 'Verse Reference',
            text: 'Bhagavad Gita ${day.verseId}',
          ),
          const SizedBox(height: 14),
          _DetailLine(label: 'Reflection', text: day.reflection),
          const SizedBox(height: 12),
          _DetailLine(label: 'Practice Today', text: day.practiceToday),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: gitaBody(
            color: kRoyalPurple,
            size: 12,
            weight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: gitaBody(
            color: kDarkText,
            size: 16,
            weight: FontWeight.w700,
          ).copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _JourneyProgressState {
  const _JourneyProgressState({
    required this.progress,
    required this.currentJourneyId,
    required this.currentJourneyDay,
    required this.suggestedJourneyIds,
  });

  final Map<String, Set<int>> progress;
  final String? currentJourneyId;
  final int currentJourneyDay;
  final List<String> suggestedJourneyIds;
}

class _JourneyCompletionNotice {
  const _JourneyCompletionNotice({
    required this.journey,
    required this.completedDay,
    required this.nextDay,
  });

  final _Journey journey;
  final _JourneyDay completedDay;
  final _JourneyDay nextDay;
}

class _Journey {
  // Journey model:
  // Each path is bundled content with a stable ID for local progress, a public
  // title/subtitle for the card, and a fixed ordered list of daily practices.
  const _Journey({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.days,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_JourneyDay> days;
}

class _JourneyDay {
  // A daily journey step always contains the four user-facing pieces requested
  // for this habit feature: Verse, Reflection, Practice Today, Journal Prompt.
  const _JourneyDay(
    this.day,
    this.verseId,
    this.title,
    this.reflection,
    this.practiceToday,
    this.journalPrompt,
  );

  final int day;
  final String verseId;
  final String title;
  final String reflection;
  final String practiceToday;
  final String journalPrompt;
}
