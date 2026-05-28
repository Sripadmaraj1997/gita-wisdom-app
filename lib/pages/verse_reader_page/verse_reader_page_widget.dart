// Premium scripture reader.
//
// Shows one verse at a time with Sanskrit, transliteration, translation,
// commentary, reflection, and Practice Today. The top verse content remains
// immediately visible, while long explanations scroll below. Previous/Next
// controls stay fixed at the bottom. Verse audio is lazy-loaded only after the
// user taps Play so app startup and chapter navigation never wait on audio.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/gita_data.dart';
import '../../services/local_storage_service.dart';
import '../../services/reading_progress_service.dart';
import '../../services/reflection_service.dart';
import '../gita_common/gita_common.dart';

class VerseReaderPageWidget extends StatefulWidget {
  const VerseReaderPageWidget({
    super.key,
    this.verseId,
  });

  static String routeName = 'VerseReaderPage';
  static String routePath = '/verseReaderPage';

  final String? verseId;

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
                        'Could not load verse data from assets/data/gita/. Please check the chapter JSON files and try again.',
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
                        'Could not find verses for this chapter. Please check the chapter JSON files.',
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
                PageHeader(
                  title: currentChapter == null
                      ? 'Chapter ${currentVerse.chapterNumber}'
                      : 'Chapter ${currentChapter.chapterNumber}: ${currentChapter.title}',
                  subtitle:
                      'Verse ${_currentIndex! + 1} of ${chapterVerses.length}',
                  showBack: true,
                ),
                Expanded(
                  child: PageView.builder(
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
                      final chapter =
                          bundle.chapterByNumber(verse.chapterNumber);
                      final pageBottomPadding =
                          index == chapterVerses.length - 1 ? 360.0 : 150.0;
                      return SingleChildScrollView(
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
                                    verse: verse,
                                    chapter: chapter,
                                    currentIndex: index,
                                    totalVerses: chapterVerses.length,
                                    fontSize: _fontSize,
                                    showSanskrit: _showSanskrit,
                                    showTransliteration: _showTransliteration,
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
        debugPrint(
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
    final player = _audioPlayer();
    final isCurrentVerse = _selectedAudioVerseId == verse.id;
    final state = player.playerState.processingState;

    if (isCurrentVerse && player.playing) {
      // Pause must remain responsive even while the progress stream is active.
      debugPrint('VerseAudio: pause tapped ${verse.reference}');
      HapticFeedback.selectionClick();
      await player.pause();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (isCurrentVerse && !player.playing && !_isAudioLoading) {
      if (state == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      debugPrint('VerseAudio: play start ${verse.reference}');
      HapticFeedback.selectionClick();
      unawaited(player.play());
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final assetPath = _verseAudioAssetPath(verse);
    debugPrint('VerseAudio: loading start $assetPath');
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAudioVerseId = verse.id;
      _isAudioLoading = true;
    });

    try {
      // Audio assets are optional. setAsset is inside try/catch so a missing
      // verse file shows a gentle message instead of crashing the reader.
      await player.stop();
      await player.setAsset(assetPath);
      debugPrint('VerseAudio: setAsset complete $assetPath');
      if (mounted) {
        setState(() => _isAudioLoading = false);
      }
      debugPrint('VerseAudio: play start ${verse.reference}');
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
        _showMessage('Audio not available for this verse yet.');
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
              Text(
                'Reader settings',
                style: gitaBody(color: kText, weight: FontWeight.w900),
              ),
              const Spacer(),
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
            Text(
              label,
              style: gitaBody(
                color: selected ? kSoftGold : kText,
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

class _VerseContentCard extends StatelessWidget {
  const _VerseContentCard({
    required this.verse,
    required this.chapter,
    required this.currentIndex,
    required this.totalVerses,
    required this.fontSize,
    required this.showSanskrit,
    required this.showTransliteration,
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
    required this.onFontSizeChanged,
    required this.onSanskritChanged,
    required this.onTransliterationChanged,
  });

  final GitaVerseData verse;
  final GitaChapterData? chapter;
  final int currentIndex;
  final int totalVerses;
  final double fontSize;
  final bool showSanskrit;
  final bool showTransliteration;
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
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onSanskritChanged;
  final ValueChanged<bool> onTransliterationChanged;

  @override
  Widget build(BuildContext context) {
    // Layout order is deliberate: reference, Sanskrit, transliteration, and the
    // compact action row appear before longer translation/commentary content.
    return PremiumCard(
      accent: false,
      padding: const EdgeInsets.all(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: kCream,
          border: Border.all(
            color: isHighlighted
                ? kGold.withValues(alpha: 0.72)
                : kGold.withValues(alpha: 0.22),
            width: isHighlighted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: isHighlighted ? 0.30 : 0.16),
              blurRadius: isHighlighted ? 34 : 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AccentPill(verse.reference),
                if (isHighlighted) ...[
                  const SizedBox(width: 8),
                  const AccentPill('Highlighted'),
                ],
                const Spacer(),
                Text(
                  'Verse ${currentIndex + 1} of $totalVerses',
                  style: gitaBody(
                    color: kDarkText.withValues(alpha: 0.68),
                    size: 12,
                    weight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (showSanskrit) ...[
              _VerseSection(
                label: 'Sanskrit',
                child: PurpleVerseCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    verse.sanskrit,
                    style: gitaSanskrit(24 * fontSize).copyWith(
                      color: kAntiqueGold,
                      height: 1.48,
                      shadows: [
                        Shadow(
                          color: kGold.withValues(alpha: 0.36),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (showTransliteration) ...[
              _VerseSection(
                label: 'Transliteration',
                child: Text(
                  verse.transliteration,
                  style: gitaTransliteration(
                    size: 16 * fontSize,
                    color: kDarkText.withValues(alpha: 0.78),
                  ).copyWith(height: 1.46),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _VerseBottomActions(
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
            const SizedBox(height: 18),
            _VerseSection(
              label: 'English Translation',
              child: Text(
                verse.englishTranslation,
                style: gitaBody(
                  color: kDarkText,
                  size: 19 * fontSize,
                  weight: FontWeight.w800,
                ).copyWith(height: 1.56),
              ),
            ),
            const SizedBox(height: 20),
            _CommentaryPanel(
              chapter: chapter,
              verse: verse,
              fontSize: fontSize,
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
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
    // Reflections are optional editorial content. Practice Today always renders
    // with a fallback so every verse has an actionable takeaway.
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
        final canSave = _hasSourceReflectionOrPractice(
          verse,
          matchedReflection,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reflectionText.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ReflectionPanel(
                reflection: reflectionText,
                fontSize: fontSize,
              ),
            ],
            const SizedBox(height: 16),
            _PracticeTodayPanel(
              practiceToday: practiceText,
              fontSize: fontSize,
            ),
            if (canSave) ...[
              const SizedBox(height: 12),
              _SaveReflectionButton(
                verse: verse,
                reflection: reflectionText,
                practiceToday: practiceText,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SaveReflectionButton extends StatefulWidget {
  const _SaveReflectionButton({
    required this.verse,
    required this.reflection,
    required this.practiceToday,
  });

  final GitaVerseData verse;
  final String reflection;
  final String practiceToday;

  @override
  State<_SaveReflectionButton> createState() => _SaveReflectionButtonState();
}

class _SaveReflectionButtonState extends State<_SaveReflectionButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GoldButton(
        label: 'Save Reflection',
        icon: Icons.bookmark_add_rounded,
        isLoading: _isSaving,
        onPressed: _isSaving ? null : _saveReflection,
      ),
    );
  }

  Future<void> _saveReflection() async {
    setState(() => _isSaving = true);
    try {
      await LocalStorageService.saveReflection(
        widget.verse,
        reflection: widget.reflection,
        practiceToday: widget.practiceToday,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Save reflection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save reflection.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _VerseSection extends StatelessWidget {
  const _VerseSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: gitaBody(
            color: kRoyalPurple,
            size: 11,
            weight: FontWeight.w900,
          ).copyWith(letterSpacing: 0.35),
        ),
        const SizedBox(height: 11),
        child,
      ],
    );
  }
}

class _CommentaryPanel extends StatelessWidget {
  const _CommentaryPanel({
    required this.chapter,
    required this.verse,
    required this.fontSize,
  });

  final GitaChapterData? chapter;
  final GitaVerseData verse;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = verse.meaning.trim().isEmpty
        ? 'Reflect on this verse as guidance for steady action, inner clarity, and peaceful living.'
        : verse.meaning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kCream,
            kAntiqueGold.withValues(alpha: 0.42),
            kCream,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, color: kGold, size: 18),
              const SizedBox(width: 8),
              Text('Meaning / Commentary',
                  style: gitaBody(color: kDarkText, weight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            text,
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
              Text(
                'Reflection',
                style: gitaBody(color: kDarkText, weight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reflection,
            style: gitaBody(
              color: kDarkText,
              size: 15.5 * fontSize,
              weight: FontWeight.w700,
            ).copyWith(height: 1.58),
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
              Text(
                'Practice Today',
                style: gitaBody(color: kDarkText, weight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practiceToday,
            style: gitaBody(
              color: kDarkText,
              size: 15.5 * fontSize,
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

  return 'Pause, reflect, and carry one insight from this verse into your day.';
}

bool _hasSourceReflectionOrPractice(
  GitaVerseData verse,
  VerseReflectionData? matchedReflection,
) {
  return verse.reflectionText.trim().isNotEmpty ||
      verse.practiceToday.trim().isNotEmpty ||
      (matchedReflection?.reflection.trim().isNotEmpty ?? false) ||
      (matchedReflection?.practiceToday.trim().isNotEmpty ?? false);
}

String _verseAudioAssetPath(GitaVerseData verse) {
  return 'assets/audio/gita/${verse.chapterNumber}_${verse.verseNumber}.mp3';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: kCard2.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGold.withValues(alpha: 0.18)),
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
          _VerseAudioProgress(
            verse: verse,
            player: player,
            selectedAudioVerseId: selectedAudioVerseId,
          ),
        ],
      ),
    );
  }
}

class _VerseAudioProgress extends StatelessWidget {
  const _VerseAudioProgress({
    required this.verse,
    required this.player,
    required this.selectedAudioVerseId,
  });

  final GitaVerseData verse;
  final AudioPlayer? player;
  final String? selectedAudioVerseId;

  @override
  Widget build(BuildContext context) {
    // The progress line is intentionally subtle and only appears after a valid
    // duration is known. It never reserves space for verses without audio.
    final audioPlayer = player;
    if (audioPlayer == null || selectedAudioVerseId != verse.id) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Duration?>(
      stream: audioPlayer.durationStream,
      initialData: audioPlayer.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data;
        if (duration == null || duration.inMilliseconds <= 0) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<Duration>(
          stream: audioPlayer.positionStream,
          initialData: audioPlayer.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final progress = (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0);
            return SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: kGold.withValues(alpha: 0.16),
                    valueColor: const AlwaysStoppedAnimation(kGold),
                  ),
                ),
              ),
            );
          },
        );
      },
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
          label: isSaved ? 'Saved' : 'Save',
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
    return PressableScale(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
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
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kGold,
                ),
              )
            else
              Icon(
                icon,
                color: selected ? kSoftGold : kText,
                size: 16,
              ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gitaBody(
                  color: selected ? kSoftGold : kText,
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
