/// ------------------------------------------------------------
/// VerseReaderScreen
///
/// Purpose:
/// Premium scripture reader for one Bhagavad Gita verse at a time.
///
/// Responsibilities:
/// - Load a verse from local JSON by verseId or chapter query parameters.
/// - Present content in the devotional reading order:
///   Sanskrit -> Transliteration -> Translation -> Gita Wisdom Interpretation
///   -> Reflection -> Practice Today.
/// - Keep Save, Share, Play/Pause, Highlight, Previous, and Next secondary to
///   the verse itself.
/// - Preserve Journey context with a compact Back to Journey row when opened
///   from a guided path.
/// - Record Continue Reading and local reflection activity.
///
/// Data sources:
/// - GitaRepository for Sanskrit, transliteration, translation, and reviewed
///   interpretation/reflection/practice content.
/// - ReflectionService for optional verse-level reflection overrides.
/// - LocalStorageService and ReadingProgressService for saved state.
///
/// Notes:
/// Reading experience is prioritized over controls. Audio is lazy-loaded only
/// after the user taps Play; missing audio is handled silently because audio
/// should enhance reading, never block it.
///
/// TODO(full-audio-library): When licensed recitations are ready, keep lazy
/// loading and expand the asset pack with the existing chapter_verse convention.
/// ------------------------------------------------------------
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/gita_data.dart';
import '../../services/local_storage_service.dart';
import '../../services/personalization_service.dart';
import '../../services/reading_progress_service.dart';
import '../../services/reflection_service.dart';
import '../gita_common/gita_common.dart';

void _readerDebugLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

class VerseReaderPageWidget extends StatefulWidget {
  const VerseReaderPageWidget({
    super.key,
    this.verseId,
    this.journeyId,
    this.journeyName,
    this.journeyDay,
    this.journeyTotalDays,
    this.journeyDayTitle,
    this.nextJourneyDayTitle,
  });

  static String routeName = 'VerseReaderPage';
  static String routePath = '/verseReaderPage';

  final String? verseId;
  final String? journeyId;
  final String? journeyName;
  final int? journeyDay;
  final int? journeyTotalDays;
  final String? journeyDayTitle;
  final String? nextJourneyDayTitle;

  bool get hasJourneyContext =>
      journeyId != null &&
      journeyName != null &&
      journeyDay != null &&
      journeyTotalDays != null;

  @override
  State<VerseReaderPageWidget> createState() => _VerseReaderPageWidgetState();
}

