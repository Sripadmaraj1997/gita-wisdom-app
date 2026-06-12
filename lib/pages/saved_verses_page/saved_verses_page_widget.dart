// Saved wisdom library.
//
// Combines three local collections: saved verses, highlighted verse IDs, and
// saved reflections. Highlight IDs are resolved through GitaDataService so the
// UI always displays the latest local scripture data.
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
    final highlightIds = await LocalStorageService.highlightedVerseIds();
    final bundle = await GitaDataService.load();
    final highlighted = highlightIds
        .map(bundle.verseById)
        .whereType<GitaVerseData>()
        .toList()
      ..sort((a, b) {
        final chapter = a.chapterNumber.compareTo(b.chapterNumber);
        return chapter == 0 ? a.verseNumber.compareTo(b.verseNumber) : chapter;
      });
    return _SavedLibraryData(
      saved: saved,
      highlighted: highlighted,
      reflections: savedReflections,
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
            subtitle: 'Private verses and reflections to return to',
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
                    data.reflections.isEmpty) {
                  return const _SavedVersesEmptyState(
                    title: 'No saved wisdom yet.',
                    body:
                        'Peace often begins with a single verse. Save wisdom you want to return to.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SavedLibraryTabs(
                      selectedIndex: _selectedTab,
                      onSelected: (index) =>
                          setState(() => _selectedTab = index),
                    ),
                    const SizedBox(height: 18),
                    if (_selectedTab == 0)
                      _SavedVersesList(
                        saved: data.saved,
                        highlighted: data.highlighted,
                        onRemoved: () => setState(_refresh),
                      )
                    else
                      _SavedReflectionsList(
                        reflections: data.reflections,
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
  });

  const _SavedLibraryData.empty()
      : saved = const [],
        highlighted = const [],
        reflections = const [];

  final List<LocalSavedVerse> saved;
  final List<GitaVerseData> highlighted;
  final List<LocalSavedReflection> reflections;
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
                ? kGold.withValues(alpha: 0.45)
                : kLine.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? kSoftGold : kText, size: 17),
            const SizedBox(width: 7),
            Flexible(
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
        body: 'Begin with one verse that steadies your heart.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlighted.isNotEmpty) ...[
          const _SavedSectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'My Highlights',
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
            title: 'Saved Wisdom',
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
    required this.onRemoved,
  });

  final List<LocalSavedReflection> reflections;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    if (reflections.isEmpty) {
      return const _SavedVersesEmptyState(
        title: 'No saved reflections yet.',
        body: 'Begin your reflection journey with one note worth carrying.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SavedSectionHeader(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Saved Reflections',
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
        Icon(icon, color: kSoftGold, size: 18),
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
    return PremiumCard(
      accent: true,
      onTap: () => context.push(Uri(
        path: '/verseReaderPage',
        queryParameters: {'verseId': verse.id},
      ).toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AccentPill('Highlighted'),
              const SizedBox(width: 8),
              AccentPill(verse.shortReference),
              const Spacer(),
              IconButton(
                tooltip: 'Remove highlight',
                onPressed: () => _removeHighlight(context),
                icon: const Icon(Icons.auto_awesome_rounded, color: kSoftGold),
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
            verse.meaning.trim().isEmpty
                ? 'Reflect on this verse as guidance for steady action, inner clarity, and peaceful living.'
                : verse.meaning,
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
          const SnackBar(content: Text('Highlight removed.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Remove highlight failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove highlight.')),
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
        queryParameters: {'verseId': verse.verseId},
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
                icon: const Icon(Icons.bookmark_remove_rounded, color: kGold),
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
          const SnackBar(content: Text('Verse removed from saved.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Remove saved verse failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove saved verse.')),
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
        queryParameters: {'verseId': reflection.verseId},
      ).toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentPill(reflection.verseReference),
              const Spacer(),
              IconButton(
                tooltip: 'Remove saved reflection',
                onPressed: () => _removeSavedReflection(context),
                icon: const Icon(Icons.delete_outline_rounded, color: kGold),
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
          const SnackBar(content: Text('Reflection removed.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Remove saved reflection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove reflection.')),
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
