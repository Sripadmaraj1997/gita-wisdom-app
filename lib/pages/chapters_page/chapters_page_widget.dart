// Read / Chapters screen.
//
// Displays the 18 local Bhagavad Gita chapters and a lightweight chapter/verse
// search. Chapter cards open VerseReaderScreen at verse 1 of the selected
// chapter; verse search results open exact verse IDs.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart';
import '../gita_common/gita_common.dart';

class ChaptersPageWidget extends StatefulWidget {
  const ChaptersPageWidget({super.key});

  static String routeName = 'ChaptersPage';
  static String routePath = '/chaptersPage';

  @override
  State<ChaptersPageWidget> createState() => _ChaptersPageWidgetState();
}

class _ChaptersPageWidgetState extends State<ChaptersPageWidget> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    debugPrint('Chapters screen loaded');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      bottomNavIndex: 1,
      child: ListView(
        key: const PageStorageKey('chapters_scroll_position'),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          PageHeader(
            title: 'Read',
            subtitle: 'Bhagavad Gita chapter library',
            trailing: IconButton(
              tooltip: 'Search Gita',
              onPressed: () => context.go('/searchPage'),
              icon: const Icon(Icons.search_rounded, color: kGold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
            child: Column(
              children: [
                FutureBuilder<GitaDataBundle>(
                  future: GitaDataService.load(),
                  builder: (context, snapshot) {
                    final chapterCount = snapshot.data?.chapterCount;
                    final verseCount = snapshot.data?.verseCount;
                    return AnimatedEntrance(
                      child: PremiumCard(
                        accent: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The Song of the Divine',
                              style: gitaTitle(26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Explore action, devotion, meditation, and liberation through a peaceful scripture reader.',
                              style: gitaBody(size: 16),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                AccentPill(chapterCount == null
                                    ? 'Loading Chapters'
                                    : '$chapterCount Chapters'),
                                AccentPill(verseCount == null
                                    ? 'Loading Verses'
                                    : '$verseCount Verses'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  style: gitaBody(color: kDarkText),
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search chapters or verse text',
                    hintStyle: gitaBody(
                      color: kDarkText.withValues(alpha: 0.56),
                      size: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: kCard2),
                    filled: true,
                    fillColor: kCream,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: kLine),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: kGold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<GitaChapterData>>(
                  future: GitaDataService.allChapters(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingStateCard(
                        message: 'Loading chapters...',
                      );
                    }
                    if (snapshot.hasError) {
                      debugPrint('Chapters load failed: ${snapshot.error}');
                      return const ErrorStateCard(
                        message:
                            'Could not load chapters from assets/data/gita/. Please check chapter1.json through chapter18.json and the pubspec asset entry.',
                      );
                    }
                    final chapterList = snapshot.data ?? const [];
                    final filteredChapters = _filterChapters(chapterList);
                    return Column(
                      children: [
                        if (filteredChapters.isEmpty && _query.isNotEmpty)
                          const EmptyStateCard(
                            icon: Icons.search_off_rounded,
                            title: 'No chapters found.',
                            body:
                                'Try a theme like wisdom, action, or devotion.',
                          ),
                        for (var i = 0; i < filteredChapters.length; i++) ...[
                          AnimatedEntrance(
                            delay: Duration(milliseconds: 24 * i),
                            child: _ChapterCard(
                              chapter: filteredChapters[i],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_query.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _VerseSearchResults(query: _query),
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

  List<GitaChapterData> _filterChapters(List<GitaChapterData> chapterList) {
    // This local filter is intentionally simple; full emotional/keyword ranking
    // belongs to SearchScreen and GitaRepository.search.
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return chapterList;
    }
    return chapterList.where((chapter) {
      return chapter.title.toLowerCase().contains(query) ||
          chapter.englishTitle.toLowerCase().contains(query) ||
          chapter.theme.toLowerCase().contains(query) ||
          chapter.summary.toLowerCase().contains(query) ||
          chapter.chapterNumber.toString() == query;
    }).toList(growable: false);
  }
}

class _VerseSearchResults extends StatelessWidget {
  const _VerseSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    // Inline verse matches let users search from the Read tab without leaving
    // the chapter library.
    return FutureBuilder<List<GitaSearchResult>>(
      future: GitaRepository.search(query, limit: 8),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(color: kGold)),
          );
        }
        if (snapshot.hasError) {
          debugPrint('Chapter verse search failed: ${snapshot.error}');
          return const ErrorStateCard(
            message:
                'Could not search verses right now. Please check the Gita JSON files.',
          );
        }
        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return const EmptyStateCard(
            icon: Icons.search_off_rounded,
            title: 'No verse matches found.',
            body: 'Search by reference, teaching, or English phrase.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Verse matches',
                style: gitaBody(color: kText, weight: FontWeight.w900),
              ),
            ),
            for (var i = 0; i < results.length; i++) ...[
              AnimatedEntrance(
                delay: Duration(milliseconds: 24 * i),
                child: PremiumCard(
                  onTap: () => context.push(Uri(
                    path: '/verseReaderPage',
                    queryParameters: {'verseId': results[i].verse.id},
                  ).toString()),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: kGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              results[i].verse.reference,
                              style: gitaBody(
                                color: kGold,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              results[i].verse.englishTranslation,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: gitaBody(size: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: kMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
  });

  final GitaChapterData chapter;

  @override
  Widget build(BuildContext context) {
    final verseId = '${chapter.chapterNumber}.1';
    void read() => context.push(Uri(
          path: '/verseReaderPage',
          queryParameters: {'verseId': verseId},
        ).toString());
    return ChapterListCard(
      onTap: read,
      chapterNumber: chapter.chapterNumber,
      title: chapter.title,
      subtitle: chapter.englishTitle,
      meta: '${chapter.verseCount} verses · ${chapter.theme}',
      actions: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ChapterActionButton(
            icon: Icons.menu_book_rounded,
            label: 'Read',
            onTap: read,
          ),
        ],
      ),
    );
  }
}

class _ChapterActionButton extends StatelessWidget {
  const _ChapterActionButton({
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
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kGold, kSoftGold, kAntiqueGold],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: kAntiqueGold.withValues(alpha: 0.62),
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: kDarkText),
            const SizedBox(width: 7),
            Text(
              label,
              style: gitaBody(
                color: kDarkText,
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