class _VerseReaderPageWidgetState extends State<VerseReaderPageWidget> {
  late final Future<GitaDataBundle> _bundleFuture;
  PageController? _pageController;
  int? _currentIndex;
  int? _currentChapterNumber;
  double _fontSize = 1;
  bool _showSanskrit = true;
  bool _showTransliteration = true;
  bool _isFocusMode = false;
  bool _isSaving = false;
  bool _isHighlighting = false;
  String? _lastSavedProgressVerseId;
  AudioPlayer? _verseAudioPlayer;
  StreamSubscription<PlayerState>? _verseAudioPlayerStateSubscription;
  String? _selectedAudioVerseId;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    // Cache the bundle Future for this screen instance. Page swipes should not
    // reparse JSON or recreate chapter lists.
    _bundleFuture = GitaDataService.load();
    unawaited(_loadReaderSettings());
    if (widget.hasJourneyContext) {
      unawaited(LocalStorageService.setCurrentJourneyDay(
        journeyId: widget.journeyId!,
        day: widget.journeyDay!,
      ));
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    unawaited(_verseAudioPlayerStateSubscription?.cancel());
    unawaited(_verseAudioPlayer?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: FutureBuilder<GitaDataBundle>(
        // Verse loading:
        // The whole local dataset is loaded once for this screen instance so
        // swipe navigation can move between verses without reparsing JSON.
        future: _bundleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: LoadingStateCard(message: 'Opening verse reader...'),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.verses.isEmpty) {
            debugPrint('Verse reader load failed: ${snapshot.error}');
            return ListView(
              children: const [
                PageHeader(
                  title: 'Verse',
                  subtitle: 'Bhagavad Gita',
                  showBack: true,
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: ErrorStateCard(
                    message:
                        'This verse is resting for a moment. Please try again.',
                  ),
                ),
              ],
            );
          }

          final bundle = snapshot.data!;
          final initialVerse = _initialVerse(bundle, widget.verseId);
          _currentChapterNumber ??= initialVerse.chapterNumber;
          final chapterVerses = bundle.chapterVerses(_currentChapterNumber!);
          if (chapterVerses.isEmpty) {
            return ListView(
              children: const [
                PageHeader(
                  title: 'Verse',
                  subtitle: 'Bhagavad Gita',
                  showBack: true,
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: ErrorStateCard(
                    message:
                        'Verses for this chapter are not available right now.',
                  ),
                ),
              ],
            );
          }
          final initialIndex = _currentIndex ??
              chapterVerses.indexWhere((verse) => verse.id == initialVerse.id);
          _currentIndex ??= initialIndex >= 0 ? initialIndex : 0;
          _pageController ??= PageController(initialPage: _currentIndex!);
          final currentVerse = chapterVerses[_currentIndex!];
          unawaited(_saveReadingProgress(currentVerse));
          final currentChapter =
              bundle.chapterByNumber(currentVerse.chapterNumber);
          final isLastVerse = _currentIndex! == chapterVerses.length - 1;
          final isFinalChapter = currentVerse.chapterNumber == 18;

          return SafeArea(
            top: false,
            child: Column(
              children: [
                _ReaderTopBar(
                  title: currentChapter == null
                      ? 'Chapter ${currentVerse.chapterNumber}'
                      : 'Chapter ${currentChapter.chapterNumber}: ${currentChapter.title}',
                ),
                if (widget.hasJourneyContext)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: _JourneyReaderRow(
                      journeyName: widget.journeyName!,
                      journeyDay: widget.journeyDay!,
                      totalDays: widget.journeyTotalDays!,
                      onBackToJourney: _backToJourney,
                    ),
                  ),
                Expanded(
                  child: PageView.builder(
                    // Previous / next navigation:
                    // PageView owns horizontal verse movement while the fixed
                    // bottom controls call the same controller for button users.
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: chapterVerses.length,
                    onPageChanged: (index) {
                      final verse = chapterVerses[index];
                      setState(() {
                        _currentIndex = index;
                      });
                      // Each verse owns its audio state. Moving to another
                      // verse stops playback and resets the compact Play button.
                      unawaited(_resetVerseAudio());
                      unawaited(_saveReadingProgress(verse));
                    },
                    itemBuilder: (context, index) {
                      final verse = chapterVerses[index];
                      final pageBottomPadding = gitaFixedControlsScrollPadding(
                        context,
                        controlsHeight:
                            index == chapterVerses.length - 1 ? 300 : 110,
                      );
                      return SingleChildScrollView(
                        // Scroll padding keeps Translation, Gita Wisdom
                        // Interpretation, Reflection, and Practice Today clear
                        // of fixed navigation controls.
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          pageBottomPadding,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedEntrance(
                              child: FutureBuilder<bool>(
                                future: LocalStorageService.isVerseHighlighted(
                                  verse.id,
                                ),
                                builder: (context, highlightSnapshot) {
                                  return _VerseContentCard(
                                    // Sanskrit / transliteration / translation
                                    // layout is centralized in this card. It
                                    // receives reader preferences and action
                                    // callbacks but does not load data itself.
                                    verse: verse,
                                    currentIndex: index,
                                    totalVerses: chapterVerses.length,
                                    fontSize: _fontSize,
                                    showSanskrit: _showSanskrit,
                                    showTransliteration: _showTransliteration,
                                    isFocusMode: _isFocusMode,
                                    isHighlighted:
                                        highlightSnapshot.data ?? false,
                                    isSavedBusy: _isSaving,
                                    isHighlightBusy: _isHighlighting,
                                    onSavingChanged: (value) =>
                                        setState(() => _isSaving = value),
                                    onHighlightingChanged: (value) =>
                                        setState(() => _isHighlighting = value),
                                    onShare: () => _shareVerse(verse),
                                    player: _verseAudioPlayer,
                                    selectedAudioVerseId: _selectedAudioVerseId,
                                    isAudioLoading: _isAudioLoading,
                                    onAudioToggle: () =>
                                        _toggleVerseAudio(verse),
                                    onFocusModeChanged: (value) =>
                                        setState(() => _isFocusMode = value),
                                    onFontSizeChanged: _setFontSize,
                                    onSanskritChanged: (value) {
                                      setState(() => _showSanskrit = value);
                                      unawaited(
                                        LocalStorageService
                                            .setReaderShowSanskrit(value),
                                      );
                                    },
                                    onTransliterationChanged: (value) {
                                      setState(
                                        () => _showTransliteration = value,
                                      );
                                      unawaited(
                                        LocalStorageService
                                            .setReaderShowTransliteration(
                                          value,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fixed previous/next controls remain outside the scroll
                      // view. The page content reserves bottom padding so the
                      // last card is never hidden behind them.
                      _VerseNavigationBar(
                        canGoPrevious: _currentIndex! > 0,
                        canGoNext: _currentIndex! < chapterVerses.length - 1,
                        onPrevious: _goToPreviousVerse,
                        onNext: _goToNextVerse,
                      ),
                      if (isLastVerse) ...[
                        const SizedBox(height: 10),
                        _FixedCompletionActions(
                          chapterNumber: currentVerse.chapterNumber,
                          isFinalChapter: isFinalChapter,
                          onPrimary: isFinalChapter
                              ? () => _openAskGitaForChapter(
                                    currentVerse.chapterNumber,
                                    isFinal: true,
                                  )
                              : () => _openNextChapter(
                                    currentVerse.chapterNumber,
                                  ),
                          onReviewChapter: _reviewCurrentChapter,
                          onBackToChapters: () => context.go('/chaptersPage'),
                          onJournalReflection: () => _openJournalForChapter(
                            currentVerse.chapterNumber,
                            isFinal: isFinalChapter,
                          ),
                          onAskGita: () => _openAskGitaForChapter(
                            currentVerse.chapterNumber,
                            isFinal: isFinalChapter,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  GitaVerseData _initialVerse(GitaDataBundle bundle, String? verseId) {
    if (verseId != null) {
      final verse = bundle.verseById(verseId);
      if (verse != null) {
        return verse;
      }
    }
    final fallbackVerse = _firstVerseOrNull(bundle.verses);
    if (fallbackVerse == null) {
      throw StateError('No Bhagavad Gita verses are loaded.');
    }
    return bundle.verseById(GitaRepository.dailyVerseId) ?? fallbackVerse;
  }

  Future<void> _loadReaderSettings() async {
    final fontScale = await LocalStorageService.readerFontScale();
    final showSanskrit = await LocalStorageService.readerShowSanskrit();
    final showTransliteration =
        await LocalStorageService.readerShowTransliteration();
    if (!mounted) {
      return;
    }
    setState(() {
      _fontSize = fontScale;
      _showSanskrit = showSanskrit;
      _showTransliteration = showTransliteration;
    });
  }

  void _setFontSize(double value) {
    setState(() => _fontSize = value);
    unawaited(LocalStorageService.setReaderFontScale(value));
  }

  Future<void> _backToJourney() async {
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      context.go('/transformationPage');
    }
  }

  void _goToPreviousVerse() {
    final controller = _pageController;
    if (controller == null || (_currentIndex ?? 0) <= 0) {
      return;
    }
    HapticFeedback.selectionClick();
    // Reset before the page animation so audio never continues under the next
    // verse.
    unawaited(_resetVerseAudio());
    controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNextVerse() {
    final controller = _pageController;
    if (controller == null) {
      return;
    }
    HapticFeedback.selectionClick();
    unawaited(_resetVerseAudio());
    controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _openNextChapter(int chapterNumber) {
    final nextChapter = chapterNumber + 1;
    _openChapterAtFirstVerse(nextChapter);
  }

  void _openChapterAtFirstVerse(int chapterNumber) {
    _pageController?.dispose();
    unawaited(_resetVerseAudio());
    setState(() {
      _currentChapterNumber = chapterNumber;
      _currentIndex = 0;
      _pageController = PageController();
    });
  }

  Future<void> _saveReadingProgress(GitaVerseData verse) async {
    if (_lastSavedProgressVerseId == verse.id) {
      return;
    }
    // Save only when the verse changes. This keeps Continue Reading accurate
    // without writing to shared_preferences on every rebuild.
    _lastSavedProgressVerseId = verse.id;
    await ReadingProgressService.saveVerse(verse);
    await LocalStorageService.recordVerseReadForReflection();
    await LocalStorageService.recordRecentVerse(verse);
  }

  AudioPlayer _audioPlayer() {
    final existing = _verseAudioPlayer;
    if (existing != null) {
      return existing;
    }
    final player = AudioPlayer();
    _verseAudioPlayer = player;
    // just_audio exposes both playback and processing state. The UI derives
    // spinner/play/pause from this stream so loading cannot get stuck.
    _verseAudioPlayerStateSubscription = player.playerStateStream.listen(
      (state) {
        _readerDebugLog(
          'VerseAudio: playerState changed playing=${state.playing}, processing=${state.processingState.name}',
        );
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() {});
        }
      },
    );
    return player;
  }

  Future<void> _toggleVerseAudio(GitaVerseData verse) async {
    final assetPath = _verseAudioAssetPath(verse);
    final hasAudio = await _verseAudioAssetExists(assetPath);
    if (!hasAudio) {
      return;
    }

    final player = _audioPlayer();
    final isSameAudioVerse = _selectedAudioVerseId == verse.id;
    final state = player.playerState.processingState;

    if (isSameAudioVerse && player.playing) {
      // Pause must remain responsive even while the progress stream is active.
      _readerDebugLog('VerseAudio: pause tapped ${verse.reference}');
      HapticFeedback.selectionClick();
      await player.pause();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (isSameAudioVerse && !player.playing && !_isAudioLoading) {
      // Replaying the same verse should never rebuild the reading layout or
      // reload the asset; seek to the beginning only after a completed play.
      if (state == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      _readerDebugLog('VerseAudio: play start ${verse.reference}');
      HapticFeedback.selectionClick();
      unawaited(player.play());
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _readerDebugLog('VerseAudio: loading start $assetPath');
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAudioVerseId = verse.id;
      _isAudioLoading = true;
    });

    try {
      // Audio assets are optional. setAsset happens only after the Play tap and
      // stays inside try/catch so missing verse files show a gentle message
      // instead of crashing or blocking scripture reading.
      await player.stop();
      await player.setAsset(assetPath);
      _readerDebugLog('VerseAudio: setAsset complete $assetPath');
      if (mounted) {
        setState(() => _isAudioLoading = false);
      }
      _readerDebugLog('VerseAudio: play start ${verse.reference}');
      unawaited(
        player.play().catchError((Object error, StackTrace stackTrace) {
          debugPrint('VerseAudio: play failed for $assetPath: $error');
          debugPrintStack(stackTrace: stackTrace);
        }),
      );
    } catch (error, stackTrace) {
      debugPrint('Verse audio load failed for $assetPath: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _selectedAudioVerseId = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAudioLoading = false);
      }
    }
  }

  Future<void> _resetVerseAudio() async {
    final player = _verseAudioPlayer;
    if (player != null) {
      try {
        await player.stop();
        await player.seek(Duration.zero);
      } catch (error) {
        debugPrint('Verse audio reset failed: $error');
      }
    }
    if (mounted) {
      setState(() {
        _selectedAudioVerseId = null;
        _isAudioLoading = false;
      });
    }
  }

  void _reviewCurrentChapter() {
    final controller = _pageController;
    if (controller == null) {
      return;
    }
    controller.animateToPage(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openAskGitaForChapter(
    int chapterNumber, {
    required bool isFinal,
  }) {
    final uri = Uri(
      path: '/askGitaPage',
      queryParameters: {
        'chapter': chapterNumber.toString(),
        'context': isFinal
            ? 'Completed the Bhagavad Gita'
            : 'Bhagavad Gita Chapter $chapterNumber',
        'initialQuestion': isFinal
            ? 'Please summarize the Bhagavad Gita journey and give me a final reflection.'
            : 'What should I reflect on from Bhagavad Gita Chapter $chapterNumber?',
      },
    );
    context.push(uri.toString());
  }

  void _openJournalForChapter(
    int chapterNumber, {
    required bool isFinal,
  }) {
    final uri = Uri(
      path: '/journalPage',
      queryParameters: {
        'chapter': chapterNumber.toString(),
        'prefill': isFinal
            ? 'Final reflection on completing the Bhagavad Gita'
            : 'Reflection on Bhagavad Gita Chapter $chapterNumber',
      },
    );
    context.push(uri.toString());
  }

  Future<void> _shareVerse(GitaVerseData verse) async {
    final matchedReflection = await ReflectionService.reflectionForVerse(
      chapterNumber: verse.chapterNumber,
      verseNumber: verse.verseNumber,
    );
    final reflectionText = _effectiveReflectionText(verse, matchedReflection);
    final text = [
      verse.reference,
      '',
      verse.englishTranslation,
      if (reflectionText.isNotEmpty) ...[
        '',
        'Reflection:',
        reflectionText,
      ],
    ].where((line) => line.trim().isNotEmpty).join('\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: verse.reference,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Share verse failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Could not prepare sharing. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kCard,
          content: Text(message),
        ),
      );
  }
}

GitaVerseData? _firstVerseOrNull(Iterable<GitaVerseData> verses) {
  for (final verse in verses) {
    return verse;
  }
  return null;
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          AnimatedGoldIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            backgroundColor: kCard2,
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/homePage'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gitaTitle(18).copyWith(
                color: kAntiqueGold,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyReaderRow extends StatelessWidget {
  const _JourneyReaderRow({
    required this.journeyName,
    required this.journeyDay,
    required this.totalDays,
    required this.onBackToJourney,
  });

  final String journeyName;
  final int journeyDay;
  final int totalDays;
  final VoidCallback onBackToJourney;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onBackToJourney,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_rounded, color: kGold, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$journeyName • Day $journeyDay of $totalDays',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(
                    color: kAntiqueGold,
                    size: 13,
                    weight: FontWeight.w900,
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

class _ReaderControls extends StatelessWidget {
  const _ReaderControls({
    required this.fontSize,
    required this.showSanskrit,
    required this.showTransliteration,
    required this.onFontSizeChanged,
    required this.onSanskritChanged,
    required this.onTransliterationChanged,
  });

  final double fontSize;
  final bool showSanskrit;
  final bool showTransliteration;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onSanskritChanged;
  final ValueChanged<bool> onTransliterationChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.format_size_rounded, color: kGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reader settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(color: kText, weight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              AccentPill('${(fontSize * 100).round()}%'),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kGold,
              inactiveTrackColor: kGold.withValues(alpha: 0.16),
              thumbColor: kSaffron,
              overlayColor: kSaffron.withValues(alpha: 0.14),
            ),
            child: Slider(
              value: fontSize,
              min: 0.86,
              max: 1.28,
              divisions: 7,
              onChanged: onFontSizeChanged,
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ReaderToggleChip(
                label: 'Sanskrit',
                icon: Icons.language_rounded,
                selected: showSanskrit,
                onTap: () => onSanskritChanged(!showSanskrit),
              ),
              _ReaderToggleChip(
                label: 'Transliteration',
                icon: Icons.translate_rounded,
                selected: showTransliteration,
                onTap: () => onTransliterationChanged(!showTransliteration),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReaderToggleChip extends StatelessWidget {
  const _ReaderToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? kRoyalPurple.withValues(alpha: 0.94)
              : kCard2.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? kGold.withValues(alpha: 0.34)
                : kLine.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? kSoftGold : kText, size: 16),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 124),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gitaBody(
                  color: selected ? kSoftGold : kText,
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

class _VerseContentCard extends StatelessWidget {
  const _VerseContentCard({
    required this.verse,
    required this.currentIndex,
    required this.totalVerses,
    required this.fontSize,
    required this.showSanskrit,
    required this.showTransliteration,
    required this.isFocusMode,
    required this.isHighlighted,
    required this.isSavedBusy,
    required this.isHighlightBusy,
    required this.onSavingChanged,
    required this.onHighlightingChanged,
    required this.onShare,
    required this.player,
    required this.selectedAudioVerseId,
    required this.isAudioLoading,
    required this.onAudioToggle,
    required this.onFocusModeChanged,
    required this.onFontSizeChanged,
    required this.onSanskritChanged,
    required this.onTransliterationChanged,
  });

  final GitaVerseData verse;
  final int currentIndex;
  final int totalVerses;
  final double fontSize;
  final bool showSanskrit;
  final bool showTransliteration;
  final bool isFocusMode;
  final bool isHighlighted;
  final bool isSavedBusy;
  final bool isHighlightBusy;
  final ValueChanged<bool> onSavingChanged;
  final ValueChanged<bool> onHighlightingChanged;
  final VoidCallback onShare;
  final AudioPlayer? player;
  final String? selectedAudioVerseId;
  final bool isAudioLoading;
  final VoidCallback onAudioToggle;
  final ValueChanged<bool> onFocusModeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onSanskritChanged;
  final ValueChanged<bool> onTransliterationChanged;

  @override
  Widget build(BuildContext context) {
    // Layout order is deliberate: reading content comes first, then compact
    // actions, then study notes.
    final sanskrit = verse.sanskrit.trim();
    final transliteration = verse.transliteration.trim();
    final translation = verse.englishTranslation.trim();
    final interpretation = verse.gitaWisdomInterpretation;
    final progressValue =
        totalVerses <= 0 ? 0.0 : (currentIndex + 1) / totalVerses;
    final isCompactHeight = MediaQuery.sizeOf(context).height < 700;
    final sanskritSize = (isCompactHeight ? 22.0 : 28.0) * fontSize;
    final transliterationSize = (isCompactHeight ? 16.0 : 18.0) * fontSize;
    final sanskritMaxHeight = isCompactHeight ? 88.0 : 170.0;
    final transliterationMaxHeight = isCompactHeight ? 52.0 : 112.0;
    final sectionGap = isCompactHeight ? 10.0 : 16.0;
    final translationGap = isCompactHeight ? 12.0 : 18.0;
    final content = PremiumCard(
      accent: true,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        key: ValueKey('${verse.id}-$isFocusMode'),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          18,
          isCompactHeight ? 14 : 18,
          18,
          isCompactHeight ? 16 : 20,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kNavy.withValues(alpha: 0.98),
              kCard.withValues(alpha: 0.98),
              kDeepBrinjal.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: isHighlighted
                ? kGold.withValues(alpha: 0.70)
                : kGold.withValues(alpha: 0.28),
            width: isHighlighted ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: isHighlighted ? 0.26 : 0.12),
              blurRadius: isHighlighted ? 30 : 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReadingProgressHeader(
              chapterNumber: verse.chapterNumber,
              verseNumber: verse.verseNumber,
              progressValue: progressValue,
              isFocusMode: isFocusMode,
              onFocusToggle: () => onFocusModeChanged(!isFocusMode),
            ),
            SizedBox(height: isCompactHeight ? 12 : 18),
            // Reading-first layout:
            // Sanskrit and transliteration are shown exactly from local JSON
            // when available. Missing fields are hidden instead of replaced
            // with generated or placeholder text.
            if (showSanskrit && sanskrit.isNotEmpty) ...[
              const _ReadingSectionLabel('Sanskrit'),
              const SizedBox(height: 8),
              _ResponsiveReaderText(
                text: sanskrit,
                maxHeight: sanskritMaxHeight,
                style: gitaSanskrit(sanskritSize).copyWith(
                  color: kAntiqueGold,
                  height: isCompactHeight ? 1.58 : 1.78,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: kGold.withValues(alpha: 0.18),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionGap),
            ],
            if (showTransliteration && transliteration.isNotEmpty) ...[
              const _ReadingSectionLabel('Transliteration'),
              const SizedBox(height: 8),
              _ResponsiveReaderText(
                text: transliteration,
                maxHeight: transliterationMaxHeight,
                style: gitaTransliteration(
                  size: transliterationSize,
                  color: kText.withValues(alpha: 0.92),
                ).copyWith(
                  height: isCompactHeight ? 1.45 : 1.65,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: translationGap),
            ],
            if (translation.isNotEmpty) ...[
              // Translation is separated into a cream reading card so long
              // English text stays readable over the dark devotional surface.
              _TranslationReadingCard(
                translation: translation,
                fontSize: fontSize,
              ),
              SizedBox(height: isCompactHeight ? 10 : 14),
            ],
            _VerseBottomActions(
              // Compact action row:
              // Save, share, play, and highlight stay below the primary
              // reading content and never become a separate vertical panel.
              verse: verse,
              isSavedBusy: isSavedBusy,
              isHighlightBusy: isHighlightBusy,
              onSavingChanged: onSavingChanged,
              onHighlightingChanged: onHighlightingChanged,
              onShare: onShare,
              player: player,
              selectedAudioVerseId: selectedAudioVerseId,
              isAudioLoading: isAudioLoading,
              onAudioToggle: onAudioToggle,
            ),
            if (!isFocusMode) ...[
              const SizedBox(height: 24),
              const _ElegantDivider(),
              const SizedBox(height: 22),
              if (interpretation.isNotEmpty) ...[
                // Reflection flow:
                // The app's interpretation layer, Reflection, and Practice
                // Today stay as separate study cards so scripture translation
                // never blends into practical understanding.
                _GitaWisdomInterpretationPanel(
                  interpretation: interpretation,
                  fontSize: fontSize,
                ),
                const SizedBox(height: 16),
              ],
              _ReflectionAndPracticePanels(
                verse: verse,
                fontSize: fontSize,
              ),
              const SizedBox(height: 18),
              _ReaderControls(
                fontSize: fontSize,
                showSanskrit: showSanskrit,
                showTransliteration: showTransliteration,
                onFontSizeChanged: onFontSizeChanged,
                onSanskritChanged: onSanskritChanged,
                onTransliterationChanged: onTransliterationChanged,
              ),
            ] else ...[
              const SizedBox(height: 14),
              Text(
                'Tap anywhere on this card to return to full view.',
                textAlign: TextAlign.center,
                style: gitaBody(
                  color: kMuted.withValues(alpha: 0.86),
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!isFocusMode) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onFocusModeChanged(false),
      child: content,
    );
  }
}

class _ReadingProgressHeader extends StatelessWidget {
  const _ReadingProgressHeader({
    required this.chapterNumber,
    required this.verseNumber,
    required this.progressValue,
    required this.isFocusMode,
    required this.onFocusToggle,
  });

  final int chapterNumber;
  final int verseNumber;
  final double progressValue;
  final bool isFocusMode;
  final VoidCallback onFocusToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Chapter $chapterNumber • Verse $verseNumber',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gitaBody(
                  color: kText.withValues(alpha: 0.86),
                  size: 14,
                  weight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _FocusModeButton(
              isFocusMode: isFocusMode,
              onTap: onFocusToggle,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: kGold.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation(
              kAntiqueGold.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadingSectionLabel extends StatelessWidget {
  const _ReadingSectionLabel(this.label);

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

class _ResponsiveReaderText extends StatelessWidget {
  const _ResponsiveReaderText({
    required this.text,
    required this.style,
    required this.maxHeight,
  });

  final String text;
  final TextStyle style;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              child: Text(
                text,
                textAlign: TextAlign.center,
                textWidthBasis: TextWidthBasis.parent,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FocusModeButton extends StatelessWidget {
  const _FocusModeButton({
    required this.isFocusMode,
    required this.onTap,
  });

  final bool isFocusMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isFocusMode
              ? kGold.withValues(alpha: 0.22)
              : kCard2.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.26)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFocusMode
                  ? Icons.visibility_rounded
                  : Icons.visibility_outlined,
              color: kAntiqueGold,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isFocusMode ? 'Full view' : 'Focus',
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

class _TranslationReadingCard extends StatelessWidget {
  const _TranslationReadingCard({
    required this.translation,
    required this.fontSize,
  });

  final String translation;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Translation',
            style: gitaBody(
              color: kRoyalPurple,
              size: 13,
              weight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            translation,
            style: gitaBody(
              color: kDarkText,
              size: 18 * fontSize,
              weight: FontWeight.w800,
            ).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _ElegantDivider extends StatelessWidget {
  const _ElegantDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: kGold.withValues(alpha: 0.16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.spa_rounded,
            color: kGold.withValues(alpha: 0.42),
            size: 16,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: kGold.withValues(alpha: 0.16),
          ),
        ),
      ],
    );
  }
}

class _ReflectionAndPracticePanels extends StatelessWidget {
  const _ReflectionAndPracticePanels({
    required this.verse,
    required this.fontSize,
  });

  final GitaVerseData verse;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Reflections and practices are optional local study notes. Missing content
    // is hidden rather than replaced with synthetic copy.
    return FutureBuilder<VerseReflectionData?>(
      future: ReflectionService.reflectionForVerse(
        chapterNumber: verse.chapterNumber,
        verseNumber: verse.verseNumber,
      ),
      builder: (context, snapshot) {
        final matchedReflection = snapshot.data;
        final reflectionText = _effectiveReflectionText(
          verse,
          matchedReflection,
        );
        final practiceText = _effectivePracticeText(
          verse,
          matchedReflection,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reflectionText.isNotEmpty) ...[
              _ReflectionPanel(
                reflection: reflectionText,
                fontSize: fontSize,
              ),
            ],
            if (practiceText.isNotEmpty) ...[
              if (reflectionText.isNotEmpty) const SizedBox(height: 16),
              _PracticeTodayPanel(
                practiceToday: practiceText,
                fontSize: fontSize,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GitaWisdomInterpretationPanel extends StatelessWidget {
  const _GitaWisdomInterpretationPanel({
    required this.interpretation,
    required this.fontSize,
  });

  final String interpretation;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGold.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: kGold.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, color: kGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gita Wisdom Interpretation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(color: kGold, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            interpretation,
            softWrap: true,
            style: gitaBody(color: kDarkText, size: 16.5 * fontSize).copyWith(
              height: 1.64,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionPanel extends StatelessWidget {
  const _ReflectionPanel({
    required this.reflection,
    required this.fontSize,
  });

  final String reflection;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: kGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reflection',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(color: kDarkText, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reflection,
            style: gitaBody(
              color: kDarkText,
              size: 16 * fontSize,
              weight: FontWeight.w700,
            ).copyWith(height: 1.58),
          ),
          const SizedBox(height: 14),
          Text(
            'Carry one insight from this verse into your day.',
            style: gitaTransliteration(
              color: kRoyalPurple.withValues(alpha: 0.78),
              size: 14 * fontSize,
            ).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PracticeTodayPanel extends StatelessWidget {
  const _PracticeTodayPanel({
    required this.practiceToday,
    required this.fontSize,
  });

  final String practiceToday;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kCream,
            kSoftGold.withValues(alpha: 0.28),
            kCream,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGold.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: kGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Practice Today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gitaBody(color: kDarkText, weight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practiceToday,
            style: gitaBody(
              color: kDarkText,
              size: 16 * fontSize,
              weight: FontWeight.w700,
            ).copyWith(height: 1.58),
          ),
        ],
      ),
    );
  }
}

String _effectiveReflectionText(
  GitaVerseData verse,
  VerseReflectionData? matchedReflection,
) {
  final serviceReflection = matchedReflection?.reflection.trim() ?? '';
  if (serviceReflection.isNotEmpty) {
    return serviceReflection;
  }
  return verse.reflectionText.trim();
}

String _effectivePracticeText(
  GitaVerseData verse,
  VerseReflectionData? matchedReflection,
) {
  final servicePractice = matchedReflection?.practiceToday.trim() ?? '';
  if (servicePractice.isNotEmpty) {
    return servicePractice;
  }
  final versePractice = verse.practiceToday.trim();
  if (versePractice.isNotEmpty) {
    return versePractice;
  }

  return '';
}

String _verseAudioAssetPath(GitaVerseData verse) {
  // The app uses a flat chapter_verse convention so generated audio packs can
  // be copied into assets/audio/gita/ without changing JSON content.
  return 'assets/audio/gita/${verse.chapterNumber}_${verse.verseNumber}.mp3';
}

Future<Set<String>>? _verseAudioAssetManifestFuture;

Future<Set<String>> _verseAudioAssetPaths() {
  // AssetManifest is the source of truth for packaged Flutter assets. Checking
  // it before showing Play avoids a broken-feeling loading/error state for
  // verses whose audio has not been produced yet.
  return _verseAudioAssetManifestFuture ??=
      AssetManifest.loadFromAssetBundle(rootBundle)
          .then((manifest) => manifest.listAssets().toSet());
}

Future<bool> _verseAudioAssetExists(String assetPath) async {
  try {
    final assets = await _verseAudioAssetPaths();
    return assets.contains(assetPath);
  } catch (error, stackTrace) {
    debugPrint('Verse audio asset manifest check failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}

class _VerseNavigationBar extends StatelessWidget {
  const _VerseNavigationBar({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: GoldButton(
              label: 'Previous',
              icon: Icons.arrow_back_rounded,
              onPressed: canGoPrevious ? onPrevious : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GoldButton(
              label: 'Next',
              icon: Icons.arrow_forward_rounded,
              onPressed: canGoNext ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedCompletionActions extends StatelessWidget {
  const _FixedCompletionActions({
    required this.chapterNumber,
    required this.isFinalChapter,
    required this.onPrimary,
    required this.onReviewChapter,
    required this.onBackToChapters,
    required this.onJournalReflection,
    required this.onAskGita,
  });

  final int chapterNumber;
  final bool isFinalChapter;
  final VoidCallback onPrimary;
  final VoidCallback onReviewChapter;
  final VoidCallback onBackToChapters;
  final VoidCallback onJournalReflection;
  final VoidCallback onAskGita;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconMedallion(
                icon: Icons.emoji_events_rounded,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFinalChapter
                          ? 'You completed the Bhagavad Gita'
                          : 'Chapter Complete',
                      style: gitaBody(color: kText, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isFinalChapter
                          ? 'Review, reflect, or ask for a final summary.'
                          : 'You finished Chapter $chapterNumber. Choose where to continue.',
                      style: gitaBody(size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: isFinalChapter
                ? 'Complete Gita Journey'
                : 'Continue to Chapter ${chapterNumber + 1}',
            icon: isFinalChapter
                ? Icons.emoji_events_rounded
                : Icons.skip_next_rounded,
            onPressed: onPrimary,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CompletionMiniAction(
                icon: Icons.replay_rounded,
                label: 'Review Chapter',
                onTap: onReviewChapter,
              ),
              _CompletionMiniAction(
                icon: Icons.menu_book_rounded,
                label: 'Back to Chapters',
                onTap: onBackToChapters,
              ),
              _CompletionMiniAction(
                icon: Icons.edit_note_rounded,
                label: 'Journal Reflection',
                onTap: onJournalReflection,
              ),
              _CompletionMiniAction(
                icon: Icons.music_note_rounded,
                label: 'Ask Gita About This Chapter',
                onTap: onAskGita,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionMiniAction extends StatelessWidget {
  const _CompletionMiniAction({
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: kCard2.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kGold, size: 16),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                label,
                maxLines: 2,
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

class _VerseBottomActions extends StatelessWidget {
  const _VerseBottomActions({
    required this.verse,
    required this.isSavedBusy,
    required this.isHighlightBusy,
    required this.onSavingChanged,
    required this.onHighlightingChanged,
    required this.onShare,
    required this.player,
    required this.selectedAudioVerseId,
    required this.isAudioLoading,
    required this.onAudioToggle,
  });

  final GitaVerseData verse;
  final bool isSavedBusy;
  final bool isHighlightBusy;
  final ValueChanged<bool> onSavingChanged;
  final ValueChanged<bool> onHighlightingChanged;
  final VoidCallback onShare;
  final AudioPlayer? player;
  final String? selectedAudioVerseId;
  final bool isAudioLoading;
  final VoidCallback onAudioToggle;

  @override
  Widget build(BuildContext context) {
    // Action chips stay inside the verse card, not the bottom navigation bar,
    // so Save/Share/Highlight/Audio remain tied to the currently visible verse.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SaveActionChip(
                verse: verse,
                isSaving: isSavedBusy,
                onSavingChanged: onSavingChanged,
              ),
              _VerseActionChip(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: onShare,
              ),
              _VerseAudioControl(
                verse: verse,
                player: player,
                selectedAudioVerseId: selectedAudioVerseId,
                isAudioLoading: isAudioLoading,
                onTap: onAudioToggle,
              ),
              _HighlightActionChip(
                verse: verse,
                isHighlighting: isHighlightBusy,
                onHighlightingChanged: onHighlightingChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerseAudioControl extends StatelessWidget {
  const _VerseAudioControl({
    required this.verse,
    required this.player,
    required this.selectedAudioVerseId,
    required this.isAudioLoading,
    required this.onTap,
  });

  final GitaVerseData verse;
  final AudioPlayer? player;
  final String? selectedAudioVerseId;
  final bool isAudioLoading;
  final VoidCallback onTap;

  bool get _isSelected => selectedAudioVerseId == verse.id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _verseAudioAssetExists(_verseAudioAssetPath(verse)),
      builder: (context, availabilitySnapshot) {
        final hasAudio = availabilitySnapshot.data ?? false;
        if (availabilitySnapshot.connectionState != ConnectionState.done) {
          return const _VerseActionChip(
            icon: Icons.music_note_rounded,
            label: 'Audio',
            isBusy: true,
            onTap: null,
          );
        }
        if (!hasAudio) {
          return const _VerseActionChip(
            icon: Icons.music_off_rounded,
            label: 'Audio',
            onTap: null,
          );
        }

        final audioPlayer = player;
        if (audioPlayer == null || !_isSelected) {
          return _VerseActionChip(
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            isBusy: isAudioLoading && _isSelected,
            onTap: onTap,
          );
        }

        return StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          initialData: audioPlayer.playerState,
          builder: (context, stateSnapshot) {
            final state = stateSnapshot.data ?? audioPlayer.playerState;
            final isPlaying = state.playing;
            final isBusy = isAudioLoading ||
                state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering;
            return _VerseActionChip(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: isBusy
                  ? 'Loading'
                  : isPlaying
                      ? 'Pause'
                      : 'Play',
              selected: isPlaying,
              isBusy: isBusy,
              onTap: isBusy ? null : onTap,
            );
          },
        );
      },
    );
  }
}

class _HighlightActionChip extends StatelessWidget {
  const _HighlightActionChip({
    required this.verse,
    required this.isHighlighting,
    required this.onHighlightingChanged,
  });

  final GitaVerseData verse;
  final bool isHighlighting;
  final ValueChanged<bool> onHighlightingChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LocalStorageService.isVerseHighlighted(verse.id),
      builder: (context, snapshot) {
        final highlighted = snapshot.data ?? false;
        return _VerseActionChip(
          icon: highlighted
              ? Icons.auto_awesome_rounded
              : Icons.auto_awesome_outlined,
          label: 'Highlight',
          selected: highlighted,
          isBusy: isHighlighting,
          onTap: () => _toggleHighlight(context, highlighted),
        );
      },
    );
  }

  Future<void> _toggleHighlight(
    BuildContext context,
    bool highlighted,
  ) async {
    onHighlightingChanged(true);
    try {
      HapticFeedback.lightImpact();
      await LocalStorageService.setVerseHighlighted(
        verse.id,
        highlighted: !highlighted,
      );
      if (!highlighted) {
        await PersonalizationService.recordVerseHighlighted(verse);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              highlighted
                  ? 'Highlight removed.'
                  : 'Verse highlighted for reflection.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Highlight toggle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update highlight.')),
        );
      }
    } finally {
      onHighlightingChanged(false);
    }
  }
}

class _SaveActionChip extends StatelessWidget {
  const _SaveActionChip({
    required this.verse,
    required this.isSaving,
    required this.onSavingChanged,
  });

  final GitaVerseData verse;
  final bool isSaving;
  final ValueChanged<bool> onSavingChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LocalStorageService.isVerseSaved(verse.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;
        return _VerseActionChip(
          icon:
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: isSaved ? 'Saved Wisdom' : 'Save',
          selected: isSaved,
          isBusy: isSaving,
          onTap: () => _toggleSaved(context, isSaved),
        );
      },
    );
  }

  Future<void> _toggleSaved(
    BuildContext context,
    bool isSaved,
  ) async {
    onSavingChanged(true);
    try {
      // Saved verses are local-only and idempotent. Snackbars provide immediate
      // feedback because there is no account/cloud sync state to wait for.
      HapticFeedback.lightImpact();
      if (isSaved) {
        await LocalStorageService.removeSavedVerse(verse.id);
        if (context.mounted) {
          _showSaveMessage(context, 'Verse removed from saved.');
        }
      } else {
        await LocalStorageService.saveVerse(verse);
        if (context.mounted) {
          _showSaveSuccess(context);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Saved verse toggle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        _showSaveMessage(context, 'Could not update saved verse.');
      }
    } finally {
      onSavingChanged(false);
    }
  }

  void _showSaveMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSaveSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kCard,
        content: _SavedVerseSuccessContent(),
      ),
    );
  }
}

class _VerseActionChip extends StatelessWidget {
  const _VerseActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isBusy;
    return PressableScale(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: !enabled
              ? kCard2.withValues(alpha: 0.34)
              : selected
                  ? kRoyalPurple.withValues(alpha: 0.94)
                  : kCard2.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? kGold.withValues(alpha: 0.36)
                : kLine.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kGold,
                ),
              )
            else
              Icon(
                icon,
                color: !enabled
                    ? kMuted.withValues(alpha: 0.72)
                    : selected
                        ? kSoftGold
                        : kText,
                size: 15,
              ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gitaBody(
                  color: !enabled
                      ? kMuted.withValues(alpha: 0.72)
                      : selected
                          ? kSoftGold
                          : kText,
                  size: 11,
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

class _SavedVerseSuccessContent extends StatelessWidget {
  const _SavedVerseSuccessContent();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Row(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kSaffron,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSaffron.withValues(alpha: 0.28),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: kText,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verse saved.',
                style: gitaBody(color: kText, weight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}
