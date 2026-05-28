// Reading Plans screen.
//
// Lightweight local habit support for the MVP. Plans are static data in code,
// while completed days are stored in shared_preferences through
// LocalStorageService. No backend or account is required.
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

  static const _plans = [
    _ReadingPlan(
      id: 'peace_7_days',
      title: '7 Days for Peace',
      subtitle: 'A gentle daily path for a calmer mind.',
      icon: Icons.self_improvement_rounded,
      days: [
        _PlanDay(1, 'Begin with steadiness', 'Read Gita 2.47', '2.47'),
        _PlanDay(2, 'Lift the mind', 'Read Gita 6.5', '6.5'),
        _PlanDay(3, 'Let fear soften', 'Read Gita 4.10', '4.10'),
        _PlanDay(4, 'Practice evenness', 'Read Gita 2.48', '2.48'),
        _PlanDay(5, 'Return to devotion', 'Read Gita 9.22', '9.22'),
        _PlanDay(6, 'Quiet the senses', 'Read Gita 2.58', '2.58'),
        _PlanDay(7, 'Rest in surrender', 'Read Gita 18.66', '18.66'),
      ],
    ),
    _ReadingPlan(
      id: 'discipline_gita',
      title: 'Discipline Through Gita',
      subtitle: 'Build focus through small sincere actions.',
      icon: Icons.spa_rounded,
      days: [
        _PlanDay(1, 'Choose one duty', 'Read Gita 3.8', '3.8'),
        _PlanDay(2, 'Act without delay', 'Read Gita 2.50', '2.50'),
        _PlanDay(3, 'Train the mind', 'Read Gita 6.26', '6.26'),
        _PlanDay(4, 'Keep returning', 'Read Gita 6.35', '6.35'),
        _PlanDay(5, 'Offer the work', 'Read Gita 3.30', '3.30'),
      ],
    ),
    _ReadingPlan(
      id: 'karma_yoga_basics',
      title: 'Karma Yoga Basics',
      subtitle: 'Understand action, offering, and freedom from results.',
      icon: Icons.menu_book_rounded,
      days: [
        _PlanDay(1, 'Right to action', 'Read Gita 2.47', '2.47'),
        _PlanDay(2, 'Skill in action', 'Read Gita 2.50', '2.50'),
        _PlanDay(3, 'Necessary action', 'Read Gita 3.8', '3.8'),
        _PlanDay(4, 'Work as offering', 'Read Gita 3.9', '3.9'),
        _PlanDay(5, 'Surrender action', 'Read Gita 3.30', '3.30'),
        _PlanDay(6, 'No attachment', 'Read Gita 5.10', '5.10'),
        _PlanDay(7, 'Peace through release', 'Read Gita 5.12', '5.12'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _progressFuture = LocalStorageService.readingPlanProgress();
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: ListView(
        key: const PageStorageKey('reading_plans_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          const PageHeader(
            title: 'Reading Plans',
            subtitle: 'Small daily practices saved locally',
            showBack: true,
            trailing: Icon(Icons.spa_rounded, color: kGold),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: FutureBuilder<Map<String, Set<int>>>(
              future: _progressFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingStateCard(
                    message: 'Preparing reading plans...',
                  );
                }
                final progress = snapshot.data ?? <String, Set<int>>{};
                final hasAnyProgress =
                    progress.values.any((days) => days.isNotEmpty);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PremiumCard(
                      accent: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AccentPill('Daily habit'),
                          const SizedBox(height: 16),
                          Text(
                            'A calmer rhythm with the Gita',
                            style: gitaTitle(26),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Complete one short reading at a time. Your progress stays on this device.',
                            style: gitaBody(color: kText, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!hasAnyProgress) ...[
                      const EmptyStateCard(
                        icon: Icons.spa_rounded,
                        title: 'No plan progress yet.',
                        body:
                            'Begin with one short reading. Each completed day will be saved on this device.',
                      ),
                      const SizedBox(height: 20),
                    ],
                    for (final plan in _plans) ...[
                      _ReadingPlanCard(
                        plan: plan,
                        completedDays: progress[plan.id] ?? <int>{},
                        onToggleDay: _toggleDay,
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

  Future<void> _toggleDay(
    _ReadingPlan plan,
    _PlanDay day,
    bool completed,
  ) async {
    // Toggle one day at a time and then reload the local progress Future so the
    // progress bar and day rows stay in sync.
    await LocalStorageService.setReadingPlanDayComplete(
      planId: plan.id,
      day: day.day,
      complete: !completed,
    );
    if (!mounted) {
      return;
    }
    setState(_refresh);
  }
}

class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({
    required this.plan,
    required this.completedDays,
    required this.onToggleDay,
  });

  final _ReadingPlan plan;
  final Set<int> completedDays;
  final Future<void> Function(_ReadingPlan plan, _PlanDay day, bool completed)
      onToggleDay;

  @override
  Widget build(BuildContext context) {
    final completedCount = completedDays.length;
    final progress = completedCount / plan.days.length;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconMedallion(icon: plan.icon, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: gitaBody(color: kText, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.subtitle,
                      style: gitaBody(color: kText, size: 13),
                    ),
                  ],
                ),
              ),
              AccentPill('$completedCount/${plan.days.length}'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: kLine,
              valueColor: const AlwaysStoppedAnimation<Color>(kGold),
            ),
          ),
          const SizedBox(height: 16),
          for (final day in plan.days) ...[
            _PlanDayRow(
              day: day,
              completed: completedDays.contains(day.day),
              onToggle: () => onToggleDay(
                plan,
                day,
                completedDays.contains(day.day),
              ),
              onOpenVerse: () => context.push(Uri(
                path: '/verseReaderPage',
                queryParameters: {'verseId': day.verseId},
              ).toString()),
            ),
            if (day != plan.days.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PlanDayRow extends StatelessWidget {
  const _PlanDayRow({
    required this.day,
    required this.completed,
    required this.onToggle,
    required this.onOpenVerse,
  });

  final _PlanDay day;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onOpenVerse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard2.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed
              ? kGold.withValues(alpha: 0.32)
              : kLine.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
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
              onTap: onOpenVerse,
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
                    day.subtitle,
                    style: gitaBody(color: kMuted, size: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Open verse',
            onPressed: onOpenVerse,
            icon: const Icon(Icons.chevron_right_rounded, color: kGold),
          ),
        ],
      ),
    );
  }
}

class _ReadingPlan {
  const _ReadingPlan({
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
  final List<_PlanDay> days;
}

class _PlanDay {
  const _PlanDay(this.day, this.title, this.subtitle, this.verseId);

  final int day;
  final String title;
  final String subtitle;
  final String verseId;
}
