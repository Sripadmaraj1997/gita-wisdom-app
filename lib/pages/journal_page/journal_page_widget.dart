// Local journal screen.
//
// Journal entries are private to the device and stored through
// LocalStorageService. The screen supports prompt-based creation, editing,
// deletion, and optional verse/chapter references without requiring login.
import 'package:flutter/material.dart';

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
    const prompts = [
      'What disturbed your peace today?',
      'What attachment are you holding onto?',
      'What gave you clarity today?',
      'What duty can you do with love today?',
    ];
    final now = DateTime.now();
    final dayKey = DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(now.year, 1, 1),
        )
        .inDays;
    return prompts[dayKey % prompts.length];
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      bottomNavIndex: 3,
      child: ListView(
        key: const PageStorageKey('journal_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          PageHeader(
            title: 'Journal',
            subtitle: 'Private reflections stored on this device',
            trailing: IconButton(
              tooltip: 'New journal entry',
              onPressed: () => _showJournalEditor(
                context,
                initialTitle: widget.prefill,
                initialText:
                    widget.prefill == null ? null : '${widget.prefill}\n\n',
                initialLinkedVerse: _chapterReference,
                onSaved: () => setState(_refresh),
              ),
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
                        const AccentPill('Prompt'),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GoldButton(
                  label: 'Create reflection',
                  icon: Icons.edit_note_rounded,
                  onPressed: () => _showJournalEditor(
                    context,
                    initialTitle: widget.prefill,
                    initialText:
                        widget.prefill == null ? null : '${widget.prefill}\n\n',
                    initialLinkedVerse: _chapterReference,
                    onSaved: () => setState(_refresh),
                  ),
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
                        title: 'Could not load journal.',
                        body: 'Your local journal data could not be read.',
                      );
                    }
                    final entries = snapshot.data ?? const [];
                    if (entries.isEmpty) {
                      return const _JournalEmptyState(
                        title: 'Begin your reflection journey.',
                        body:
                            'Write one thought that brought you clarity today.',
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
                tooltip: 'Delete entry',
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
              style: gitaBody(color: kDarkText, size: 14).copyWith(height: 1.5),
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
        title: Text('Delete reflection?', style: gitaTitle(22)),
        content: Text(
          'This journal entry will be removed from this device.',
          style: gitaBody(color: kText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: gitaBody(color: kGold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: gitaBody(color: kSaffron)),
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
          const SnackBar(content: Text('Journal entry deleted.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Journal delete failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete journal entry.')),
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
    required this.onSaved,
  });

  final LocalJournalEntry? entry;
  final String? initialTitle;
  final String? initialText;
  final String? initialLinkedVerse;
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
  late String _mood;
  bool _isSaving = false;

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
      text: widget.entry?.title ?? widget.initialTitle ?? 'Today\'s reflection',
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _intentionController.dispose();
    _gratitudeController.dispose();
    _actionStepController.dispose();
    _linkedVerseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kNavy2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kLine),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _JournalTextField(
                  controller: _titleController,
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
                  controller: _textController,
                  label: 'Reflection',
                  minLines: 8,
                  maxLines: 12,
                ),
                const SizedBox(height: 12),
                _JournalTextField(
                  controller: _intentionController,
                  label: 'Intention',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _JournalTextField(
                  controller: _gratitudeController,
                  label: 'Gratitude',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _JournalTextField(
                  controller: _actionStepController,
                  label: 'Action step',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _JournalTextField(
                  controller: _linkedVerseController,
                  label: 'Linked verse',
                  minLines: 1,
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                GoldButton(
                  label: 'Save reflection',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _save,
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
    if (title.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title and reflection.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final entry = widget.entry == null
          ? LocalJournalEntry.create(
              title: title,
              text: text,
              mood: _mood,
              intention: intention,
              gratitude: gratitude,
              actionStep: actionStep,
              linkedVerse: linkedVerse,
            )
          : widget.entry!.copyWith(
              title: title,
              text: text,
              mood: _mood,
              intention: intention,
              gratitude: gratitude,
              actionStep: actionStep,
              linkedVerse: linkedVerse,
            );
      await LocalStorageService.upsertJournalEntry(entry);
      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Journal save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save journal entry.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _JournalTextField extends StatelessWidget {
  const _JournalTextField({
    required this.controller,
    required this.label,
    required this.minLines,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: gitaBody(color: kDarkText, size: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: gitaBody(color: kCard2),
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
    );
  }
}
