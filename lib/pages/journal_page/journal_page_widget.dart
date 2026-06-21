/// ------------------------------------------------------------
/// JournalScreen
///
/// Purpose:
/// Private local reflection journal.
///
/// Responsibilities:
/// - Create, edit, and delete journal entries.
/// - Support prompt-based entry creation from guidance and chapter flows.
/// - Optionally link entries to a verse or chapter reference.
/// - Count journaling as gentle reflection activity.
///
/// Data sources:
/// - LocalStorageService for all journal persistence.
///
/// User flow:
/// Journal should feel like guided reflection, not generic note taking. Prompts
/// help the user name what happened, understand what it revealed, and choose one
/// wise action without requiring cloud storage or an account.
///
/// Notes:
/// Journal text never leaves the device. Only lightweight local topic signals
/// are used for continuity so the app can feel personal without feeling watched.
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/local_storage_service.dart';
import '../gita_common/gita_common.dart';

class JournalPageWidget extends StatefulWidget {
  const JournalPageWidget({
    super.key,
    this.prefill,
    this.chapter,
  });

  static String routeName = 'JournalPage';
  static String routePath = '/journalPage';

  final String? prefill;
  final String? chapter;

  @override
  State<JournalPageWidget> createState() => _JournalPageWidgetState();
}

class _JournalPageWidgetState extends State<JournalPageWidget> {
  late Future<List<LocalJournalEntry>> _entriesFuture;
  bool _openedPrefillEditor = false;

