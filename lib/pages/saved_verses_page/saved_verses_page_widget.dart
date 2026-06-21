/// ------------------------------------------------------------
/// SavedWisdomScreen
///
/// Purpose:
/// Private local library for saved verses, highlights, and reflections.
///
/// Responsibilities:
/// - Load saved verse snapshots.
/// - Resolve highlighted verse IDs against the latest local Gita dataset.
/// - Display saved reflections and Practice Today prompts.
/// - Support removing local saved items.
///
/// Data sources:
/// - LocalStorageService for user-owned saved data.
/// - GitaDataService for current scripture text behind highlight IDs.
///
/// Notes:
/// Highlights store IDs instead of full verse text so scripture display remains
/// consistent if the bundled local dataset is refined later.
/// ------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart';
import '../../services/local_storage_service.dart';
import '../gita_common/gita_common.dart';

class SavedVersesPageWidget extends StatefulWidget {
  const SavedVersesPageWidget({super.key});

  static String routeName = 'SavedVersesPage';
  static String routePath = '/savedVersesPage';

  @override
  State<SavedVersesPageWidget> createState() => _SavedVersesPageWidgetState();
}

class _SavedVersesPageWidgetState extends State<SavedVersesPageWidget> {
  late Future<_SavedLibraryData> _savedLibraryFuture;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _savedLibraryFuture = _loadSavedLibrary();
  }

  Future<_SavedLibraryData> _loadSavedLibrary() async {
    // Load user-owned data first, then resolve highlighted IDs against the
    // static Gita bundle. Missing IDs are ignored gracefully.
    final saved = await LocalStorageService.savedVerses();
    final savedReflections = await LocalStorageService.savedReflections();
    final journalEntries = await LocalStorageService.journalEntries();
    final highlightIds = await LocalStorageService.highlightedVerseIds();
    final highlighted = <GitaVerseData>[];
    if (highlightIds.isNotEmpty) {
      final bundle = await GitaDataService.load();
      highlighted.addAll(
        highlightIds.map(bundle.verseById).whereType<GitaVerseData>(),
      );
      highlighted.sort((a, b) {
        final chapter = a.chapterNumber.compareTo(b.chapterNumber);
        return chapter == 0 ? a.verseNumber.compareTo(b.verseNumber) : chapter;
      });
    }
    return _SavedLibraryData(
      saved: saved,
      highlighted: highlighted,
      reflections: savedReflections,
      journalEntries: journalEntries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      child: ListView(
        key: const PageStorageKey('saved_verses_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 42),
        children: [
          const PageHeader(
            title: 'Saved Wisdom',
            subtitle: 'Return to the verses and reflections you want to live',
            showBack: true,
            trailing: Icon(Icons.bookmark_rounded, color: kGold),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: FutureBuilder<_SavedLibraryData>(
              future: _savedLibraryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingStateCard(
                    message: 'Loading saved wisdom...',
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('Saved verses load failed: ${snapshot.error}');
                  return const _SavedVersesEmptyState(
                    title: 'Saved wisdom is resting for a moment.',
                    body: 'Please return in a little while.',
                  );
                }

                final data = snapshot.data ?? const _SavedLibraryData.empty();
                if (data.saved.isEmpty &&
                    data.highlighted.isEmpty &&
                    data.reflections.isEmpty &&
                    data.journalEntries.isEmpty) {
                  return const _SavedVersesEmptyState(
                    title: 'Your wisdom collection is empty.',
                    body:
                        'Save one verse or reflection when it gives you an insight, an action, or a reason to return.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (context) {
                      final hasVerseContent =
                          data.saved.isNotEmpty || data.highlighted.isNotEmpty;
                      final hasReflectionContent =
                          data.reflections.isNotEmpty ||
                              data.journalEntries.isNotEmpty;
                      final selectedTab =
                          !hasVerseContent && hasReflectionContent
                              ? 1
                              : _selectedTab;
                      return _SavedLibraryTabs(
                        selectedIndex: selectedTab,
                        onSelected: (index) =>
                            setState(() => _selectedTab = index),
                      );
                    }),
                    const SizedBox(height: 18),
                    if ((data.saved.isEmpty &&
                            data.highlighted.isEmpty &&
                            (data.reflections.isNotEmpty ||
                                data.journalEntries.isNotEmpty))
                        ? false
                        : _selectedTab == 0)
                      _SavedVersesList(
                        saved: data.saved,
                        highlighted: data.highlighted,
                        onRemoved: () => setState(_refresh),
                      )
                    else
                      _SavedReflectionsList(
                        reflections: data.reflections,
                        journalEntries: data.journalEntries,
                        onRemoved: () => setState(_refresh),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedLibraryData {
  const _SavedLibraryData({
    required this.saved,
    required this.highlighted,
    required this.reflections,
    required this.journalEntries,
  });

  const _SavedLibraryData.empty()
      : saved = const [],
        highlighted = const [],
        reflections = const [],
        journalEntries = const [];

  final List<LocalSavedVerse> saved;
  final List<GitaVerseData> highlighted;
  final List<LocalSavedReflection> reflections;
  final List<LocalJournalEntry> journalEntries;
}

class _SavedLibraryTabs extends StatelessWidget {
  const _SavedLibraryTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // Two tabs keep the screen simple while still exposing both verse-level
    // saves and reflection saves.
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _SavedLibraryTab(
              label: 'Saved Wisdom',
              icon: Icons.bookmark_rounded,
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SavedLibraryTab(
              label: 'Reflections',
              icon: Icons.lightbulb_outline_rounded,
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedLibraryTab extends StatelessWidget {
  const _SavedLibraryTab({
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
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kRoyalPurple : kCard2.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? kSoftGold.withValues(alpha: 0.34)
                : kLine.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kText, size: 17),
            const SizedBox(width: 7),
            Flexible(
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

class _SavedVersesList extends StatelessWidget {
  const _SavedVersesList({
    required this.saved,
    required this.highlighted,
    required this.onRemoved,
  });

  final List<LocalSavedVerse> saved;
  final List<GitaVerseData> highlighted;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    if (saved.isEmpty && highlighted.isEmpty) {
      return const _SavedVersesEmptyState(
        title: 'No saved verses yet.',
        body:
            'When a verse steadies you, save it here and return to practice it again.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlighted.isNotEmpty) ...[
          const _SavedSectionHeader(
            icon: Icons.edit_note_rounded,
            title: 'Verses to Revisit',
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < highlighted.length; i++) ...[
            AnimatedEntrance(
              delay: Duration(milliseconds: 30 * i),
              child: _HighlightedVerseCard(
                verse: highlighted[i],
                onRemoved: onRemoved,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
        if (saved.isNotEmpty) ...[
          const _SavedSectionHeader(
            icon: Icons.bookmark_rounded,
            title: 'Verses to Practice',
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < saved.length; i++) ...[
            AnimatedEntrance(
              delay: Duration(milliseconds: 30 * i),
              child: _SavedVerseCard(
                verse: saved[i],
                onRemoved: onRemoved,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ],
    );
  }
}

class _SavedReflectionsList extends StatelessWidget {
  const _SavedReflectionsList({
    required this.reflections,
    required this.journalEntries,
    required this.onRemoved,
  });

  final List<LocalSavedReflection> reflections;
  final List<LocalJournalEntry> journalEntries;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    if (reflections.isEmpty && journalEntries.isEmpty) {
      return const _SavedVersesEmptyState(
        title: 'No saved reflections yet.',
        body:
            'Save reflections that help you understand yourself and choose one wiser action.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (journalEntries.isNotEmpty) ...[
          const _SavedSectionHeader(
            icon: Icons.edit_note_rounded,
            title: 'Journal Reflections',
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < journalEntries.length; i++) ...[
            AnimatedEntrance(
              delay: Duration(milliseconds: 30 * i),
              child: _SavedJournalEntryCard(entry: journalEntries[i]),
            ),
            const SizedBox(height: 18),
          ],
        ],
        if (reflections.isNotEmpty) ...[
          const _SavedSectionHeader(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Verse Reflections',
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < reflections.length; i++) ...[
            AnimatedEntrance(
              delay: Duration(milliseconds: 30 * i),
              child: _SavedReflectionCard(
                reflection: reflections[i],
                onRemoved: onRemoved,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ],
      ],
    );
  }
}

class _SavedJournalEntryCard extends StatelessWidget {
  const _SavedJournalEntryCard({required this.entry});

  final LocalJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentPill(entry.formattedDate),
              if (entry.linkedVerse.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(child: AccentPill(entry.linkedVerse)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            entry.title,
            style: gitaBody(color: kText, size: 16, weight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGold.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.text.trim().isNotEmpty)
                  Text(
                    entry.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: gitaBody(color: kDarkText, size: 14)
                        .copyWith(height: 1.5),
                  ),
                if (entry.intention.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SavedJournalLine(label: 'Intention', text: entry.intention),
                ],
                if (entry.gratitude.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SavedJournalLine(label: 'Gratitude', text: entry.gratitude),
                ],
                if (entry.actionStep.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SavedJournalLine(
                    label: 'Practice Today',
                    text: entry.actionStep,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedJournalLine extends StatelessWidget {
  const _SavedJournalLine({
    required this.label,
    required this.text,
  });

  final String label;
  final String text;

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
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: gitaBody(
            color: kDarkText,
            size: 14,
            weight: FontWeight.w800,
          ).copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _SavedSectionHeader extends StatelessWidget {
  const _SavedSectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kMuted, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: gitaBody(color: kText, size: 18, weight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _HighlightedVerseCard extends StatelessWidget {
  const _HighlightedVerseCard({
    required this.verse,
    required this.onRemoved,
  });

  final GitaVerseData verse;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final interpretation = verse.gitaWisdomInterpretation.trim();
    return PremiumCard(
      accent: true,
      onTap: () => context.push(Uri(
        path: '/verseReaderPage',
        queryParameters: {
          'verseId': verse.id,
          'source': 'savedWisdom',
        },
      ).toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AccentPill('Marked'),
              const SizedBox(width: 8),
              AccentPill(verse.shortReference),
              const Spacer(),
              IconButton(
                tooltip: 'Remove mark',
                onPressed: () => _removeHighlight(context),
                icon: const Icon(Icons.edit_note_rounded, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGold.withValues(alpha: 0.24)),
            ),
            child: Text(
              verse.englishTranslation,
              style: gitaBody(
                color: kDarkText,
                size: 16,
                weight: FontWeight.w800,
              ).copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            interpretation.isEmpty
                ? 'Reflect on this verse as guidance for steady action, inner clarity, and peaceful living.'
                : interpretation,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: gitaBody(color: kMuted, size: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _removeHighlight(BuildContext context) async {
    try {
      await LocalStorageService.setVerseHighlighted(
        verse.id,
        highlighted: false,
      );
      onRemoved();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mark removed.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Remove highlight failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove this mark.')),
        );
      }
    }
  }
}

class _SavedVerseCard extends StatelessWidget {
  const _SavedVerseCard({
    required this.verse,
    required this.onRemoved,
  });

  final LocalSavedVerse verse;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      onTap: () => context.push(Uri(
        path: '/verseReaderPage',
        queryParameters: {
          'verseId': verse.verseId,
          'source': 'savedWisdom',
        },
      ).toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentPill(verse.reference),
              const Spacer(),
              IconButton(
                tooltip: 'Remove saved verse',
                onPressed: () => _removeSavedVerse(context),
                icon: const Icon(Icons.bookmark_remove_rounded, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(verse.sanskrit, style: gitaSanskrit(21)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kGold.withValues(alpha: 0.18)),
            ),
            child: Text(
              verse.translation,
              style: gitaBody(color: kDarkText, size: 16),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: kMuted),
              Spacer(),
              Icon(Icons.chevron_right_rounded, color: kMuted),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removeSavedVerse(BuildContext context) async {
    try {
      await LocalStorageService.removeSavedVerse(verse.verseId);
      onRemoved();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verse released from Saved Wisdom.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Remove saved verse failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not release this verse.')),
        );
      }
    }
  }
}

class _SavedReflectionCard extends StatelessWidget {
  const _SavedReflectionCard({
    required this.reflection,
    required this.onRemoved,
  });

  final LocalSavedReflection reflection;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      accent: true,
      onTap: () => context.push(Uri(
        path: '/verseReaderPage',
        queryParameters: {
          'verseId': reflection.verseId,
          'source': 'savedWisdom',
        },
      ).toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentPill(reflection.verseReference),
              const Spacer(),
              IconButton(
                tooltip: 'Remove reflection',
                onPressed: () => _removeSavedReflection(context),
                icon: const Icon(Icons.close_rounded, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGold.withValues(alpha: 0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reflection.reflection.trim().isNotEmpty) ...[
                  Text(
                    'Reflection',
                    style: gitaBody(
                      color: kRoyalPurple,
                      size: 11,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    reflection.reflection,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: gitaBody(color: kDarkText, size: 14)
                        .copyWith(height: 1.5),
                  ),
                ],
                if (reflection.practiceToday.trim().isNotEmpty) ...[
                  if (reflection.reflection.trim().isNotEmpty)
                    const SizedBox(height: 14),
                  Text(
                    'Practice Today',
                    style: gitaBody(
                      color: kRoyalPurple,
                      size: 11,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    reflection.practiceToday,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: gitaBody(
                      color: kDarkText,
                      size: 14,
                      weight: FontWeight.w800,
                    ).copyWith(height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reflection.englishTranslation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: gitaBody(color: kMuted, size: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSavedReflection(BuildContext context) async {
    try {
      await LocalStorageService.removeSavedReflection(reflection.verseId);
      onRemoved();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection released.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Remove saved reflection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not release this reflection.')),
        );
      }
    }
  }
}

class _SavedVersesEmptyState extends StatelessWidget {
  const _SavedVersesEmptyState({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.bookmark_border_rounded,
      title: title,
      body: body,
    );
  }
}
