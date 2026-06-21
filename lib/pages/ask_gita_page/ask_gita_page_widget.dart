/// ------------------------------------------------------------
/// AskGitaScreen
///
/// Purpose:
/// Local, retrieval-based spiritual guidance screen.
///
/// Responsibilities:
/// - Accept suggested or typed user questions.
/// - Render the required answer structure: Guidance, Verse, Meaning,
///   Reflection, Practice Today, and Source.
/// - Save completed guidance locally for continuity.
/// - Keep the experience calm and practical rather than conversationally noisy.
///
/// Data sources:
/// - AskGitaLiteService for deterministic local guidance.
/// - GitaRepository for verified local verse translations.
/// - LocalStorageService for private local history.
///
/// User flow:
/// A user brings one concern, receives one relevant verse, reflects on what it
/// means, and leaves with one practice to try today. Suggested questions and
/// typed questions use the same deterministic local service.
///
/// Answer contract:
/// 1. Gentle Guidance
/// 2. Relevant Verse
/// 3. Meaning
/// 4. Reflection
/// 5. Practice Today
/// 6. Source
///
/// Notes:
/// The goal is practical wisdom, not chatbot conversation. This screen avoids
/// OpenAI, Firebase, and backend calls so guidance remains private, reviewable,
/// and available offline.
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart';
import '../../services/ask_gita_lite_service.dart';
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

  AskGitaLiteAnswer? _guidance;
  String? _emptyMessage;
  String? _selectedQuestion;
  bool _hasQuestionText = false;
  bool _isLoading = false;

  static const _suggestedQuestions = [
    'How do I stop worrying?',
    'How do I handle anger?',
    'I feel overwhelmed at work.',
    'How do I let go of attachment?',
    'How do I find peace?',
  ];

  @override
  void initState() {
    super.initState();
    final initialQuestion = widget.initialQuestion?.trim();
    if (initialQuestion != null && initialQuestion.isNotEmpty) {
      _questionController.text = initialQuestion;
      _selectedQuestion = initialQuestion;
      _hasQuestionText = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _generateAnswer(initialQuestion);
        }
      });
    }
    _questionController.addListener(_handleQuestionTextChanged);
  }

  @override
  void dispose() {
    _questionController.removeListener(_handleQuestionTextChanged);
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleQuestionTextChanged() {
    final hasQuestionText = _questionController.text.trim().isNotEmpty;
    if (hasQuestionText == _hasQuestionText) {
      return;
    }
    setState(() {
      _hasQuestionText = hasQuestionText;
    });
  }

  void _selectSuggestedQuestion(String question) {
    debugPrint('AskGita suggested question tapped: $question');
    _questionController.value = TextEditingValue(
      text: question,
      selection: TextSelection.collapsed(offset: question.length),
    );
    setState(() {
      _selectedQuestion = question;
      _hasQuestionText = question.trim().isNotEmpty;
      _emptyMessage = null;
    });
  }

  Future<void> _submitQuestion() async {
    debugPrint('AskGita send tapped');
    if (_isLoading) {
      return;
    }

    final question = _questionController.text.trim();
    debugPrint('AskGita resolved question text: $question');
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question.')),
      );
      return;
    }

    if (_selectedQuestion != null && _selectedQuestion != question) {
      setState(() {
        _selectedQuestion = null;
      });
    }

    await _generateAnswer(question);
  }

  Future<void> _generateAnswer(String question) async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _guidance = null;
      _emptyMessage = null;
    });

    try {
      // Answer flow stays local and deterministic: map the concern to a
      // hand-curated topic profile, retrieve a local verse, and render the
      // six-part guidance structure.
      final guidance = await AskGitaLiteService.answer(question);

      if (!mounted) {
        return;
      }

      setState(() {
        _guidance = guidance;
        _isLoading = false;
      });
      debugPrint('AskGita answer generated: ${guidance.source}');
      await LocalStorageService.recordAskGitaHistory(
        question: question,
        answer: guidance.gentleGuidance,
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
            'Begin with what you are carrying. A verse and one small practice can help steady the next step.';
        _isLoading = false;
      });
      _scrollGentlyToAnswer();
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
                // Answer content scrolls independently from the composer so
                // the keyboard can appear without hiding the question field.
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  22,
                  24,
                  gitaFixedControlsScrollPadding(
                    context,
                    controlsHeight: 86,
                  ),
                ),
                children: [
                  _AskHeader(onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/homePage');
                    }
                  }),
                  const SizedBox(height: 22),
                  // Question matching entry points:
                  // These examples seed common emotional concerns while still
                  // using the same local AskGitaLiteService as typed questions.
                  _SuggestedQuestionGrid(
                    questions: _suggestedQuestions,
                    isDisabled: _isLoading,
                    selectedQuestion: _selectedQuestion,
                    onTap: (question) {
                      _selectSuggestedQuestion(question);
                    },
                  ),
                  const SizedBox(height: 22),
                  if (_isLoading)
                    const _ReflectionLoadingCard()
                  else if (_guidance != null)
                    // Answer structure:
                    // AskGitaLiteService always returns the six-part response
                    // contract so the UI never has to assemble generic copy.
                    _GuidanceResultCard(guidance: _guidance!)
                  else if (_emptyMessage != null)
                    // Fallback behavior:
                    // Retrieval failures stay calm and practical. The screen
                    // does not expose stack traces or empty answer states.
                    _EmptyAskState(message: _emptyMessage!)
                  else
                    const _QuietStartCard(),
                ],
              ),
            ),
            // The composer is fixed at the bottom of the screen. Scroll
            // padding above reserves space for it on small phones.
            _QuestionComposer(
              controller: _questionController,
              isLoading: _isLoading,
              hasQuestionText: _hasQuestionText,
              onSubmit: _submitQuestion,
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
                icon: Icons.self_improvement_rounded,
                size: 50,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ask Gita', style: gitaTitle(28)),
                    const SizedBox(height: 4),
                    Text(
                      'Bring what you are carrying. Read with calm attention.',
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
                    'These reflections support spiritual learning from the Bhagavad Gita. They are not medical, legal, financial, or mental health advice.',
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
    required this.selectedQuestion,
    required this.onTap,
  });

  final List<String> questions;
  final bool isDisabled;
  final String? selectedQuestion;
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
                  color: kSoftGold, size: 19),
              const SizedBox(width: 8),
              Text(
                'Begin with one question',
                style: gitaBody(color: kText, weight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Choose one, then read slowly.',
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
                        isSelected: selectedQuestion == question,
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
    required this.isSelected,
    required this.onTap,
  });

  final String question;
  final bool isDisabled;
  final bool isSelected;
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
          border: Border.all(
            color: isSelected
                ? kSoftGold.withValues(alpha: 0.40)
                : kGold.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.spa_rounded,
              color: isSelected ? kSoftGold : kMuted,
              size: 18,
            ),
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
    required this.hasQuestionText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool hasQuestionText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 0,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kCard.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: kGold.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: kDeepBrinjal.withValues(alpha: 0.18),
                blurRadius: 20,
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
                  border: Border.all(color: kGold.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: kDeepBrinjal.withValues(alpha: 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  color: kSoftGold,
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
                  style: gitaBody(color: kDarkText, size: 16),
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    hintText: 'What are you carrying today?',
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
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend =
                      hasQuestionText || value.text.trim().isNotEmpty;
                  final visuallyEnabled = canSend && !isLoading;
                  return Opacity(
                    opacity: visuallyEnabled ? 1 : 0.58,
                    child: AnimatedGoldIconButton(
                      icon: Icons.send_rounded,
                      isBusy: isLoading,
                      tooltip: 'Send',
                      backgroundColor: visuallyEnabled ? null : kCard2,
                      onTap: isLoading ? null : onSubmit,
                    ),
                  );
                },
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
              'Opening a steady verse...',
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
      title: 'Bring one honest question.',
      body:
          'Share what you are carrying. Ask Gita will offer a verse, calm guidance, and one small practice.',
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
              style: gitaBody(color: kText, size: 16).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceResultCard extends StatelessWidget {
  const _GuidanceResultCard({required this.guidance});

  final AskGitaLiteAnswer guidance;

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
            _GuidanceSection(
              icon: Icons.menu_book_rounded,
              title: 'Relevant Verse',
              child: _RelevantVersePanel(verse: guidance.verse),
            ),
            const SizedBox(height: 20),
            _GuidanceSection(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Meaning',
              child: Text(
                guidance.meaning,
                style:
                    gitaBody(color: kDarkText, size: 16).copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            _GuidanceSection(
              icon: Icons.favorite_border_rounded,
              title: 'Reflection',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guidance.reflection,
                    style: gitaBody(color: kDarkText, size: 16)
                        .copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What is one thing you will remember from this today?',
                    style: gitaTransliteration(
                      color: kRoyalPurple.withValues(alpha: 0.78),
                      size: 14,
                    ).copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _GuidanceSection(
              icon: Icons.spa_rounded,
              title: 'Practice Today',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guidance.practiceToday,
                    style: gitaBody(
                      color: kDarkText,
                      size: 16,
                      weight: FontWeight.w800,
                    ).copyWith(height: 1.58),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Return to this once today when the same feeling appears.',
                    style: gitaTransliteration(
                      color: kRoyalPurple.withValues(alpha: 0.78),
                      size: 14,
                    ).copyWith(height: 1.45),
                  ),
                ],
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
          if (_hasUsefulText(verse.englishTranslation))
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

  final AskGitaLiteAnswer guidance;

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
          Text(
            guidance.source,
            style: gitaBody(color: kDarkText, size: 13),
          ),
        ],
      ),
    );
  }
}

bool _hasUsefulText(String value) {
  final trimmed = value.trim().toLowerCase();
  return trimmed.isNotEmpty &&
      !trimmed.contains('unavailable') &&
      !trimmed.contains('not available');
}
