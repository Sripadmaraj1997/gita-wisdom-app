// Journeys screen.
//
// Calm local study paths inspired by proven spiritual app patterns. Journey
// definitions are bundled in the app; progress is stored in shared_preferences
// through LocalStorageService. No account, feed, or social surface is involved.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/local_storage_service.dart';
import '../gita_common/gita_common.dart';

class TransformationPageWidget extends StatefulWidget {
  const TransformationPageWidget({super.key});

  static String routeName = 'TransformationPage';
  static String routePath = '/transformationPage';

  @override
  State<TransformationPageWidget> createState() =>
      _TransformationPageWidgetState();
}

class _TransformationPageWidgetState extends State<TransformationPageWidget> {
  late Future<Map<String, Set<int>>> _progressFuture;

  static const _journeys = [
    _Journey(
      id: 'journey_peace_7',
      title: 'Journey to Peace',
      subtitle: '7 days for steadiness, release, and gentle trust.',
      icon: Icons.self_improvement_rounded,
      days: [
        _JourneyDay(
            1,
            '2.47',
            'Act without clinging',
            'Let effort be sincere, then loosen the grip on the result.',
            'Complete one task with full attention.',
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
      subtitle: '14 days of small, steady action.',
      icon: Icons.spa_rounded,
      days: [
        _JourneyDay(
            1,
            '3.8',
            'Begin with duty',
            'Discipline starts with the duty nearest to you.',
            'Finish one necessary task first.',
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
            'Begin one task with a quiet offering.',
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
            'Do one ordinary task beautifully.',
            'How can my work become worship?'),
        _JourneyDay(
            11,
            '2.50',
            'Skill in action',
            'Wisdom shapes action into something clean and careful.',
            'Do one task slowly and well.',
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
      subtitle: '14 days on action, offering, and freedom from results.',
      icon: Icons.menu_book_rounded,
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
            'Practice calm during one task.',
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
            'Dedicate one task before starting.',
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
            'Treat one task as an offering.',
            'How can ordinary work become sacred?'),
        _JourneyDay(
            10,
            '5.10',
            'Untouched by action',
            'Offering action frees the heart from stickiness.',
            'Let go after completing one task.',
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
      subtitle: '7 days for fear, uncertainty, and inner steadiness.',
      icon: Icons.nights_stay_rounded,
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
      subtitle: '21 days for discernment, self-knowledge, and quiet wisdom.',
      icon: Icons.lightbulb_outline_rounded,
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
    _refresh();
  }

  void _refresh() {
    _progressFuture = LocalStorageService.journeyProgress();
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: ListView(
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
            child: FutureBuilder<Map<String, Set<int>>>(
              future: _progressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingStateCard(
                    message: 'Preparing journeys...',
                  );
                }
                final progress = snapshot.data ?? <String, Set<int>>{};
                // Daily progress:
                // The current journey is the first in-progress path. If the
                // user has not started one, the first journey becomes the calm
                // default instead of forcing a setup step.
                final current = _currentJourney(progress);
                final currentCompleted = progress[current.id] ?? <int>{};
                final currentDay = _nextJourneyDay(current, currentCompleted);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CurrentJourneyCard(
                      journey: current,
                      day: currentDay,
                      completedDays: currentCompleted,
                      onContinue: () => _openJourneyDay(currentDay),
                      onComplete: () => _toggleDay(
                        current,
                        currentDay,
                        currentCompleted.contains(currentDay.day),
                      ),
                      onJournal: () => _openJournalForDay(currentDay),
                    ),
                    const SizedBox(height: 20),
                    for (final journey in _journeys) ...[
                      _JourneyCard(
                        journey: journey,
                        completedDays: progress[journey.id] ?? <int>{},
                        onToggleDay: _toggleDay,
                        onOpenDay: _openJourneyDay,
                        onJournalDay: _openJournalForDay,
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _Journey _currentJourney(Map<String, Set<int>> progress) {
    for (final journey in _journeys) {
      final completed = progress[journey.id] ?? <int>{};
      if (completed.isNotEmpty && completed.length < journey.days.length) {
        return journey;
      }
    }
    return _journeys.first;
  }

  _JourneyDay _nextJourneyDay(_Journey journey, Set<int> completedDays) {
    for (final day in journey.days) {
      if (!completedDays.contains(day.day)) {
        return day;
      }
    }
    return journey.days.last;
  }

  Future<void> _toggleDay(
    _Journey journey,
    _JourneyDay day,
    bool completed,
  ) async {
    // Local persistence:
    // Journey completion is stored only in shared_preferences, keeping this
    // habit feature private and usable offline.
    await LocalStorageService.setJourneyDayComplete(
      journeyId: journey.id,
      day: day.day,
      complete: !completed,
    );
    if (!mounted) {
      return;
    }
    setState(_refresh);
  }

  void _openJourneyDay(_JourneyDay day) {
    context.push(Uri(
      path: '/verseReaderPage',
      queryParameters: {'verseId': day.verseId},
    ).toString());
  }

  void _openJournalForDay(_JourneyDay day) {
    context.push(Uri(
      path: '/journalPage',
      queryParameters: {
        'prefill': day.journalPrompt,
        'chapter': day.verseId.split('.').first,
      },
    ).toString());
  }
}

class _CurrentJourneyCard extends StatelessWidget {
  const _CurrentJourneyCard({
    required this.journey,
    required this.day,
    required this.completedDays,
    required this.onContinue,
    required this.onComplete,
    required this.onJournal,
  });

  final _Journey journey;
  final _JourneyDay day;
  final Set<int> completedDays;
  final VoidCallback onContinue;
  final VoidCallback onComplete;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedDays.length;
    final isCompleted = completedDays.contains(day.day);
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AccentPill('Current Journey'),
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
                      'Day ${day.day} of ${journey.days.length}',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completedCount / journey.days.length,
              minHeight: 6,
              backgroundColor: kGold.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(kGold),
            ),
          ),
          const SizedBox(height: 18),
          _JourneyDayDetail(day: day),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GoldButton(
                label: 'Continue Journey',
                icon: Icons.play_arrow_rounded,
                onPressed: onContinue,
              ),
              _JourneyMiniAction(
                icon: isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: isCompleted ? 'Completed' : 'Mark Complete',
                onTap: onComplete,
              ),
              _JourneyMiniAction(
                icon: Icons.edit_note_rounded,
                label: 'Journal',
                onTap: onJournal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.journey,
    required this.completedDays,
    required this.onToggleDay,
    required this.onOpenDay,
    required this.onJournalDay,
  });

  final _Journey journey;
  final Set<int> completedDays;
  final Future<void> Function(_Journey journey, _JourneyDay day, bool completed)
      onToggleDay;
  final ValueChanged<_JourneyDay> onOpenDay;
  final ValueChanged<_JourneyDay> onJournalDay;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedDays.length;
    final progress = completedCount / journey.days.length;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconMedallion(icon: journey.icon, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      style: gitaBody(color: kText, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      journey.subtitle,
                      style: gitaBody(color: kMuted, size: 13),
                    ),
                  ],
                ),
              ),
              AccentPill('$completedCount/${journey.days.length}'),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: kLine,
              valueColor: const AlwaysStoppedAnimation<Color>(kGold),
            ),
          ),
          const SizedBox(height: 14),
          for (final day in journey.days) ...[
            _JourneyDayRow(
              day: day,
              completed: completedDays.contains(day.day),
              onToggle: () => onToggleDay(
                journey,
                day,
                completedDays.contains(day.day),
              ),
              onOpen: () => onOpenDay(day),
              onJournal: () => onJournalDay(day),
            ),
            if (day != journey.days.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _JourneyDayRow extends StatelessWidget {
  const _JourneyDayRow({
    required this.day,
    required this.completed,
    required this.onToggle,
    required this.onOpen,
    required this.onJournal,
  });

  final _JourneyDay day;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed
            ? kGold.withValues(alpha: 0.12)
            : kCard2.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed
              ? kGold.withValues(alpha: 0.38)
              : kLine.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressableScale(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(100),
            child: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: completed ? kGold : kMuted,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PressableScale(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${day.day}: ${day.title}',
                    style: gitaBody(color: kText, weight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bhagavad Gita ${day.verseId}',
                    style: gitaBody(color: kMuted, size: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Journal prompt',
            onPressed: onJournal,
            icon: const Icon(Icons.edit_note_rounded, color: kGold),
          ),
          IconButton(
            tooltip: 'Open verse',
            onPressed: onOpen,
            icon: const Icon(Icons.chevron_right_rounded, color: kGold),
          ),
        ],
      ),
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
          _DetailLine(label: 'Verse', text: 'Bhagavad Gita ${day.verseId}'),
          const SizedBox(height: 12),
          _DetailLine(label: 'Reflection', text: day.reflection),
          const SizedBox(height: 12),
          _DetailLine(label: 'Practice Today', text: day.practiceToday),
          const SizedBox(height: 12),
          _DetailLine(label: 'Journal Prompt', text: day.journalPrompt),
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

class _JourneyMiniAction extends StatelessWidget {
  const _JourneyMiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: kCard2.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kGold, size: 16),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gitaBody(
                  color: kText,
                  size: 12,
                  weight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
