// Ask Gita Lite screen.
//
// This is a retrieval-only MVP: it searches local Gita verses and local journal
// reflections, then formats calm guidance. It intentionally does not call
// OpenAI, Firebase, or any backend so it remains fast and available offline.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart';
import '../../services/local_storage_service.dart';
import '../gita_common/gita_common.dart';

class AskGitaPageWidget extends StatefulWidget {
  const AskGitaPageWidget({
    super.key,
    this.initialQuestion,
    this.initialContext,
  });

  static String routeName = 'AskGitaPage';
  static String routePath = '/askGitaPage';

  final String? initialQuestion;
  final String? initialContext;

  @override
  State<AskGitaPageWidget> createState() => _AskGitaPageWidgetState();
}

class _AskGitaPageWidgetState extends State<AskGitaPageWidget> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  _AskGuidance? _guidance;
  String? _emptyMessage;
  bool _isLoading = false;

  static const _suggestedQuestions = [
    'How do I stop worrying?',
    'How do I handle anger?',
    'How do I stay disciplined?',
    'How do I let go of attachment?',
    'How do I find peace?',
  ];

  @override
  void initState() {
    super.initState();
    final initialQuestion = widget.initialQuestion?.trim();
    if (initialQuestion != null && initialQuestion.isNotEmpty) {
      _questionController.text = initialQuestion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _askQuestion(initialQuestion);
        }
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion([String? overrideQuestion]) async {
    final question = (overrideQuestion ?? _questionController.text).trim();
    if (question.isEmpty || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _guidance = null;
      _emptyMessage = null;
    });

    try {
      // Expand emotional wording before searching. This makes questions like
      // "How do I stop worrying?" retrieve relevant verses without an AI model.
      final enhancedQuestion = _expandEmotionalQuery(question);
      final verseMatches =
          await GitaRepository.search(enhancedQuestion, limit: 3);
      final reflectionMatches = await _topLocalReflectionMatches(question);
      final verse = verseMatches.isEmpty ? null : verseMatches.first.verse;
      final reflection =
          reflectionMatches.isEmpty ? null : reflectionMatches.first;

      if (!mounted) {
        return;
      }

      if (verse == null && reflection == null) {
        setState(() {
          _emptyMessage =
              'Try asking about peace, duty, fear, anger, attachment, or purpose.';
          _isLoading = false;
        });
        _scrollGentlyToAnswer();
        return;
      }

      setState(() {
        _guidance = _AskGuidance.fromRetrieval(
          question: question,
          verse: verse,
          reflection: reflection,
        );
        _isLoading = false;
      });
      await LocalStorageService.recordAskGitaHistory(
        question: question,
        answer: _guidance?.gentleGuidance ?? '',
      );
      _scrollGentlyToAnswer();
    } catch (error, stackTrace) {
      debugPrint('AskGita Lite retrieval failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _emptyMessage =
            'Try asking about peace, duty, fear, anger, attachment, or purpose.';
        _isLoading = false;
      });
      _scrollGentlyToAnswer();
    }
  }

  Future<List<_LocalReflectionMatch>> _topLocalReflectionMatches(
    String question,
  ) async {
    try {
      // Local journal entries are treated as private context only on device.
      // They are never uploaded or sent to a service in the MVP.
      final entries = await LocalStorageService.journalEntries();
      final matches = entries
          .map((entry) => _LocalReflectionMatch.fromEntry(entry, question))
          .where((match) => match.score > 0)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return matches.take(3).toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('AskGita Lite local reflection search failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  void _scrollGentlyToAnswer() {
    // Avoid aggressive jumps. Only scroll if the user is already near the
    // bottom; this keeps older answers readable while still revealing new ones.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.maxScrollExtent;
      if (target <= position.pixels || position.extentAfter > 520) {
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                children: [
                  _AskHeader(onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/homePage');
                    }
                  }),
                  const SizedBox(height: 22),
                  _SuggestedQuestionGrid(
                    questions: _suggestedQuestions,
                    isDisabled: _isLoading,
                    onTap: (question) {
                      _questionController.text = question;
                      _askQuestion(question);
                    },
                  ),
                  const SizedBox(height: 22),
                  if (_isLoading)
                    const _ReflectionLoadingCard()
                  else if (_guidance != null)
                    _GuidanceResultCard(guidance: _guidance!)
                  else if (_emptyMessage != null)
                    _EmptyAskState(message: _emptyMessage!)
                  else
                    const _QuietStartCard(),
                ],
              ),
            ),
            _QuestionComposer(
              controller: _questionController,
              isLoading: _isLoading,
              onSubmit: _askQuestion,
            ),
          ],
        ),
      ),
    );
  }
}

