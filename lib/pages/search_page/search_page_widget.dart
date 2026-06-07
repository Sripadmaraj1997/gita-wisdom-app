// Gita search screen.
//
// Searches local scripture, reflections, Practice Today text, tags, and verse
// references. Topic chips seed emotional searches such as peace, fear, anger,
// and attachment. Ranking lives in GitaRepository.search so SearchScreen only
// handles UX state and exact navigation into Verse Reader.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/gita_data.dart';
import '../../services/local_storage_service.dart';
import '../gita_common/gita_common.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({
    super.key,
    this.initialQuery,
  });

  static String routeName = 'SearchPage';
  static String routePath = '/searchPage';

  final String? initialQuery;

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<GitaSearchResult>>? _searchFuture;
  String _query = '';

  static const _topicChips = [
    'peace',
    'fear',
    'anger',
    'discipline',
    'attachment',
    'devotion',
    'purpose',
    'karma',
    'stress',
    'clarity',
  ];

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    _query = initialQuery;
    _controller.text = initialQuery;
    _searchFuture = initialQuery.isEmpty
        ? GitaRepository.search('2.47', limit: 12)
        : GitaRepository.search(initialQuery, limit: 40);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    // Short debounce keeps typing responsive while avoiding a new JSON search on
    // every single keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      final query = value.trim();
      if (!mounted) {
        return;
      }
      setState(() {
        _query = query;
        _searchFuture = query.isEmpty
            ? GitaRepository.search('2.47', limit: 12)
            : GitaRepository.search(query, limit: 40);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GitaScaffold(
      bottomNavIndex: 2,
      child: ListView(
        key: const PageStorageKey('search_scroll_position'),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: gitaBottomNavScrollPadding(context)),
        children: [
          const PageHeader(
            title: 'Search',
            subtitle:
                'Search Sanskrit, translation, reflection, practice, or topic',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            child: Column(
              children: [
                AnimatedEntrance(
                  // Search field:
                  // Free text supports verse references, Sanskrit,
                  // transliteration, translation words, and practical topics.
                  child: PremiumCard(
                    accent: true,
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    child: Row(
                      children: [
                        const IconMedallion(
                          icon: Icons.search_rounded,
                          size: 40,
                          backgroundColor: kGold,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: false,
                            style: gitaBody(color: kDarkText, size: 16),
                            onChanged: _onQueryChanged,
                            decoration: InputDecoration(
                              hintText: 'Search peace, karma, 2.47, आत्मा...',
                              hintStyle: gitaBody(
                                color: kDarkText.withValues(alpha: 0.56),
                                size: 14,
                              ),
                              filled: true,
                              fillColor: kCream,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
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
                        if (_controller.text.isNotEmpty)
                          AnimatedGoldIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Clear search',
                            backgroundColor: kCard2,
                            onTap: () {
                              _debounce?.cancel();
                              _controller.clear();
                              setState(() {
                                _query = '';
                                _searchFuture =
                                    GitaRepository.search('2.47', limit: 12);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Emotional topic search:
                // Topic chips record private reflection activity and send the
                // same query through the repository ranking logic.
                _TopicSearchChips(
                  topics: _topicChips,
                  selectedTopic: _query,
                  onSelected: (topic) {
                    _debounce?.cancel();
                    _controller.text = topic;
                    unawaited(LocalStorageService.recordReflectedTopic(topic));
                    setState(() {
                      _query = topic;
                      _searchFuture = GitaRepository.search(topic, limit: 40);
                    });
                  },
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: FutureBuilder<List<GitaSearchResult>>(
                    // Ranking logic lives in GitaRepository.search. This
                    // screen only displays loading/error/empty states and maps
                    // a result tap to VerseReaderScreen.
                    key: ValueKey(_query),
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const LoadingStateCard(
                          message: 'Searching the Gita...',
                        );
                      }
                      if (snapshot.hasError) {
                        debugPrint('Gita search failed: ${snapshot.error}');
                        return const ErrorStateCard(
                          message:
                              'Could not search the Gita right now. Please check the chapter JSON files.',
                        );
                      }
                      final results = snapshot.data ?? const [];
                      if (results.isEmpty) {
                        return const EmptyStateCard(
                          icon: Icons.search_off_rounded,
                          title: 'No matching verses found.',
                          body:
                              'Try peace, duty, fear, anger, attachment, or purpose.',
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _query.isEmpty
                                      ? 'Suggested verses'
                                      : '${results.length} results',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: gitaBody(
                                    color: kText,
                                    size: 17,
                                    weight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const AccentPill('Real Gita data'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          for (var i = 0; i < results.length; i++) ...[
                            AnimatedEntrance(
                              delay:
                                  Duration(milliseconds: 18 * i.clamp(0, 10)),
                              child: _SearchResultCard(
                                result: results[i],
                                query: _query,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    },
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

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.query,
  });

  final GitaSearchResult result;
  final String query;

  @override
  Widget build(BuildContext context) {
    final verse = result.verse;
    final chapter = result.chapter;
    // Result cards prefer reflection/practice previews when available because
    // they answer emotional searches better than raw verse text alone.
    return PremiumCard(
      onTap: () => context.push(Uri(
        path: '/verseReaderPage',
        queryParameters: {'verseId': verse.id},
      ).toString()),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentPill(verse.reference),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter?.englishTitle ?? 'Bhagavad Gita',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: gitaBody(size: 12, color: kGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (verse.sanskrit.trim().isNotEmpty) ...[
            _HighlightedSnippet(
              text: verse.sanskrit,
              query: query,
              maxLines: 3,
              style: gitaSanskrit(21),
            ),
            const SizedBox(height: 14),
          ],
          if (verse.transliteration.trim().isNotEmpty) ...[
            _HighlightedSnippet(
              text: verse.transliteration,
              query: query,
              maxLines: 2,
              style: gitaTransliteration(size: 14, color: kMuted),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kGold.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (verse.reflectionText.trim().isNotEmpty) ...[
                  _PreviewBlock(
                    label: 'Reflection',
                    text: verse.reflectionText,
                    query: query,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                ],
                if (verse.englishTranslation.trim().isNotEmpty) ...[
                  _HighlightedSnippet(
                    text: verse.englishTranslation,
                    query: query,
                    style: gitaBody(
                      color: kDarkText,
                      size: 16,
                      weight: FontWeight.w800,
                    ),
                    maxLines: 3,
                  ),
                ],
                if (_secondaryPreviewText(verse).trim().isNotEmpty) ...[
                  if (verse.englishTranslation.trim().isNotEmpty)
                    const SizedBox(height: 10),
                  _PreviewBlock(
                    label: _secondaryPreviewLabel(verse),
                    text: _secondaryPreviewText(verse),
                    query: query,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          if (verse.allTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in verse.allTags.take(5)) AccentPill('#$tag'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({
    required this.label,
    required this.text,
    required this.query,
    required this.maxLines,
  });

  final String label;
  final String text;
  final String query;
  final int maxLines;

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
        _HighlightedSnippet(
          text: text,
          query: query,
          maxLines: maxLines,
          style: gitaBody(
            color: kDarkText,
            size: 14,
          ).copyWith(height: 1.46),
        ),
      ],
    );
  }
}

class _TopicSearchChips extends StatelessWidget {
  const _TopicSearchChips({
    required this.topics,
    required this.selectedTopic,
    required this.onSelected,
  });

  final List<String> topics;
  final String selectedTopic;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search by feeling or topic',
            style: gitaBody(color: kText, weight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Begin with what you are carrying today.',
            style: gitaBody(color: kMuted, size: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in topics)
                _TopicChip(
                  label: topic,
                  selected: selectedTopic.toLowerCase() == topic.toLowerCase(),
                  onTap: () => onSelected(topic),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
              : kCard2.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? kGold.withValues(alpha: 0.45)
                : kLine.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          style: gitaBody(
            color: selected ? kSoftGold : kText,
            size: 12,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HighlightedSnippet extends StatelessWidget {
  const _HighlightedSnippet({
    required this.text,
    required this.query,
    required this.style,
    required this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    // Lightweight in-card highlighting. This is purely presentational and does
    // not change search ranking.
    final normalizedQuery = query.trim().toLowerCase();
    final terms = query
        .toLowerCase()
        .split(RegExp(r'[\s,;:!?()\[\]"“”‘’]+'))
        .where((term) => term.length > 2)
        .toSet()
      ..addAll(normalizedQuery.length > 1 ? [normalizedQuery] : const []);
    if (terms.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final spans = <TextSpan>[];
    final pattern = RegExp(
      terms.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style.copyWith(
          color: kDarkText,
          fontWeight: FontWeight.w900,
          backgroundColor: kGold.withValues(alpha: 0.28),
        ),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: style, children: spans),
    );
  }
}

String _secondaryPreviewLabel(GitaVerseData verse) {
  final practiceToday = verse.practiceToday.trim();
  if (practiceToday.isNotEmpty) {
    return 'Practice Today';
  }
  final meaning = verse.cleanMeaning.trim();
  if (meaning.isNotEmpty) {
    return 'Meaning';
  }
  return 'Translation';
}

String _secondaryPreviewText(GitaVerseData verse) {
  final practiceToday = verse.practiceToday.trim();
  if (practiceToday.isNotEmpty) {
    return practiceToday;
  }
  final meaning = verse.cleanMeaning.trim();
  if (meaning.isNotEmpty) {
    return meaning;
  }
  return verse.englishTranslation;
}
