/// ------------------------------------------------------------
/// HomeScreen
///
/// Purpose:
/// Main companion entry point after splash.
///
/// Responsibilities:
/// - Continue Reading from the last opened verse.
/// - Surface Today's Guidance and a practical daily action.
/// - Route users into Read Gita, Ask Gita, Journeys, Search, Journal, and Saved
///   Wisdom without creating dashboard clutter.
/// - Show local continuity such as Current Journey, Recently Reflected On, and
///   Days of Reflection.
///
/// Data sources:
/// - ReadingProgressService for Continue Reading.
/// - DailyCompanionService and PersonalizationService for Today's Guidance.
/// - LocalStorageService/JourneyService for local journey state.
///
/// Notes:
/// Home follows a companion-first design. The screen should answer one question
/// quickly: "What is the next sincere step I can take today?"
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/gita_data.dart';
import '../../services/daily_companion_service.dart';
import '../../services/journey_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/personalization_service.dart';
import '../../services/reading_progress_service.dart';
import '../gita_common/gita_common.dart';
import '../transformation_page/transformation_page_widget.dart';

void _homeDebugLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

class HomePageWidget extends StatelessWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      bottomNavIndex: 0,
      child: ListView(
        key: const PageStorageKey('home_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: gitaBottomNavScrollPadding(context)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting / companion flow:
                // The hero creates a gentle arrival moment. Primary actions
                // stay below it so Home feels like a daily companion instead
                // of a marketing page or dense dashboard.
                const AnimatedEntrance(
                  child: _KrishnaHeroSection(),
                ),
                const SizedBox(height: 24),
                // Continue Reading:
                // Restores the last verse saved by VerseReaderScreen so a
                // returning user can resume scripture reading immediately.
                const _SectionHeader(
                  title: 'Continue reading',
                ),
                const SizedBox(height: 16),
                FutureBuilder<_ContinueReadingData>(
                  future: _loadContinueReading(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingStateCard(
                        message: 'Finding your place...',
                      );
                    }
                    final data = snapshot.data;
                    if (data == null) {
                      return AnimatedEntrance(
                        delay: const Duration(milliseconds: 40),
                        child: _ContinueReadingCard.empty(
                          onTap: () => context.go('/chaptersPage'),
                        ),
                      );
                    }
                    return AnimatedEntrance(
                      delay: const Duration(milliseconds: 40),
                      child: _ContinueReadingCard(
                        data: data,
                        onTap: () {
                          context.push(Uri(
                            path: '/verseReaderPage',
                            queryParameters: {'verseId': data.verse.id},
                          ).toString());
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Read Gita / Ask Gita:
                // The two primary paths cover direct scripture reading and
                // retrieval-based guidance without sending user questions to an
                // external AI/API service.
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 65),
                  child: _PrimaryActionCards(
                    onRead: () => context.go('/chaptersPage'),
                    onAsk: () => context.push('/askGitaPage'),
                  ),
                ),
                const SizedBox(height: 24),
                // Today's Guidance:
                // The daily companion experience stays singular: one verse
                // reference, one reflection, and one practice.
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: FutureBuilder<DailyGuidance>(
                    future: PersonalizationService.personalizedTodaysGuidance(),
                    builder: (context, snapshot) {
                      final guidance = snapshot.data ??
                          DailyCompanionService.todaysGuidance();
                      return _TodaysGuidanceCard(
                        guidance: guidance,
                        onReadVerse: (guidance) {
                          _recordReflectedVerse(guidance.verseId);
                          context.push(Uri(
                            path: '/verseReaderPage',
                            queryParameters: {'verseId': guidance.verseId},
                          ).toString());
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Journeys:
                // Surfaces the active local journey after today's verse so the
                // Home flow stays content-first: resume scripture, choose a
                // path, receive guidance, then continue the guided journey.
                ValueListenableBuilder<int>(
                  valueListenable: LocalStorageService.journeyProgressRevision,
                  builder: (context, revision, _) {
                    return FutureBuilder<GitaCurrentJourney>(
                      key: ValueKey('home_journey_$revision'),
                      future: JourneyService.currentJourney(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const LoadingStateCard(
                            message: 'Preparing your journey...',
                          );
                        }
                        final journey = snapshot.data;
                        if (journey == null) {
                          return const SizedBox.shrink();
                        }
                        return AnimatedEntrance(
                          delay: const Duration(milliseconds: 100),
                          child: _HomeCurrentJourneyCard(
                            current: journey,
                            onContinue: () {
                              if (journey.isComplete) {
                                _showNextJourneyPicker(context);
                                return;
                              }
                              _continueJourneyFromHome(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                _PersonalizedRecommendationSection(
                  onOpenVerse: (verseId) => context.push(Uri(
                    path: '/verseReaderPage',
                    queryParameters: {'verseId': verseId},
                  ).toString()),
                  onOpenJourney: (journeyId) async {
                    await LocalStorageService.startJourney(journeyId);
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TransformationPageWidget(
                          initialJourneyId: journeyId,
                        ),
                      ),
                    );
                  },
                ),
                _RecentlyReflectedSection(
                  onOpenVerse: (verseId) => context.push(Uri(
                    path: '/verseReaderPage',
                    queryParameters: {'verseId': verseId},
                  ).toString()),
                  onOpenTopic: (topic) => context.go(Uri(
                    path: '/searchPage',
                    queryParameters: {'q': topic.toLowerCase()},
                  ).toString()),
                ),
                const SizedBox(height: 28),
                // Secondary actions:
                // Keeps useful Bible-app-level tools accessible while avoiding
                // social feeds, profiles, comments, or other noisy surfaces.
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 150),
                  child: _SecondaryActionCards(
                    onSearch: () => context.go('/searchPage'),
                    onJournal: () => context.go('/journalPage'),
                    onSaved: () => context.push('/savedVersesPage'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KrishnaHeroSection extends StatelessWidget {
  const _KrishnaHeroSection();

  String _timeAwareGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 17) {
      return 'Reflect gently on what brought peace today.';
    }
    return 'May today bring clarity and steadiness.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kNavy,
            kPeacockTeal,
            kDeepBrinjal,
          ],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kGold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -34,
            right: -28,
            child: Icon(
              Icons.spa_rounded,
              size: 132,
              color: kAntiqueGold.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: kAntiqueGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: kGold.withValues(alpha: 0.22)),
                ),
                child: Text(
                  'Gita Wisdom',
                  style: gitaBody(
                    color: kAntiqueGold,
                    size: 12,
                    weight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back.',
                style: gitaTitle(27).copyWith(
                  color: kAntiqueGold,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: kCard.withValues(alpha: 0.72),
                      blurRadius: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _timeAwareGreeting(),
                style: gitaBody(
                  color: kText,
                  size: 16,
                  weight: FontWeight.w800,
                ).copyWith(height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _recordReflectedVerse(String verseId) async {
  try {
    final verse = await GitaRepository.verseById(verseId);
    if (verse != null) {
      await LocalStorageService.recordReflectedVerse(verse);
    }
  } catch (error, stackTrace) {
    debugPrint('Record reflected verse failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<_ContinueReadingData> _loadContinueReading() async {
  final bundle = await GitaDataService.load();
  final progress = await ReadingProgressService.load();
  final verse = progress == null ? null : bundle.verseById(progress.verseId);
  if (verse == null) {
    final fallback = bundle.verseById(GitaRepository.dailyVerseId) ??
        (bundle.verses.isEmpty ? null : bundle.verses.first);
    if (fallback == null) {
      throw StateError('No verses available for Continue Reading.');
    }
    final chapter = bundle.chapterByNumber(fallback.chapterNumber);
    return _ContinueReadingData(
      verse: fallback,
      chapter: chapter,
      progressValue: 0,
      hasSavedProgress: false,
      savedAt: null,
    );
  }
  final chapter = bundle.chapterByNumber(verse.chapterNumber);
  return _ContinueReadingData(
    verse: verse,
    chapter: chapter,
    progressValue: _progressValue(verse, bundle),
    hasSavedProgress: true,
    savedAt: progress!.savedAt,
  );
}

double _progressValue(GitaVerseData verse, GitaDataBundle bundle) {
  final chapterVerses = bundle.chapterVerses(verse.chapterNumber);
  if (chapterVerses.isEmpty) {
    return 0;
  }
  final index = chapterVerses.indexWhere((item) => item.id == verse.id);
  if (index < 0) {
    return 0;
  }
  return ((index + 1) / chapterVerses.length).clamp(0.0, 1.0);
}

class _TodaysGuidanceCard extends StatefulWidget {
  const _TodaysGuidanceCard({
    required this.guidance,
    required this.onReadVerse,
  });

  final DailyGuidance guidance;
  final ValueChanged<DailyGuidance> onReadVerse;

  @override
  State<_TodaysGuidanceCard> createState() => _TodaysGuidanceCardState();
}

class _TodaysGuidanceCardState extends State<_TodaysGuidanceCard> {
  late Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _streakFuture = _recordAndLoadStreak();
  }

  Future<int> _recordAndLoadStreak() async {
    // Viewing Today's Guidance counts as a gentle reflection day. Completing
    // Practice Today also writes the same date, so the streak remains one entry
    // per day.
    await LocalStorageService.recordDailyGuidanceOpened();
    return LocalStorageService.reflectionStreak();
  }

  @override
  Widget build(BuildContext context) {
    final guidance = widget.guidance;
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kGold.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.12),
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
                const Icon(Icons.wb_sunny_rounded, color: kGold, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _GoldHighlightLabel('Today\'s Guidance'),
                  ),
                ),
                Flexible(
                  child: FutureBuilder<int>(
                    future: _streakFuture,
                    builder: (context, snapshot) {
                      final streak = snapshot.data ?? 0;
                      if (streak <= 0) {
                        return const Align(
                          alignment: Alignment.centerRight,
                          child: AccentPill('Begin again gently'),
                        );
                      }
                      return Align(
                        alignment: Alignment.centerRight,
                        child: AccentPill(
                          '$streak Day${streak == 1 ? '' : 's'} of Reflection',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              guidance.reference,
              style: gitaTitle(22).copyWith(
                color: kDarkText,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              guidance.reflection,
              style: gitaBody(
                color: kDarkText.withValues(alpha: 0.86),
                size: 16,
                weight: FontWeight.w800,
              ).copyWith(height: 1.48),
            ),
            const SizedBox(height: 16),
            _PracticeTodayBox(text: guidance.practiceToday),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kRoyalPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGold.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_note_rounded,
                      color: kRoyalPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      guidance.journalPrompt,
                      style: gitaBody(
                        color: kDarkText,
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'One sincere step is enough today.',
              style: gitaTransliteration(
                size: 14,
                color: kRoyalPurple.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ReflectionAction(
                  icon: Icons.menu_book_rounded,
                  label: 'Read Verse',
                  onTap: () => widget.onReadVerse(guidance),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeTodayBox extends StatelessWidget {
  const _PracticeTodayBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGold.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.self_improvement_rounded,
              color: kRoyalPurple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GoldHighlightLabel('Practice Today'),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: gitaBody(
                    color: kDarkText,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldHighlightLabel extends StatelessWidget {
  const _GoldHighlightLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kGold,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: gitaBody(
          color: kDarkText,
          size: 12,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PersonalizedRecommendationSection extends StatelessWidget {
  const _PersonalizedRecommendationSection({
    required this.onOpenVerse,
    required this.onOpenJourney,
  });

  final ValueChanged<String> onOpenVerse;
  final Future<void> Function(String journeyId) onOpenJourney;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PersonalizedRecommendation>>(
      future: PersonalizationService.recommendations(limit: 1),
      builder: (context, snapshot) {
        final recommendations = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done ||
            recommendations.isEmpty) {
          return const SizedBox.shrink();
        }
        final item = recommendations.first;
        return AnimatedEntrance(
          delay: const Duration(milliseconds: 116),
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Recommended For You'),
                const SizedBox(height: 12),
                PressableScale(
                  onTap: () {
                    final verseId = item.verseId;
                    if (verseId != null) {
                      onOpenVerse(verseId);
                      return;
                    }
                    final journeyId = item.journeyId;
                    if (journeyId != null) {
                      onOpenJourney(journeyId);
                    }
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kCard2.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: kGold.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconMedallion(
                          icon: item.opensJourney
                              ? Icons.route_rounded
                              : Icons.auto_stories_rounded,
                          size: 42,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.reason,
                                style: gitaBody(
                                  color: kSoftGold,
                                  size: 12,
                                  weight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.title,
                                style: gitaBody(
                                  color: kText,
                                  size: 17,
                                  weight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: gitaBody(
                                  color: kMuted,
                                  size: 13,
                                  weight: FontWeight.w700,
                                ).copyWith(height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: kGold,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReflectionAction extends StatelessWidget {
  const _ReflectionAction({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kRoyalPurple,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.34)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kSoftGold, size: 16),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
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

class _RecentlyReflectedSection extends StatelessWidget {
  const _RecentlyReflectedSection({
    required this.onOpenVerse,
    required this.onOpenTopic,
  });

  final ValueChanged<String> onOpenVerse;
  final ValueChanged<String> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LocalReflectedItem>>(
      future: LocalStorageService.recentReflections(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done || items.isEmpty) {
          return const SizedBox.shrink();
        }
        return AnimatedEntrance(
          delay: const Duration(milliseconds: 96),
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Recently Reflected On'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items.take(4))
                      _ReflectedChip(
                        item: item,
                        onTap: () {
                          if (item.isVerse && item.verseId != null) {
                            onOpenVerse(item.verseId!);
                            return;
                          }
                          if (item.isTopic && item.topic != null) {
                            onOpenTopic(item.topic!);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReflectedChip extends StatelessWidget {
  const _ReflectedChip({
    required this.item,
    required this.onTap,
  });

  final LocalReflectedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: kCard2.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isVerse ? Icons.menu_book_rounded : Icons.spa_rounded,
              color: kGold,
              size: 15,
            ),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                item.label,
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

Future<void> _continueJourneyFromHome(BuildContext context) async {
  _homeDebugLog('continueJourney tapped');
  final currentJourneyId = await LocalStorageService.currentJourneyId();
  _homeDebugLog('currentJourneyId value: ${currentJourneyId ?? 'none'}');

  var journeyId = currentJourneyId;
  if (journeyId == null || journeyId.isEmpty) {
    // Fresh installs use the calm default journey immediately, so Continue
    // Journey never falls back to Home or asks the user to recover context.
    journeyId = 'journey_peace_7';
    _homeDebugLog('no journey found → starting default journey $journeyId');
    await LocalStorageService.startJourney(journeyId);
    _homeDebugLog('selected journey saved: $journeyId');
  }

  final day = await LocalStorageService.currentJourneyDay();
  _homeDebugLog('opening day number: $day');
  if (!context.mounted) {
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TransformationPageWidget(initialJourneyId: journeyId),
    ),
  );
}

Future<void> _showNextJourneyPicker(BuildContext context) async {
  _homeDebugLog('StartNextJourney tapped');
  final journeys = JourneyService.recommendedAfterCompletion();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _HomeNextJourneySheet(
      journeys: journeys,
      onSelect: (journey) => _startNextJourneyFromHome(
        parentContext: context,
        sheetContext: sheetContext,
        journey: journey,
      ),
    ),
  );
}

Future<void> _startNextJourneyFromHome({
  required BuildContext parentContext,
  required BuildContext sheetContext,
  required GitaJourneySummary journey,
}) async {
  _homeDebugLog('selected journey id ${journey.id}');
  await LocalStorageService.startJourney(journey.id);
  _homeDebugLog('navigation target JourneyDay ${journey.id} day 1');
  if (!parentContext.mounted || !sheetContext.mounted) {
    return;
  }
  Navigator.of(sheetContext).pop();
  ScaffoldMessenger.of(parentContext).showSnackBar(
    SnackBar(
      content: Text(
        'Journey started',
        style: gitaBody(color: kText, weight: FontWeight.w800),
      ),
      backgroundColor: kRoyalPurple,
      behavior: SnackBarBehavior.floating,
    ),
  );
  Navigator.of(parentContext).push(
    MaterialPageRoute<void>(
      builder: (_) => TransformationPageWidget(
        initialJourneyId: journey.id,
      ),
    ),
  );
}

class _HomeNextJourneySheet extends StatelessWidget {
  const _HomeNextJourneySheet({
    required this.journeys,
    required this.onSelect,
  });

  final List<GitaJourneySummary> journeys;
  final Future<void> Function(GitaJourneySummary journey) onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: kGold.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AccentPill('Choose Your Next Journey'),
            const SizedBox(height: 14),
            Text(
              'Begin gently with a path that fits this season.',
              style: gitaBody(color: kMuted, size: 13).copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            for (final journey in journeys) ...[
              PressableScale(
                onTap: () => onSelect(journey),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  key: ValueKey('home_next_journey_${journey.id}'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCream,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: kGold.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const IconMedallion(
                        icon: Icons.route_rounded,
                        size: 38,
                      ),
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
                            const SizedBox(height: 4),
                            Text(
                              '${journey.totalDays} days',
                              style: gitaBody(
                                color: kDarkText.withValues(alpha: 0.66),
                                size: 12,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: kGold,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (journey != journeys.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingData {
  const _ContinueReadingData({
    required this.verse,
    required this.chapter,
    required this.progressValue,
    required this.hasSavedProgress,
    required this.savedAt,
  });

  final GitaVerseData verse;
  final GitaChapterData? chapter;
  final double progressValue;
  final bool hasSavedProgress;
  final DateTime? savedAt;

  bool get wasReadToday {
    final value = savedAt;
    if (value == null || !hasSavedProgress) {
      return false;
    }
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.data,
    required this.onTap,
  });

  const _ContinueReadingCard.empty({
    required this.onTap,
  }) : data = null;

  final _ContinueReadingData? data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = data;
    final chapterTitle = current?.chapter?.title ?? 'Begin the Gita';
    final hasProgress = current != null && current.hasSavedProgress;
    final subtitle = hasProgress
        ? 'Chapter ${current.verse.chapterNumber} • Verse ${current.verse.verseNumber}'
        : 'Start Reading';
    final verseText = current?.verse.englishTranslation ??
        'Open the scripture reader and your last read verse will be saved here.';
    final progressValue = current?.progressValue ?? 0;
    final recencyLabel = current == null
        ? 'Your reading place will be saved automatically'
        : current.wasReadToday
            ? 'Last read today'
            : 'Last read saved on this device';

    return PremiumCard(
      accent: current != null && current.hasSavedProgress,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: kGold.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kGold, kSoftGold, kAntiqueGold],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: kDarkText,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !hasProgress
                            ? 'Begin Your Reading'
                            : 'Continue Reading',
                        style: gitaBody(
                          color: kRoyalPurple,
                          weight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapterTitle,
                        style: gitaTitle(24).copyWith(color: kDarkText),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: kRoyalPurple),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: gitaBody(
                color: kDarkText,
                size: 14,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              verseText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: gitaBody(
                size: 14,
                color: kDarkText.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: kRoyalPurple, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    current == null
                        ? recencyLabel
                        : !hasProgress
                            ? 'Begin with ${current.verse.shortReference}'
                            : '$recencyLabel • Verse ${current.verse.verseNumber} of ${current.chapter?.verseCount ?? current.verse.verseNumber}',
                    style: gitaBody(
                      size: 12,
                      color: kDarkText.withValues(alpha: 0.72),
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: kLine,
                valueColor: const AlwaysStoppedAnimation(kGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCurrentJourneyCard extends StatelessWidget {
  const _HomeCurrentJourneyCard({
    required this.current,
    required this.onContinue,
  });

  final GitaCurrentJourney current;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final journey = current.journey;
    final progress = current.completedCount / journey.totalDays;
    final isComplete = current.isComplete;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccentPill(isComplete ? 'Journey Complete' : 'Current Journey'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconMedallion(
                icon: isComplete
                    ? Icons.check_circle_rounded
                    : Icons.route_rounded,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      style: gitaBody(
                        color: kText,
                        size: 17,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isComplete
                          ? 'You completed ${journey.title}.'
                          : 'Day ${current.nextDay} of ${journey.totalDays}',
                      style: gitaBody(
                        color: kAntiqueGold,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      journey.subtitle,
                      style: gitaBody(color: kMuted, size: 13),
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isComplete
                      ? current.progressLabel
                      : '${current.completedCount} Days of Reflection',
                  style: gitaBody(
                    color: kMuted,
                    size: 13,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onContinue,
                icon: Icon(
                  isComplete
                      ? Icons.verified_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(
                  isComplete ? 'Start Next Journey' : 'Continue Journey',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: kGold,
                  textStyle: gitaBody(size: 13, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (isComplete) ...[
            const SizedBox(height: 12),
            Text(
              'What insight will you carry forward?',
              style: gitaBody(
                color: kText,
                size: 14,
                weight: FontWeight.w700,
              ).copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            Text(
              'Recommended next journeys',
              style: gitaBody(
                color: kMuted,
                size: 13,
                weight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final journey
                    in JourneyService.recommendedAfterCompletion())
                  AccentPill(journey.title),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionCards extends StatelessWidget {
  const _PrimaryActionCards({
    required this.onRead,
    required this.onAsk,
  });

  final VoidCallback onRead;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Read Gita', Icons.menu_book_rounded, onRead),
      ('Ask Gita', Icons.music_note_rounded, onAsk),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Read or Ask',
        ),
        const SizedBox(height: 14),
        _ActionRow(
          actions: actions,
          highlightedIndexes: const {},
        ),
      ],
    );
  }
}

class _SecondaryActionCards extends StatelessWidget {
  const _SecondaryActionCards({
    required this.onSearch,
    required this.onJournal,
    required this.onSaved,
  });

  final VoidCallback onSearch;
  final VoidCallback onJournal;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Search', Icons.travel_explore_rounded, onSearch),
      ('Journal', Icons.edit_note_rounded, onJournal),
      ('Saved Wisdom', Icons.bookmark_rounded, onSaved),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Keep Reflecting'),
        const SizedBox(height: 14),
        _ActionRow(
          actions: actions,
          highlightedIndexes: const {},
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.actions,
    required this.highlightedIndexes,
  });

  final List<(String, IconData, VoidCallback)> actions;
  final Set<int> highlightedIndexes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final useThreeColumns =
            actions.length == 3 && constraints.maxWidth >= 520;
        final columns = useThreeColumns ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < actions.length; i++)
              SizedBox(
                width: !useThreeColumns &&
                        actions.length.isOdd &&
                        i == actions.length - 1
                    ? constraints.maxWidth
                    : itemWidth,
                child: _GlowQuickButton(
                  label: actions[i].$1,
                  icon: actions[i].$2,
                  onTap: actions[i].$3,
                  highlighted: highlightedIndexes.contains(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GlowQuickButton extends StatelessWidget {
  const _GlowQuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.965,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 92,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: highlighted
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kRoyalPurple,
                    kCard2,
                    kDeepBrinjal,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kCard,
                    kCard2,
                    kAntiqueGold.withValues(alpha: 0.14),
                  ],
                ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: highlighted
                ? kGold.withValues(alpha: 0.58)
                : kGold.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: highlighted ? 0.28 : 0.16),
              blurRadius: highlighted ? 32 : 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: kRoyalPurple.withValues(alpha: highlighted ? 0.16 : 0.05),
              blurRadius: highlighted ? 28 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _GoldenQuickIcon(
              icon: icon,
              selected: highlighted,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gitaBody(
                  color: highlighted ? kAntiqueGold : kText,
                  size: 15,
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

class _GoldenQuickIcon extends StatelessWidget {
  const _GoldenQuickIcon({
    required this.icon,
    required this.selected,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? const [
                  kGold,
                  kSoftGold,
                  kAntiqueGold,
                ]
              : [
                  kCard.withValues(alpha: 0.98),
                  kCard2.withValues(alpha: 0.88),
                  kRoyalPurple.withValues(alpha: 0.64),
                ],
        ),
        border: Border.all(
          color: selected
              ? kAntiqueGold.withValues(alpha: 0.92)
              : kGold.withValues(alpha: 0.34),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: selected ? 0.42 : 0.20),
            blurRadius: selected ? 28 : 18,
            spreadRadius: selected ? 1 : 0,
            offset: const Offset(0, 8),
          ),
          if (selected)
            BoxShadow(
              color: kAntiqueGold.withValues(alpha: 0.28),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: selected ? 1.07 : 1,
        child: Icon(
          icon,
          color: selected ? kRoyalPurple : kGold,
          size: selected ? 27 : 25,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: gitaBody(size: 19, color: kText, weight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