class _AskHeader extends StatelessWidget {
  const _AskHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedGoldIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                backgroundColor: kCard2,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              const IconMedallion(
                icon: Icons.music_note_rounded,
                size: 50,
                backgroundColor: kGold,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ask Gita', style: gitaTitle(28)),
                    const SizedBox(height: 4),
                    Text(
                      'Receive Gita-inspired guidance for daily life.',
                      style: gitaBody(color: kText, size: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGold.withValues(alpha: 0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_rounded, color: kGold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gita Wisdom provides Bhagavad Gita-inspired reflections for spiritual learning. It is not medical, legal, financial, or mental health advice.',
                    style: gitaBody(
                      color: kText,
                      size: 13,
                      weight: FontWeight.w800,
                    ),
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

class _SuggestedQuestionGrid extends StatelessWidget {
  const _SuggestedQuestionGrid({
    required this.questions,
    required this.isDisabled,
    required this.onTap,
  });

  final List<String> questions;
  final bool isDisabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: kGold, size: 19),
              const SizedBox(width: 8),
              Text(
                'Suggested questions',
                style: gitaBody(color: kText, weight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a question, then read the answer slowly.',
            style: gitaBody(color: kMuted, size: 13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final itemWidth = isWide
                  ? (constraints.maxWidth - 20) / 3
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final question in questions)
                    SizedBox(
                      width: itemWidth,
                      child: _SuggestedQuestionChip(
                        question: question,
                        isDisabled: isDisabled,
                        onTap: () => onTap(question),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestedQuestionChip extends StatelessWidget {
  const _SuggestedQuestionChip({
    required this.question,
    required this.isDisabled,
    required this.onTap,
  });

  final String question;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: !isDisabled,
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kRoyalPurple.withValues(alpha: 0.88),
              kCard2.withValues(alpha: 0.84),
              kCard.withValues(alpha: 0.96),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kGold.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.spa_rounded, color: kGold, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                question,
                style: gitaBody(
                  color: kText,
                  size: 13,
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

class _QuestionComposer extends StatelessWidget {
  const _QuestionComposer({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kCard.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: kGold.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: kGold.withValues(alpha: 0.12),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kDeepBrinjal,
                  border: Border.all(color: kGold.withValues(alpha: 0.42)),
                  boxShadow: [
                    BoxShadow(
                      color: kGold.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: kGold,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  style: gitaBody(color: kDarkText, size: 15),
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    hintText: 'Ask about peace, duty, fear, purpose...',
                    hintStyle: gitaBody(
                      color: kDarkText.withValues(alpha: 0.58),
                      size: 13,
                    ),
                    filled: true,
                    fillColor: kCream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: kGold.withValues(alpha: 0.22),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: kGold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedGoldIconButton(
                icon: Icons.send_rounded,
                isBusy: isLoading,
                tooltip: 'Ask Gita',
                backgroundColor: isLoading ? kCard2 : null,
                onTap: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionLoadingCard extends StatelessWidget {
  const _ReflectionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: kGold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Reflecting on the Gita...',
              style: gitaBody(color: kText, weight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietStartCard extends StatelessWidget {
  const _QuietStartCard();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.menu_book_rounded,
      title: 'Seek clarity, peace, and wisdom through the Gita.',
      body:
          'Ask about worry, anger, discipline, attachment, or purpose to receive a verse and one small practice.',
    );
  }
}

class _EmptyAskState extends StatelessWidget {
  const _EmptyAskState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.search_off_rounded, color: kGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: gitaBody(color: kText, size: 15).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceResultCard extends StatelessWidget {
  const _GuidanceResultCard({required this.guidance});

  final _AskGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntrance(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kGold.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuidanceSection(
              icon: Icons.self_improvement_rounded,
              title: 'Gentle Guidance',
              child: Text(
                guidance.gentleGuidance,
                style:
                    gitaBody(color: kDarkText, size: 16).copyWith(height: 1.62),
              ),
            ),
            const SizedBox(height: 20),
            if (guidance.verse != null) ...[
              _GuidanceSection(
                icon: Icons.menu_book_rounded,
                title: 'Relevant Gita Verse',
                child: _RelevantVersePanel(verse: guidance.verse!),
              ),
              const SizedBox(height: 20),
            ],
            _GuidanceSection(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Meaning',
              child: Text(
                guidance.meaning,
                style:
                    gitaBody(color: kDarkText, size: 15).copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            _GuidanceSection(
              icon: Icons.spa_rounded,
              title: 'Practice Today',
              child: Text(
                guidance.practiceToday,
                style: gitaBody(
                  color: kDarkText,
                  size: 15,
                  weight: FontWeight.w800,
                ).copyWith(height: 1.58),
              ),
            ),
            const SizedBox(height: 20),
            _SourcePanel(guidance: guidance),
          ],
        ),
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withValues(alpha: 0.16),
                border: Border.all(color: kGold.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, color: kRoyalPurple, size: 17),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: gitaBody(
                color: kRoyalPurple,
                size: 14,
                weight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGold.withValues(alpha: 0.16)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _RelevantVersePanel extends StatelessWidget {
  const _RelevantVersePanel({required this.verse});

  final GitaVerseData verse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccentPill(verse.shortReference),
          const SizedBox(height: 14),
          if (_hasUsefulText(verse.sanskrit)) ...[
            Text(
              verse.sanskrit,
              style: gitaSanskrit(22).copyWith(color: kRoyalPurple),
            ),
            const SizedBox(height: 10),
          ],
          if (_hasUsefulText(verse.transliteration)) ...[
            Text(
              verse.transliteration,
              style: gitaBody(
                color: kRoyalPurple,
                size: 14,
                weight: FontWeight.w700,
              ).copyWith(fontStyle: FontStyle.italic, height: 1.45),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            verse.englishTranslation,
            style: gitaBody(
              color: kDarkText,
              size: 16,
              weight: FontWeight.w800,
            ).copyWith(height: 1.58),
          ),
        ],
      ),
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({required this.guidance});

  final _AskGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.source_rounded, color: kGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Source',
                style: gitaBody(color: kRoyalPurple, weight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (guidance.verse != null)
            Text(
              'Based on Bhagavad Gita Chapter ${guidance.verse!.chapterNumber}, Verse ${guidance.verse!.verseNumber}',
              style: gitaBody(color: kDarkText, size: 13),
            ),
          if (guidance.verse?.reflectionText.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            const AccentPill('Verse reflection'),
            const SizedBox(height: 8),
            Text(
              guidance.verse!.reflectionText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: gitaBody(color: kDarkText, size: 13).copyWith(height: 1.5),
            ),
          ],
          if (guidance.reflection != null) ...[
            const SizedBox(height: 10),
            const AccentPill('Local reflection matched'),
            const SizedBox(height: 8),
            Text(
              guidance.reflection!.title,
              style: gitaBody(color: kDarkText, weight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              guidance.reflection!.text,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: gitaBody(color: kDarkText, size: 13).copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _AskGuidance {
  const _AskGuidance({
    required this.gentleGuidance,
    required this.meaning,
    required this.practiceToday,
    required this.verse,
    required this.reflection,
  });

  final String gentleGuidance;
  final String meaning;
  final String practiceToday;
  final GitaVerseData? verse;
  final _LocalReflectionMatch? reflection;

  factory _AskGuidance.fromRetrieval({
    required String question,
    required GitaVerseData? verse,
    required _LocalReflectionMatch? reflection,
  }) {
    final sourceText = _firstNonEmpty([
      reflection?.text,
      verse?.reflectionText,
      verse?.meaning,
      verse?.englishTranslation,
    ]);
    return _AskGuidance(
      verse: verse,
      reflection: reflection,
      gentleGuidance: _gentleGuidanceFor(question),
      meaning: _plainMeaningFor(sourceText),
      practiceToday: _firstNonEmpty([
            verse?.practiceToday,
            _practiceFor(question),
          ]) ??
          'Pause, reflect, and carry one insight from this verse into your day.',
    );
  }
}

class _LocalReflectionMatch {
  const _LocalReflectionMatch({
    required this.title,
    required this.text,
    required this.score,
  });

  final String title;
  final String text;
  final int score;

  factory _LocalReflectionMatch.fromEntry(
    LocalJournalEntry entry,
    String question,
  ) {
    final haystack = entry.searchableText;
    return _LocalReflectionMatch(
      title: entry.title,
      text: entry.text,
      score: _scoreMatch(question, haystack),
    );
  }
}

String _gentleGuidanceFor(String question) {
  final lower = question.toLowerCase();
  if (lower.contains('worry') ||
      lower.contains('anxious') ||
      lower.contains('fear')) {
    return 'The Gita invites you to return from imagined outcomes to the duty that is present now. Let your mind become steady by doing the next right action with sincerity.';
  }
  if (lower.contains('anger')) {
    return 'Anger often rises when desire, fear, or expectation feels blocked. Pause before acting, soften the breath, and choose a response that protects your clarity.';
  }
  if (lower.contains('purpose') || lower.contains('dharma')) {
    return 'Purpose becomes clearer through honest action, not endless pressure to know everything at once. Begin with the responsibility nearest to you and offer it with care.';
  }
  if (lower.contains('discipline') || lower.contains('focus')) {
    return 'Discipline grows through repeated small actions done with steadiness. Do not wait for perfect motivation; begin gently and return again tomorrow.';
  }
  if (lower.contains('result') ||
      lower.contains('attachment') ||
      lower.contains('let go')) {
    return 'The Gita teaches that you can give your full effort without surrendering your peace to the outcome. Your part is sincere action; the result is not fully yours to control.';
  }
  return 'The Gita points you toward steadiness, sincere action, and inner clarity. Meet this moment with honesty, do what is yours to do, and loosen your grip on what you cannot control.';
}

String _expandEmotionalQuery(String question) {
  final lower = question.toLowerCase();
  final additions = <String>[];
  void add(List<String> words) => additions.addAll(words);

  if (lower.contains('worry') ||
      lower.contains('anxious') ||
      lower.contains('anxiety') ||
      lower.contains('stress')) {
    add(['peace', 'fear', 'mind', 'steady', 'calm']);
  }
  if (lower.contains('anger')) {
    add(['anger', 'desire', 'control', 'mind']);
  }
  if (lower.contains('discipline') || lower.contains('focus')) {
    add(['practice', 'mind', 'yoga', 'action']);
  }
  if (lower.contains('attachment') ||
      lower.contains('result') ||
      lower.contains('let go')) {
    add(['karma', 'action', 'fruit', 'attachment']);
  }
  if (lower.contains('purpose') || lower.contains('dharma')) {
    add(['dharma', 'duty', 'action', 'purpose']);
  }
  if (lower.contains('peace')) {
    add(['peace', 'devotion', 'steady', 'mind']);
  }
  return [question, ...additions].join(' ');
}

String _plainMeaningFor(String? sourceText) {
  final source = sourceText?.trim();
  if (source == null || source.isEmpty) {
    return 'This guidance is pointing you toward calm action, self-awareness, and trust. Instead of reacting from fear or pressure, return to what can be done with clarity now.';
  }
  final compact = source.replaceAll(RegExp(r'\s+'), ' ');
  if (compact.length <= 260) {
    return compact;
  }
  return '${compact.substring(0, 257).trimRight()}...';
}

String _practiceFor(String question) {
  final lower = question.toLowerCase();
  if (lower.contains('anger')) {
    return 'Pause before reacting. Choose clarity over impulse.';
  }
  if (lower.contains('discipline') || lower.contains('focus')) {
    return 'Choose one meaningful task and give it 15 quiet minutes without distraction.';
  }
  if (lower.contains('purpose') || lower.contains('dharma')) {
    return 'Offer your best effort to one clear duty, then release the outcome.';
  }
  if (lower.contains('result') ||
      lower.contains('attachment') ||
      lower.contains('let go')) {
    return 'Notice one attachment and soften your grip on it.';
  }
  return 'Take one action today without worrying about the result.';
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool _hasUsefulText(String value) {
  final trimmed = value.trim().toLowerCase();
  return trimmed.isNotEmpty &&
      !trimmed.contains('unavailable') &&
      !trimmed.contains('not available');
}

int _scoreMatch(String question, String haystack) {
  final terms = question
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((term) => term.length > 2)
      .toSet();
  final text = haystack.toLowerCase();
  var score = 0;
  for (final term in terms) {
    if (text.contains(term)) {
      score++;
    }
  }
  return score;
}
