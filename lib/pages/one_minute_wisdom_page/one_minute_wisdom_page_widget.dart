// One Minute Wisdom flow.
//
// A lightweight guided reflection: Breathe, Read, Reflect, Practice. It reuses
// Today's Guidance and local Gita data, then records completion locally for the
// gentle reflection streak. No audio or backend is required.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart';
import '../../services/daily_companion_service.dart';
import '../../services/local_storage_service.dart';
import '../gita_common/gita_common.dart' hide GitaVerse;

class OneMinuteWisdomPageWidget extends StatelessWidget {
  const OneMinuteWisdomPageWidget({super.key});

  static String routeName = 'OneMinuteWisdomPage';
  static String routePath = '/oneMinuteWisdomPage';

  @override
  Widget build(BuildContext context) {
    final guidance = DailyCompanionService.todaysGuidance();
    // Load only the single verse needed for today's guidance; this keeps the
    // flow focused and avoids introducing another state manager.
    return GitaScaffold(
      child: FutureBuilder<GitaVerse>(
        future: GitaRepository.verseByIdOrDaily(guidance.verseId),
        builder: (context, snapshot) {
          final verse = snapshot.data;
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
            children: [
              Row(
                children: [
                  AnimatedGoldIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'One Minute Wisdom',
                      style: gitaTitle(28).copyWith(color: kAntiqueGold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState != ConnectionState.done)
                const LoadingStateCard(message: 'Preparing a calm minute...')
              else if (snapshot.hasError || verse == null)
                const ErrorStateCard(
                  message: 'Could not load today\'s wisdom from local data.',
                )
              else ...[
                const _WisdomStepCard(
                  icon: Icons.self_improvement_rounded,
                  title: 'Breathe',
                  body:
                      'Pause. Take one slow breath. Let your shoulders soften before reading.',
                  accent: true,
                ),
                const SizedBox(height: 16),
                _WisdomStepCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Read',
                  label: verse.reference,
                  body: verse.englishTranslation,
                ),
                const SizedBox(height: 16),
                _WisdomStepCard(
                  icon: Icons.spa_rounded,
                  title: 'Reflect',
                  body: guidance.reflection,
                ),
                const SizedBox(height: 16),
                _WisdomStepCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Practice',
                  body: guidance.practiceToday,
                  actionLabel: 'Complete Practice',
                  onAction: () async {
                    await LocalStorageService.recordPracticeCompleted();
                    await LocalStorageService.recordReflectedVerse(verse);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Practice saved for today'),
                      ),
                    );
                    context.pop();
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WisdomStepCard extends StatelessWidget {
  const _WisdomStepCard({
    required this.icon,
    required this.title,
    required this.body,
    this.label,
    this.actionLabel,
    this.onAction,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntrance(
      child: PremiumCard(
        accent: accent,
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: kGold.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconMedallion(icon: icon, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: gitaBody(
                            color: kRoyalPurple,
                            size: 13,
                            weight: FontWeight.w900,
                          ),
                        ),
                        if (label != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            label!,
                            style: gitaBody(
                              color: kDarkText.withValues(alpha: 0.72),
                              size: 12,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: gitaBody(
                  color: kDarkText,
                  size: 16,
                  weight: FontWeight.w700,
                ).copyWith(height: 1.55),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                GoldButton(
                  label: actionLabel!,
                  icon: Icons.done_rounded,
                  onPressed: onAction!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