  static const _reflectionPrompts = [
    'What disturbed your peace today?',
    'What gave you clarity today?',
    'What attachment can you soften?',
    'What insight stayed with you?',
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Some flows, such as Today's Guidance or chapter completion, open the
      // journal with a prefilled reflection prompt.
      if (!mounted || _openedPrefillEditor) {
        return;
      }
      final prefill = widget.prefill?.trim();
      if (prefill == null || prefill.isEmpty) {
        return;
      }
      _openedPrefillEditor = true;
      _showJournalEditor(
        context,
        initialTitle: prefill,
        initialText: '$prefill\n\n',
        initialLinkedVerse: _chapterReference,
        onSaved: () => setState(_refresh),
      );
    });
  }

  void _refresh() {
    // Reassigning the Future lets FutureBuilder reload after create/edit/delete.
    _entriesFuture = LocalStorageService.journalEntries();
  }

  String get _chapterReference {
    final chapter = widget.chapter?.trim();
    if (chapter == null || chapter.isEmpty) {
      return '';
    }
    return 'Bhagavad Gita Chapter $chapter';
  }

  String get _dailyPrompt {
    final now = DateTime.now();
    final dayKey = DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(now.year, 1, 1),
        )
        .inDays;
    return _reflectionPrompts[dayKey % _reflectionPrompts.length];
  }

  void _openGuidedReflection() {
    final prompt = _dailyPrompt;
    _showJournalEditor(
      context,
      initialTitle: widget.prefill,
      initialText: widget.prefill == null ? null : '${widget.prefill}\n\n',
      initialLinkedVerse: _chapterReference,
      reflectionPrompt: prompt,
      onSaved: () => setState(_refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      bottomNavIndex: 3,
      child: ListView(
        key: const PageStorageKey('journal_scroll_position'),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: gitaBottomNavScrollPadding(context)),
        children: [
          PageHeader(
            title: 'Journal',
            subtitle: 'A quiet place to understand your day',
            trailing: IconButton(
              tooltip: 'New journal entry',
              onPressed: _openGuidedReflection,
              icon: const Icon(Icons.add_circle_rounded, color: kGold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: Column(
              children: [
                AnimatedEntrance(
                  child: PremiumCard(
                    accent: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AccentPill('Guided Reflection'),
                        const SizedBox(height: 18),
                        Text(
                          _dailyPrompt,
                          style: gitaTitle(24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bhagavad Gita 2.47',
                          style: gitaBody(
                            color: kSoftGold,
                            weight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Name what happened, what it showed you, and one small step for today.',
                          style: gitaBody(
                            color: kMuted,
                            size: 14,
                            weight: FontWeight.w700,
                          ).copyWith(height: 1.42),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GoldButton(
                  label: 'Begin reflection',
                  icon: Icons.edit_note_rounded,
                  onPressed: _openGuidedReflection,
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent reflections',
                    style: gitaBody(
                      color: kText,
                      size: 18,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<LocalJournalEntry>>(
                  future: _entriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingStateCard(
                        message: 'Loading reflections...',
                      );
                    }
                    if (snapshot.hasError) {
                      debugPrint(
                          'Journal entries load failed: ${snapshot.error}');
                      return const _JournalEmptyState(
                        title: 'Your journal is resting for a moment.',
                        body: 'Please return in a little while.',
                      );
                    }
                    final entries = snapshot.data ?? const [];
                    if (entries.isEmpty) {
                      return const _JournalEmptyState(
                        title: 'Begin with one honest reflection.',
                        body:
                            'Let the prompt guide you. A few sincere lines are enough.',
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < entries.length; i++) ...[
                          AnimatedEntrance(
                            delay: Duration(milliseconds: 30 * i),
                            child: _JournalEntryCard(
                              entry: entries[i],
                              onChanged: () => setState(_refresh),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.onChanged,
  });

  final LocalJournalEntry entry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: gitaBody(color: kText, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AccentPill(entry.mood),
                        AccentPill(entry.formattedDate),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit entry',
                onPressed: () => _showJournalEditor(
                  context,
                  entry: entry,
                  onSaved: onChanged,
                ),
                icon: const Icon(Icons.edit_rounded, color: kGold),
              ),
              IconButton(
                tooltip: 'Remove reflection',
                onPressed: () => _deleteEntry(context),
                icon: const Icon(Icons.delete_outline_rounded, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kGold.withValues(alpha: 0.18)),
            ),
            child: Text(
              entry.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: gitaBody(color: kDarkText, size: 16).copyWith(height: 1.5),
            ),
          ),
          if (entry.intention.isNotEmpty ||
              entry.gratitude.isNotEmpty ||
              entry.actionStep.isNotEmpty ||
              entry.linkedVerse.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (entry.linkedVerse.isNotEmpty) AccentPill(entry.linkedVerse),
                if (entry.intention.isNotEmpty) const AccentPill('Intention'),
                if (entry.gratitude.isNotEmpty) const AccentPill('Gratitude'),
                if (entry.actionStep.isNotEmpty)
                  const AccentPill('Action step'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Remove reflection?', style: gitaTitle(22)),
        content: Text(
          'This reflection will be removed from this device.',
          style: gitaBody(color: kText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: gitaBody(color: kGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove Reflection', style: gitaBody(color: kGold)),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      return;
    }

    try {
      await LocalStorageService.deleteJournalEntry(entry.id);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection removed.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Journal delete failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove this reflection.')),
        );
      }
    }
  }
}

class _JournalEmptyState extends StatelessWidget {
  const _JournalEmptyState({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.edit_note_rounded,
      title: title,
      body: body,
    );
  }
}

Future<void> _showJournalEditor(
  BuildContext context, {
  LocalJournalEntry? entry,
  String? initialTitle,
  String? initialText,
  String? initialLinkedVerse,
  String? reflectionPrompt,
  required VoidCallback onSaved,
}) async {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _JournalEditorSheet(
      entry: entry,
      initialTitle: initialTitle,
      initialText: initialText,
      initialLinkedVerse: initialLinkedVerse,
      reflectionPrompt: reflectionPrompt,
      onSaved: onSaved,
    ),
  );
}

class _JournalEditorSheet extends StatefulWidget {
  const _JournalEditorSheet({
    this.entry,
    this.initialTitle,
    this.initialText,
    this.initialLinkedVerse,
    this.reflectionPrompt,
    required this.onSaved,
  });

  final LocalJournalEntry? entry;
  final String? initialTitle;
  final String? initialText;
  final String? initialLinkedVerse;
  final String? reflectionPrompt;
  final VoidCallback onSaved;

  @override
  State<_JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends State<_JournalEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _intentionController;
  late final TextEditingController _gratitudeController;
  late final TextEditingController _actionStepController;
  late final TextEditingController _linkedVerseController;
  final _scrollController = ScrollController();
  final _titleFocusNode = FocusNode();
  final _reflectionFocusNode = FocusNode();
  final _intentionFocusNode = FocusNode();
  final _gratitudeFocusNode = FocusNode();
  final _actionStepFocusNode = FocusNode();
  final _linkedVerseFocusNode = FocusNode();
  final _titleFieldKey = GlobalKey();
  final _reflectionFieldKey = GlobalKey();
  final _intentionFieldKey = GlobalKey();
  final _gratitudeFieldKey = GlobalKey();
  final _actionStepFieldKey = GlobalKey();
  final _linkedVerseFieldKey = GlobalKey();
  late String _mood;
  bool _isSaving = false;
  bool _hasContent = false;

  static const _moods = [
    'Peaceful',
    'Grateful',
    'Seeking',
    'Focused',
    'Heavy',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.entry?.title ?? widget.initialTitle ?? '',
    );
    _textController = TextEditingController(
      text: widget.entry?.text ?? widget.initialText ?? '',
    );
    _intentionController =
        TextEditingController(text: widget.entry?.intention ?? '');
    _gratitudeController =
        TextEditingController(text: widget.entry?.gratitude ?? '');
    _actionStepController =
        TextEditingController(text: widget.entry?.actionStep ?? '');
    _linkedVerseController = TextEditingController(
      text: widget.entry?.linkedVerse ?? widget.initialLinkedVerse ?? '',
    );
    _mood = widget.entry?.mood ?? _moods.first;
    for (final controller in _contentControllers) {
      controller.addListener(_updateSaveState);
    }
    for (final target in _focusTargets) {
      target.focusNode.addListener(() {
        if (target.focusNode.hasFocus) {
          _scrollFocusedFieldIntoView(target.fieldKey);
        }
      });
    }
    _hasContent = _hasAnyContent;
  }

  @override
  void dispose() {
    for (final controller in _contentControllers) {
      controller.removeListener(_updateSaveState);
    }
    _titleController.dispose();
    _textController.dispose();
    _intentionController.dispose();
    _gratitudeController.dispose();
    _actionStepController.dispose();
    _linkedVerseController.dispose();
    _titleFocusNode.dispose();
    _reflectionFocusNode.dispose();
    _intentionFocusNode.dispose();
    _gratitudeFocusNode.dispose();
    _actionStepFocusNode.dispose();
    _linkedVerseFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<TextEditingController> get _contentControllers => [
        _titleController,
        _textController,
        _intentionController,
        _gratitudeController,
        _actionStepController,
        _linkedVerseController,
      ];

  List<_FocusScrollTarget> get _focusTargets => [
        _FocusScrollTarget(_titleFocusNode, _titleFieldKey),
        _FocusScrollTarget(_reflectionFocusNode, _reflectionFieldKey),
        _FocusScrollTarget(_intentionFocusNode, _intentionFieldKey),
        _FocusScrollTarget(_gratitudeFocusNode, _gratitudeFieldKey),
        _FocusScrollTarget(_actionStepFocusNode, _actionStepFieldKey),
        _FocusScrollTarget(_linkedVerseFocusNode, _linkedVerseFieldKey),
      ];

  bool get _hasAnyContent => _contentControllers.any(
        (controller) => controller.text.trim().isNotEmpty,
      );

  void _updateSaveState() {
    final hasContent = _hasAnyContent;
    if (_hasContent == hasContent) {
      return;
    }
    setState(() => _hasContent = hasContent);
  }

  void _scrollFocusedFieldIntoView(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) {
        return;
      }
      final fieldContext = fieldKey.currentContext;
      if (fieldContext == null) {
        return;
      }
      if (!fieldContext.mounted) {
        return;
      }
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final safeBottom = mediaQuery.padding.bottom;
    final safeTop = mediaQuery.padding.top;
    final maxSheetHeight =
        (mediaQuery.size.height - safeTop - 28).clamp(320.0, 760.0);
    final saveBarBottom = bottomInset + safeBottom + 12;
    final scrollBottomPadding = saveBarBottom + 96;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        height: maxSheetHeight.toDouble(),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kLine),
          ),
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: scrollBottomPadding),
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.entry == null
                              ? 'New Reflection'
                              : 'Edit Reflection',
                          style: gitaTitle(24),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((widget.reflectionPrompt ?? '').trim().isNotEmpty) ...[
                      _ReflectionPromptCard(
                        prompt: widget.reflectionPrompt!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _JournalTextField(
                      fieldKey: _titleFieldKey,
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      label: 'Title',
                      minLines: 1,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mood',
                      style: gitaBody(color: kText, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mood in _moods)
                          ChoiceChip(
                            label: Text(mood),
                            selected: _mood == mood,
                            onSelected: (_) => setState(() => _mood = mood),
                            selectedColor: kRoyalPurple,
                            backgroundColor: kCard,
                            checkmarkColor: kSoftGold,
                            labelStyle: gitaBody(
                              color: kText,
                              weight: FontWeight.w800,
                            ),
                            side: const BorderSide(color: kLine),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _JournalTextField(
                      fieldKey: _reflectionFieldKey,
                      controller: _textController,
                      focusNode: _reflectionFocusNode,
                      label: 'Reflection',
                      hint:
                          'What happened? What did it reveal about your mind, attachment, fear, or peace?',
                      minLines: 8,
                      maxLines: 12,
                    ),
                    const SizedBox(height: 12),
                    _JournalTextField(
                      fieldKey: _intentionFieldKey,
                      controller: _intentionController,
                      focusNode: _intentionFocusNode,
                      label: 'Intention',
                      hint: 'What quality do you want to carry into the day?',
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _JournalTextField(
                      fieldKey: _gratitudeFieldKey,
                      controller: _gratitudeController,
                      focusNode: _gratitudeFocusNode,
                      label: 'Gratitude',
                      hint:
                          'What helped you, steadied you, or softened your heart?',
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _JournalTextField(
                      fieldKey: _actionStepFieldKey,
                      controller: _actionStepController,
                      focusNode: _actionStepFocusNode,
                      label: 'Action step',
                      hint: 'What is one small wise action you can take today?',
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _JournalTextField(
                      fieldKey: _linkedVerseFieldKey,
                      controller: _linkedVerseController,
                      focusNode: _linkedVerseFocusNode,
                      label: 'Linked verse',
                      minLines: 1,
                      maxLines: 1,
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  bottom: saveBarBottom,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kNavy2,
                      boxShadow: [
                        BoxShadow(
                          color: kNavy.withValues(alpha: 0.72),
                          blurRadius: 18,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: GoldButton(
                      label: 'Save Reflection',
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _hasContent ? _save : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    final intention = _intentionController.text.trim();
    final gratitude = _gratitudeController.text.trim();
    final actionStep = _actionStepController.text.trim();
    final linkedVerse = _linkedVerseController.text.trim();
    debugPrint('Journal reflection save tapped');
    final hasContent = [
      title,
      text,
      intention,
      gratitude,
      actionStep,
      linkedVerse,
    ].any((value) => value.isNotEmpty);
    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write one reflection before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final resolvedTitle =
          title.isEmpty ? _fallbackTitle(text, intention, gratitude) : title;
      final resolvedText = text.isEmpty
          ? _fallbackReflectionText(
              intention: intention,
              gratitude: gratitude,
              actionStep: actionStep,
            )
          : text;
      final entry = widget.entry == null
          ? LocalJournalEntry.create(
              title: resolvedTitle,
              text: resolvedText,
              mood: _mood,
              intention: intention,
              gratitude: gratitude,
              actionStep: actionStep,
              linkedVerse: linkedVerse,
            )
          : widget.entry!.copyWith(
              title: resolvedTitle,
              text: resolvedText,
              mood: _mood,
              intention: intention,
              gratitude: gratitude,
              actionStep: actionStep,
              linkedVerse: linkedVerse,
            );
      debugPrint('Journal reflection entry created: ${entry.id}');
      await LocalStorageService.upsertJournalEntry(entry);
      final savedEntries = await LocalStorageService.journalEntries();
      final persisted = savedEntries.any((item) => item.id == entry.id);
      debugPrint(
        'Journal reflection storage load success: ${savedEntries.length} entries',
      );
      if (!persisted) {
        throw StateError('Journal reflection was not found after save.');
      }
      HapticFeedback.lightImpact();
      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Journal save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your reflection. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _fallbackTitle(String text, String intention, String gratitude) {
    final source = [text, intention, gratitude].firstWhere(
      (value) => value.trim().isNotEmpty,
      orElse: () => 'Today\'s reflection',
    );
    final normalized = source.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 42) {
      return normalized;
    }
    return '${normalized.substring(0, 42).trim()}...';
  }

  String _fallbackReflectionText({
    required String intention,
    required String gratitude,
    required String actionStep,
  }) {
    final lines = [
      if (intention.isNotEmpty) 'Intention: $intention',
      if (gratitude.isNotEmpty) 'Gratitude: $gratitude',
      if (actionStep.isNotEmpty) 'Action step: $actionStep',
    ];
    return lines.isEmpty ? 'Quiet reflection.' : lines.join('\n');
  }
}

class _FocusScrollTarget {
  const _FocusScrollTarget(this.focusNode, this.fieldKey);

  final FocusNode focusNode;
  final GlobalKey fieldKey;
}

class _ReflectionPromptCard extends StatelessWidget {
  const _ReflectionPromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGold.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.self_improvement_rounded, color: kGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reflection prompt',
                  style: gitaBody(
                    color: kRoyalPurple,
                    size: 11,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  prompt,
                  style: gitaBody(
                    color: kDarkText,
                    size: 15,
                    weight: FontWeight.w800,
                  ).copyWith(height: 1.42),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer simply. A few honest lines are enough.',
                  style: gitaBody(
                    color: kDarkText.withValues(alpha: 0.72),
                    size: 13,
                    weight: FontWeight.w700,
                  ).copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalTextField extends StatelessWidget {
  const _JournalTextField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.label,
    this.hint,
    required this.minLines,
    required this.maxLines,
  });

  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: fieldKey,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        minLines: minLines,
        maxLines: maxLines,
        style: gitaBody(color: kDarkText, size: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: gitaBody(color: kCard2),
          hintStyle: gitaBody(
            color: kCard2.withValues(alpha: 0.62),
            size: 14,
          ).copyWith(height: 1.35),
          filled: true,
          fillColor: kCream,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kGold),
          ),
        ),
      ),
    );
  }
}
