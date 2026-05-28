// Home screen for the daily spiritual companion experience.
//
// This page intentionally prioritizes a calm daily flow over dashboard density:
// Continue Reading, Read/Ask actions, Today's Guidance, Daily Verse, recent
// reflections, and secondary tools. All state is local.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/gita_data.dart';
import '../../services/daily_companion_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/reading_progress_service.dart';
import '../gita_common/gita_common.dart';

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
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero establishes the spiritual identity without containing
                // primary CTAs; the actual daily actions stay below for clarity.
                const AnimatedEntrance(
                  child: _KrishnaHeroSection(),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Continue reading',
                  action: 'All chapters',
                  onTap: () => context.go('/chaptersPage'),
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
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 65),
                  child: _PrimaryActionCards(
                    onRead: () => context.go('/chaptersPage'),
                    onAsk: () => context.push('/askGitaPage'),
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: _TodaysGuidanceCard(
                    guidance: DailyCompanionService.todaysGuidance(),
                    onReadVerse: (guidance) {
                      _recordReflectedVerse(guidance.verseId);
                      context.push(Uri(
                        path: '/verseReaderPage',
                        queryParameters: {'verseId': guidance.verseId},
                      ).toString());
                    },
                    onJournal: (guidance) => context.push(Uri(
                      path: '/journalPage',
                      queryParameters: {
                        'prefill': guidance.journalPrompt,
                        'chapter': guidance.chapterNumber.toString(),
                      },
                    ).toString()),
                  ),
                ),
                const SizedBox(height: 28),
                FutureBuilder<GitaVerseData>(
                  // Daily Verse uses the local Gita dataset directly so it
                  // remains available offline and never blocks on a backend.
                  future: GitaRepository.dailyVerse(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingStateCard(
                        message: 'Preparing today\'s verse...',
                      );
                    }
                    final verse = snapshot.data;
                    if (snapshot.hasError || verse == null) {
                      debugPrint('Home daily verse failed: ${snapshot.error}');
                      return const ErrorStateCard(
                        message: 'Could not load today\'s verse.',
                      );
                    }
                    return AnimatedEntrance(
                      delay: const Duration(milliseconds: 96),
                      child: _CompactDailyVerseCard(
                        verse: verse,
                        onTap: () => context.push(Uri(
                          path: '/verseReaderPage',
                          queryParameters: {'verseId': verse.id},
                        ).toString()),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 248),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kNavy,
            kPeacockTeal,
            kRoyalPurple,
            kDeepBrinjal,
          ],
          stops: [0, 0.42, 0.74, 1],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: kGold.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.34),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: kRoyalPurple.withValues(alpha: 0.20),
            blurRadius: 52,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 10,
            right: 4,
            child: _KrishnaInspiredImageArea(),
          ),
          Positioned(
            top: -36,
            right: -20,
            child: Icon(
              Icons.spa_rounded,
              size: 156,
              color: kAntiqueGold.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 24,
            child: Icon(
              Icons.music_note_rounded,
              size: 124,
              color: kGold.withValues(alpha: 0.17),
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
              const SizedBox(height: 18),
              Text(
                'Welcome back.',
                style: gitaTitle(33).copyWith(
                  color: kAntiqueGold,
                  height: 1.05,
                  shadows: [
                    Shadow(
                      color: kCard.withValues(alpha: 0.72),
                      blurRadius: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'May today bring clarity and peace.',
                style: gitaBody(
                  color: kText,
                  size: 17,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KrishnaInspiredImageArea extends StatelessWidget {
  const _KrishnaInspiredImageArea();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kAntiqueGold.withValues(alpha: 0.52),
                  kGold.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 12,
            child: Transform.rotate(
              angle: -0.55,
              child: Icon(
                Icons.spa_rounded,
                size: 82,
                color: kAntiqueGold.withValues(alpha: 0.72),
              ),
            ),
          ),
          Positioned(
            top: 31,
            right: 42,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [kGold, kSoftGold, kRoyalPurple],
                ),
                border: Border.all(color: kAntiqueGold.withValues(alpha: 0.72)),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            right: 6,
            child: Transform.rotate(
              angle: -0.72,
              child: Container(
                width: 126,
                height: 10,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kAntiqueGold, kSoftGold, kGold],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: kGold.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 58,
            right: 36,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kDeepBrinjal.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: 20,
            child: Icon(
              Icons.music_note_rounded,
              size: 58,
              color: kGold.withValues(alpha: 0.30),
            ),
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
    required this.onJournal,
  });

  final DailyGuidance guidance;
  final ValueChanged<DailyGuidance> onReadVerse;
  final ValueChanged<DailyGuidance> onJournal;

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
                Expanded(
                  child: Text(
                    'Today\'s Guidance',
                    style: gitaBody(
                      color: kRoyalPurple,
                      size: 13,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
                FutureBuilder<int>(
                  future: _streakFuture,
                  builder: (context, snapshot) {
                    final streak = snapshot.data ?? 0;
                    if (streak <= 0) {
                      return const SizedBox.shrink();
                    }
                    return AccentPill(
                      '$streak day${streak == 1 ? '' : 's'} of reflection',
                    );
                  },
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ReflectionAction(
                  icon: Icons.menu_book_rounded,
                  label: 'Read Verse',
                  onTap: () => widget.onReadVerse(guidance),
                ),
                _ReflectionAction(
                  icon: Icons.edit_note_rounded,
                  label: 'Journal Prompt',
                  onTap: () => widget.onJournal(guidance),
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
                Text(
                  'Practice Today',
                  style: gitaBody(
                    color: kRoyalPurple,
                    size: 12,
                    weight: FontWeight.w900,
                  ),
                ),
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

class _CompactDailyVerseCard extends StatelessWidget {
  const _CompactDailyVerseCard({
    required this.verse,
    required this.onTap,
  });

  final GitaVerseData verse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PurpleVerseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconMedallion(
                icon: Icons.wb_sunny_rounded,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Verse',
                      style: gitaBody(
                        color: kAntiqueGold,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      verse.reference,
                      style: gitaBody(color: kMuted, size: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kGold),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            verse.sanskrit,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: gitaSanskrit(22).copyWith(
              color: kAntiqueGold,
              height: 1.46,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kGold.withValues(alpha: 0.20)),
            ),
            child: Text(
              verse.englishTranslation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: gitaBody(
                color: kDarkText,
                size: 15,
                weight: FontWeight.w800,
              ).copyWith(height: 1.48),
            ),
          ),
        ],
      ),
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
            Text(
              label,
              style: gitaBody(
                color: kText,
                size: 12,
                weight: FontWeight.w900,
              ),
            ),
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

class _RecentlyReflectedSection extends StatelessWidget {
  const _RecentlyReflectedSection({
    required this.onOpenVerse,
    required this.onOpenTopic,
  });

  final ValueChanged<String> onOpenVerse;
  final ValueChanged<String> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    // Recent items intentionally support both exact verses and emotional topics:
    // verse items reopen Verse Reader; topic items reopen Search.
    return FutureBuilder<List<LocalReflectedItem>>(
      future: LocalStorageService.recentReflections(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done || items.isEmpty) {
          return const SizedBox.shrink();
        }
        return AnimatedEntrance(
          delay: const Duration(milliseconds: 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              const _SectionHeader(title: 'Recently Reflected On'),
              const SizedBox(height: 14),
              PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in items)
                      _ReflectedChip(
                        item: item,
                        onTap: () {
                          if (item.isVerse) {
                            onOpenVerse(item.verseId!);
                            return;
                          }
                          if (item.isTopic) {
                            onOpenTopic(item.topic!);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: kCard2.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isVerse ? Icons.menu_book_rounded : Icons.spa_rounded,
              color: kGold,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              item.label,
              style: gitaBody(
                color: kText,
                size: 12,
                weight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
          title: 'Choose your path',
        ),
        const SizedBox(height: 14),
        _ActionRow(
          actions: actions,
          highlightedIndexes: const {0, 1},
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
      ('Journal', Icons.edit_note_rounded, onJournal),
      ('Search', Icons.travel_explore_rounded, onSearch),
      ('Saved Verses', Icons.bookmark_rounded, onSaved),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'More tools'),
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
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: gitaBody(size: 19, color: kText, weight: FontWeight.w900)),
        if (action != null && onTap != null) ...[
          const Spacer(),
          TextButton(
              onPressed: onTap,
              child: Text(action!, style: gitaBody(color: kSoftGold))),
        ],
      ],
    );
  }
}
