// Local Bhagavad Gita data layer.
//
// This service is the source of truth for scripture content. It loads the
// chapter JSON files from assets/data/gita/, merges optional reflections from
// assets/data/reflections.json, validates the expected 18 chapters / 700 verses,
// and exposes search/retrieval helpers used by Home, Read, Search, Ask Gita
// Lite, and Verse Reader.
//
// TODO(ai-guidance): Future semantic retrieval can layer embeddings over this
// repository while keeping the local JSON loader as the offline fallback.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GitaChapterData {
  const GitaChapterData({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.englishTitle,
    required this.verseCount,
    required this.theme,
    required this.summary,
  });

  factory GitaChapterData.fromJson(Map<String, dynamic> json) {
    return GitaChapterData(
      id: json['id'] as String,
      chapterNumber: _readInt(json['chapterNumber']),
      title: json['title'] as String,
      englishTitle: json['englishTitle'] as String,
      verseCount: _readInt(json['verseCount']),
      theme: json['theme'] as String,
      summary: json['summary'] as String,
    );
  }

  final String id;
  final int chapterNumber;
  final String title;
  final String englishTitle;
  final int verseCount;
  final String theme;
  final String summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterNumber': chapterNumber,
        'title': title,
        'englishTitle': englishTitle,
        'verseCount': verseCount,
        'theme': theme,
        'summary': summary,
      };
}

typedef GitaChapter = GitaChapterData;

class GitaVerse {
  const GitaVerse({
    required this.id,
    required this.chapterNumber,
    required this.verseNumber,
    required this.sanskrit,
    required this.transliteration,
    required this.englishTranslation,
    required this.meaning,
    required this.tags,
    required this.audioUrl,
    required this.audioAssetPath,
    this.reflectionText = '',
    this.practiceToday = '',
    this.reflectionTags = const [],
  });

  factory GitaVerse.fromJson(Map<String, dynamic> json) {
    final chapterNumber =
        _readInt(json['chapterNumber'] ?? json['chapter_number']);
    final verseNumber = _readInt(json['verseNumber'] ?? json['verse_number']);
    final sanskritField = _firstStringEntry(
      json,
      const ['sanskrit', 'sloka', 'text'],
    );
    final transliterationField = _firstStringEntry(
      json,
      const ['transliteration', 'transliterationText'],
    );
    final englishTranslationField = _firstStringEntry(
      json,
      const ['englishTranslation', 'translation', 'english'],
    );
    final meaningField = _firstStringEntry(
      json,
      const [
        'meaning',
        'commentary',
        'description',
        'purport',
        'englishTranslation',
        'translation',
      ],
    );
    final sanskrit = sanskritField?.value ?? 'Sanskrit unavailable.';
    final transliteration =
        transliterationField?.value ?? 'Transliteration unavailable.';
    final englishTranslation =
        englishTranslationField?.value ?? 'English translation unavailable.';
    final meaning = meaningField?.value ?? '';
    return GitaVerse(
      id: (json['id'] as String?) ?? '$chapterNumber.$verseNumber',
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      sanskrit: sanskrit,
      transliteration: transliteration,
      englishTranslation: englishTranslation,
      meaning: meaning,
      tags: _readStringList(json['tags']),
      audioUrl: (json['audioUrl'] as String?) ?? '',
      audioAssetPath: (json['audioAssetPath'] as String?) ??
          (json['audio_asset_path'] as String?) ??
          defaultAudioAssetPath(chapterNumber, verseNumber),
      reflectionText: (json['reflection'] as String?)?.trim() ?? '',
      practiceToday: (json['practiceToday'] as String?)?.trim() ?? '',
      reflectionTags: _readStringList(json['reflectionTags']),
    );
  }

  static String defaultAudioAssetPath(int chapterNumber, int verseNumber) {
    return '';
  }

  final String id;
  final int chapterNumber;
  final int verseNumber;
  final String sanskrit;
  final String transliteration;
  final String englishTranslation;
  final String meaning;
  final List<String> tags;
  final String audioUrl;
  final String audioAssetPath;
  final String reflectionText;
  final String practiceToday;
  final List<String> reflectionTags;

  String get reference => 'Bhagavad Gita $chapterNumber.$verseNumber';
  String get shortReference => 'Gita $chapterNumber.$verseNumber';
  String get translation => englishTranslation;
  String get english => englishTranslation;
  String get commentary => meaning;
  String get reflection => reflectionText;
  List<String> get allTags => {...tags, ...reflectionTags}.toList();

  GitaVerse withReflection(GitaReflection reflection) {
    return GitaVerse(
      id: id,
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      sanskrit: sanskrit,
      transliteration: transliteration,
      englishTranslation: englishTranslation,
      meaning: meaning,
      tags: tags,
      audioUrl: audioUrl,
      audioAssetPath: audioAssetPath,
      reflectionText: reflection.reflection,
      practiceToday: reflection.practiceToday,
      reflectionTags: reflection.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterNumber': chapterNumber,
        'verseNumber': verseNumber,
        'sanskrit': sanskrit,
        'transliteration': transliteration,
        'englishTranslation': englishTranslation,
        'translation': englishTranslation,
        'commentary': meaning,
        'meaning': meaning,
        'tags': tags,
        'audioUrl': audioUrl,
        'audioAssetPath': audioAssetPath,
        'reflection': reflectionText,
        'practiceToday': practiceToday,
        'reflectionTags': reflectionTags,
      };
}

class GitaReflection {
  const GitaReflection({
    required this.chapterNumber,
    required this.verseNumber,
    required this.reflection,
    required this.practiceToday,
    required this.tags,
  });

  factory GitaReflection.fromJson(Map<String, dynamic> json) {
    return GitaReflection(
      chapterNumber: _readInt(json['chapterNumber']),
      verseNumber: _readInt(json['verseNumber']),
      reflection: (json['reflection'] as String?)?.trim() ?? '',
      practiceToday: (json['practiceToday'] as String?)?.trim() ?? '',
      tags: _readStringList(json['tags']),
    );
  }

  final int chapterNumber;
  final int verseNumber;
  final String reflection;
  final String practiceToday;
  final List<String> tags;

  String get verseId => '$chapterNumber.$verseNumber';
}

MapEntry<String, String>? _firstStringEntry(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return MapEntry(key, value.trim());
    }
  }
  return null;
}

typedef GitaVerseData = GitaVerse;

class GitaSearchResult {
  const GitaSearchResult({
    required this.verse,
    required this.score,
    this.chapter,
  });

  final GitaVerseData verse;
  final GitaChapterData? chapter;
  final int score;
}

class GitaDataBundle {
  GitaDataBundle({
    required this.chapters,
    required this.verses,
  })  : versesByChapter = _groupVersesByChapter(verses),
        chaptersByNumber = {
          for (final chapter in chapters) chapter.chapterNumber: chapter
        },
        versesById = {for (final verse in verses) verse.id: verse};

  // Precomputed lookup maps keep screens fast and avoid repeated list scans
  // when opening exact verses from search, saved items, or reading progress.
  final List<GitaChapterData> chapters;
  final List<GitaVerse> verses;
  final Map<int, List<GitaVerse>> versesByChapter;
  final Map<int, GitaChapterData> chaptersByNumber;
  final Map<String, GitaVerse> versesById;

  int get chapterCount => chapters.length;
  int get verseCount => verses.length;

  GitaVerse? verseById(String id) => versesById[id];
  GitaChapterData? chapterByNumber(int chapterNumber) =>
      chaptersByNumber[chapterNumber];
  List<GitaVerse> chapterVerses(int chapterNumber) =>
      versesByChapter[chapterNumber] ?? const [];
}

class GitaDataService {
  const GitaDataService._();

  static const assetPath = 'assets/data/gita';
  static const chapterAssetDirectory = 'assets/data/gita';
  static const reflectionsAssetPath = 'assets/data/reflections.json';
  static const expectedChapterCount = 18;
  static const expectedVerseCount = 700;

  static Future<GitaDataBundle>? _bundleFuture;

  static Future<GitaDataBundle> load() {
    // Cache the parsed bundle for the life of the app. The source data is local
    // and immutable during runtime, so this avoids repeated JSON parsing.
    return _bundleFuture ??= _loadFromAsset().catchError((Object error) {
      _bundleFuture = null;
      throw error;
    });
  }

  static Future<List<GitaVerse>> allVerses() async {
    return (await load()).verses;
  }

  static Future<Map<int, List<GitaVerse>>> versesGroupedByChapter() async {
    return (await load()).versesByChapter;
  }

  static Future<List<GitaVerse>> versesForChapter(
    int chapterNumber,
  ) async {
    return (await load()).chapterVerses(chapterNumber);
  }

  static Future<List<GitaVerse>> loadChapter(int chapterNumber) async {
    try {
      final path = chapterAssetPath(chapterNumber);
      if (kDebugMode) {
        debugPrint('GitaDataService: loading chapter JSON from $path');
      }
      final jsonString = await rootBundle.loadString(path);
      final data = jsonDecode(jsonString);
      // Chapter files in this project have changed shape over time. The parser
      // supports common nesting formats so replacing the dataset does not
      // require screen changes.
      final verseMaps = _extractVerseMaps(data, chapterNumber);
      final verses = verseMaps.map(GitaVerse.fromJson).toList()
        ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
      if (kDebugMode) {
        if (chapterNumber == 1) {
          debugPrint(
            'GitaDataService: chapter1 raw JSON type: ${data.runtimeType}',
          );
          debugPrint(
            'GitaDataService: chapter1 verse list length: ${verseMaps.length}',
          );
        }
        debugPrint(
          'GitaDataService: chapter $chapterNumber verses loaded: '
          '${verses.length}',
        );
        if (verses.length == 1) {
          debugPrint(
            'GitaDataService WARNING: chapter $chapterNumber loaded only '
            '1 verse. Check the JSON nesting and parser extraction path.',
          );
        }
        final expectedCount = _expectedVerseCounts[chapterNumber];
        if (expectedCount != null && expectedCount != verses.length) {
          debugPrint(
            'GitaDataService WARNING: chapter $chapterNumber expected '
            '$expectedCount verses, but loaded ${verses.length}.',
          );
        }
      }
      return verses;
    } catch (error, stackTrace) {
      debugPrint('GitaDataService: chapter JSON load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static String chapterAssetPath(int chapterNumber) {
    return '$chapterAssetDirectory/chapter$chapterNumber.json';
  }

  static Future<List<dynamic>> loadRawChapter(int chapterNumber) async {
    final path = chapterAssetPath(chapterNumber);
    final jsonString = await rootBundle.loadString(path);
    final data = jsonDecode(jsonString);
    return _extractVerseMaps(data, chapterNumber);
  }

  static Future<GitaVerse?> verseById(String id) async {
    return (await load()).verseById(id);
  }

  static Future<List<GitaChapterData>> allChapters() async {
    return (await load()).chapters;
  }

  static Future<GitaChapterData?> chapterByNumber(int chapterNumber) async {
    return (await load()).chapterByNumber(chapterNumber);
  }

  static Future<GitaDataBundle> _loadFromAsset() async {
    try {
      if (kDebugMode) {
        debugPrint(
          'GitaDataService: loading chapter JSON files from $assetPath',
        );
      }
      final chapters = <GitaChapterData>[];
      final verses = <GitaVerse>[];
      final missingChapters = <int>[];
      final reflections = await _loadReflections();

      // Load chapters sequentially so debug logs and validation errors point to
      // the exact chapter file that failed.
      for (var chapterNumber = 1;
          chapterNumber <= expectedChapterCount;
          chapterNumber++) {
        try {
          final chapterVerses = await loadChapter(chapterNumber);
          verses.addAll(chapterVerses.map((verse) {
            final reflection = reflections[verse.id];
            return reflection == null
                ? verse
                : verse.withReflection(reflection);
          }));
          chapters.add(_chapterDefinition(chapterNumber, chapterVerses.length));
        } catch (error, stackTrace) {
          missingChapters.add(chapterNumber);
          debugPrint(
            'GitaDataService: missing or invalid chapter file '
            '${chapterAssetPath(chapterNumber)}: $error',
          );
          if (kDebugMode) {
            debugPrintStack(stackTrace: stackTrace);
          }
        }
      }

      verses.sort((a, b) {
        final chapterCompare = a.chapterNumber.compareTo(b.chapterNumber);
        if (chapterCompare != 0) {
          return chapterCompare;
        }
        return a.verseNumber.compareTo(b.verseNumber);
      });

      final bundle = GitaDataBundle(chapters: chapters, verses: verses);
      _validateBundle(bundle, missingChapters: missingChapters);
      if (kDebugMode) {
        debugPrint(
          'GitaDataService: total chapters loaded: ${bundle.chapterCount}',
        );
        debugPrint(
          'GitaDataService: total verses loaded: ${bundle.verseCount}',
        );
        if (bundle.verses.isNotEmpty) {
          final previewVerse = _firstVerseOrNull(bundle.verses);
          debugPrint(
            'GitaDataService: first verse loaded: '
            '${previewVerse?.reference ?? 'None'} | '
            '${previewVerse?.sanskrit.replaceAll('\n', ' ') ?? ''} | '
            '${previewVerse?.englishTranslation ?? ''}',
          );
        }
      }
      return bundle;
    } catch (error, stackTrace) {
      debugPrint('GitaDataService: JSON parsing/loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, GitaReflection>> _loadReflections() async {
    try {
      // Reflections are optional enhancement data. If the file is missing or
      // malformed, scripture reading still works with fallback Practice Today
      // text in the UI.
      final jsonString = await rootBundle.loadString(reflectionsAssetPath);
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        debugPrint(
          'GitaDataService: reflections.json root is not a list; ignoring.',
        );
        return const {};
      }
      final reflections = decoded
          .whereType<Map>()
          .map((item) =>
              GitaReflection.fromJson(Map<String, dynamic>.from(item)))
          .where((item) =>
              item.chapterNumber > 0 &&
              item.verseNumber > 0 &&
              (item.reflection.isNotEmpty || item.practiceToday.isNotEmpty))
          .toList(growable: false);
      if (kDebugMode) {
        debugPrint(
          'GitaDataService: reflections loaded: ${reflections.length}',
        );
      }
      return {
        for (final reflection in reflections) reflection.verseId: reflection
      };
    } catch (error, stackTrace) {
      debugPrint('GitaDataService: reflections load failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return const {};
    }
  }

  static void _validateBundle(
    GitaDataBundle bundle, {
    List<int> missingChapters = const [],
  }) {
    // Fail fast in development/release builds if the packaged scripture dataset
    // is incomplete. This is better than silently shipping missing chapters.
    if (bundle.chapters.isEmpty || bundle.verses.isEmpty) {
      throw StateError(
        'No Bhagavad Gita chapter files could be loaded from $assetPath.',
      );
    }
    if (missingChapters.isNotEmpty) {
      throw StateError(
        'Could not load required Bhagavad Gita chapter files: '
        '${missingChapters.join(', ')}. Please check assets/data/gita/.',
      );
    }
    if (bundle.chapterCount != expectedChapterCount) {
      throw StateError(
        'Expected $expectedChapterCount Gita chapters in $assetPath, '
        'found ${bundle.chapterCount}.',
      );
    }
    if (bundle.verseCount != expectedVerseCount) {
      throw StateError(
        'Expected $expectedVerseCount Gita verses in $assetPath, '
        'found ${bundle.verseCount}.',
      );
    }
    for (final chapter in bundle.chapters) {
      final actualCount = bundle.chapterVerses(chapter.chapterNumber).length;
      if (actualCount != chapter.verseCount) {
        throw StateError(
          'Chapter ${chapter.chapterNumber} expected ${chapter.verseCount} '
          'verses, found $actualCount.',
        );
      }
    }
  }
}

GitaChapterData _chapterDefinition(int chapterNumber, int loadedVerseCount) {
  final metadata = _chapterMetadata[chapterNumber];
  if (metadata == null) {
    return GitaChapterData(
      id: 'chapter_$chapterNumber',
      chapterNumber: chapterNumber,
      title: 'Chapter $chapterNumber',
      englishTitle: 'Bhagavad Gita Chapter $chapterNumber',
      verseCount: loadedVerseCount,
      theme: 'Wisdom',
      summary: 'Bhagavad Gita chapter $chapterNumber.',
    );
  }
  return GitaChapterData(
    id: 'chapter_$chapterNumber',
    chapterNumber: chapterNumber,
    title: metadata.title,
    englishTitle: metadata.englishTitle,
    verseCount: metadata.verseCount,
    theme: metadata.theme,
    summary: metadata.summary,
  );
}

const _chapterMetadata = <int, _ChapterMetadata>{
  1: _ChapterMetadata(
    'Arjuna Vishada Yoga',
    'Arjuna\'s Despair',
    47,
    'Dharma',
    'Arjuna faces moral grief on the battlefield.',
  ),
  2: _ChapterMetadata(
    'Sankhya Yoga',
    'Knowledge of the Self',
    72,
    'Wisdom',
    'Krishna teaches the eternal Self and steady wisdom.',
  ),
  3: _ChapterMetadata(
    'Karma Yoga',
    'The Yoga of Action',
    43,
    'Action',
    'Selfless action becomes a path to freedom.',
  ),
  4: _ChapterMetadata(
    'Jnana Karma Sannyasa Yoga',
    'Wisdom in Action',
    42,
    'Sacrifice',
    'Knowledge transforms action into sacred offering.',
  ),
  5: _ChapterMetadata(
    'Karma Sannyasa Yoga',
    'Renunciation of Action',
    29,
    'Peace',
    'True renunciation is inward freedom.',
  ),
  6: _ChapterMetadata(
    'Dhyana Yoga',
    'The Yoga of Meditation',
    47,
    'Mind',
    'Meditation disciplines the mind and reveals the Self.',
  ),
  7: _ChapterMetadata(
    'Jnana Vijnana Yoga',
    'Knowledge and Realization',
    30,
    'Truth',
    'Krishna reveals divine knowledge and realization.',
  ),
  8: _ChapterMetadata(
    'Akshara Brahma Yoga',
    'The Imperishable Absolute',
    28,
    'Memory',
    'Remembrance of the Divine guides the final journey.',
  ),
  9: _ChapterMetadata(
    'Raja Vidya Yoga',
    'Royal Knowledge',
    34,
    'Devotion',
    'Krishna reveals the most secret wisdom of devotion.',
  ),
  10: _ChapterMetadata(
    'Vibhuti Yoga',
    'Divine Glories',
    42,
    'Wonder',
    'The Divine is seen through the excellences of creation.',
  ),
  11: _ChapterMetadata(
    'Vishvarupa Darshana Yoga',
    'Vision of the Universal Form',
    55,
    'Vision',
    'Arjuna beholds Krishna\'s universal form.',
  ),
  12: _ChapterMetadata(
    'Bhakti Yoga',
    'The Yoga of Devotion',
    20,
    'Love',
    'Devotion and steadiness reveal the beloved devotee.',
  ),
  13: _ChapterMetadata(
    'Kshetra Kshetrajna Vibhaga Yoga',
    'Field and Knower',
    34,
    'Awareness',
    'The body is the field and consciousness is the knower.',
  ),
  14: _ChapterMetadata(
    'Gunatraya Vibhaga Yoga',
    'The Three Gunas',
    27,
    'Nature',
    'The three gunas bind and shape embodied life.',
  ),
  15: _ChapterMetadata(
    'Purushottama Yoga',
    'The Supreme Person',
    20,
    'Reality',
    'Krishna reveals the eternal person beyond the world tree.',
  ),
  16: _ChapterMetadata(
    'Daivasura Sampad Vibhaga Yoga',
    'Divine and Demonic Qualities',
    24,
    'Character',
    'Divine qualities lead upward while destructive traits bind.',
  ),
  17: _ChapterMetadata(
    'Shraddhatraya Vibhaga Yoga',
    'Threefold Faith',
    28,
    'Faith',
    'Faith, food, sacrifice, austerity, and charity follow the gunas.',
  ),
  18: _ChapterMetadata(
    'Moksha Sannyasa Yoga',
    'Liberation and Renunciation',
    78,
    'Freedom',
    'Krishna gathers the teachings into surrender and liberation.',
  ),
};

const _expectedVerseCounts = <int, int>{
  1: 47,
  2: 72,
  3: 43,
  4: 42,
  5: 29,
  6: 47,
  7: 30,
  8: 28,
  9: 34,
  10: 42,
  11: 55,
  12: 20,
  13: 34,
  14: 27,
  15: 20,
  16: 24,
  17: 28,
  18: 78,
};

class _ChapterMetadata {
  const _ChapterMetadata(
    this.title,
    this.englishTitle,
    this.verseCount,
    this.theme,
    this.summary,
  );

  final String title;
  final String englishTitle;
  final int verseCount;
  final String theme;
  final String summary;
}

Future<List<dynamic>> loadChapter(int chapterNumber) async {
  return GitaDataService.loadRawChapter(chapterNumber);
}

class GitaRepository {
  const GitaRepository._();

  static const assetPath = GitaDataService.assetPath;
  static const dailyVerseId = '2.47';

  static Future<GitaDataBundle> load() {
    return GitaDataService.load();
  }

  static Future<List<GitaChapterData>> allChapters() async {
    return GitaDataService.allChapters();
  }

  static Future<List<GitaVerse>> allVerses() async {
    return GitaDataService.allVerses();
  }

  static Future<GitaVerse> dailyVerse() async {
    final bundle = await load();
    final fallbackVerse = _firstVerseOrNull(bundle.verses);
    if (fallbackVerse == null) {
      throw StateError('No Bhagavad Gita verses are loaded.');
    }
    return bundle.verseById(dailyVerseId) ?? fallbackVerse;
  }

  static Future<GitaVerse?> verseById(String id) async {
    return GitaDataService.verseById(id);
  }

  static Future<GitaVerse> verseByIdOrDaily(String? id) async {
    final bundle = await load();
    if (id != null) {
      final verse = bundle.verseById(id);
      if (verse != null) {
        return verse;
      }
    }
    final fallbackVerse = _firstVerseOrNull(bundle.verses);
    if (fallbackVerse == null) {
      throw StateError('No Bhagavad Gita verses are loaded.');
    }
    return bundle.verseById(dailyVerseId) ?? fallbackVerse;
  }

  static Future<List<GitaVerse>> versesForChapter(
    int chapterNumber,
  ) async {
    return GitaDataService.versesForChapter(chapterNumber);
  }

  static Future<GitaChapterData?> chapterByNumber(int chapterNumber) async {
    return GitaDataService.chapterByNumber(chapterNumber);
  }

  static Future<List<GitaSearchResult>> search(
    String query, {
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    // Emotional searches such as "worry" or "attachment" are expanded into
    // related Gita terms so the offline search feels spiritually useful without
    // an AI service. Ranking then favors exact references first, followed by
    // editorial tags/reflections, then scripture text. This mirrors how users
    // usually search: "2.47" should be exact, while "fear" should find guidance.
    final expandedQuery = _expandSpiritualSearchQuery(normalizedQuery);
    final terms = expandedQuery
        .split(RegExp(r'[\s,;:!?()\[\]"“”‘’]+'))
        .where((term) => term.trim().length > 1)
        .map((term) => term.trim())
        .toSet();
    if (terms.isEmpty) {
      return const [];
    }

    final bundle = await load();
    final results = <GitaSearchResult>[];
    for (final verse in bundle.verses) {
      final chapter = bundle.chapterByNumber(verse.chapterNumber);
      final referenceText = '${verse.id} ${verse.reference}'.toLowerCase();
      final numberText =
          '${verse.chapterNumber} ${verse.verseNumber} ${verse.chapterNumber}.${verse.verseNumber}';
      final sanskritText = verse.sanskrit.toLowerCase();
      final transliterationText = verse.transliteration.toLowerCase();
      final translationText = verse.englishTranslation.toLowerCase();
      final meaningText = verse.meaning.toLowerCase();
      final reflectionText = verse.reflectionText.toLowerCase();
      final practiceText = verse.practiceToday.toLowerCase();
      final tagText = verse.allTags.join(' ').toLowerCase();
      final chapterText = [
        chapter?.title,
        chapter?.englishTitle,
        chapter?.theme,
        chapter?.summary,
      ].whereType<String>().join(' ').toLowerCase();
      final text = [
        referenceText,
        numberText,
        sanskritText,
        transliterationText,
        translationText,
        meaningText,
        reflectionText,
        practiceText,
        tagText,
        chapterText,
      ].join(' ');

      // Ranking priority:
      // 1. exact chapter/verse references
      // 2. tags and topic terms
      // 3. reflection / practice text
      // 4. translation and meaning
      // 5. transliteration / Sanskrit matches
      var score = 0;
      final exactReferenceMatch = normalizedQuery == verse.id ||
          normalizedQuery == '${verse.chapterNumber}.${verse.verseNumber}' ||
          normalizedQuery == '${verse.chapterNumber}:${verse.verseNumber}' ||
          normalizedQuery ==
              '${verse.chapterNumber} ${verse.verseNumber}'.trim() ||
          referenceText.contains(' $normalizedQuery ');
      if (exactReferenceMatch) {
        score += 100;
      } else if (referenceText.contains(normalizedQuery) ||
          numberText.contains(normalizedQuery)) {
        score += 70;
      }
      if (tagText.contains(normalizedQuery)) {
        score += 55;
      }
      if (reflectionText.contains(normalizedQuery) ||
          practiceText.contains(normalizedQuery)) {
        score += 42;
      }
      if (translationText.contains(normalizedQuery)) {
        score += 30;
      }
      if (meaningText.contains(normalizedQuery)) {
        score += 24;
      }
      if (transliterationText.contains(normalizedQuery)) {
        score += 18;
      }
      if (sanskritText.contains(normalizedQuery)) {
        score += 16;
      }
      for (final term in terms) {
        if (tagText.contains(term)) {
          score += 12;
        }
        if (reflectionText.contains(term)) {
          score += 9;
        }
        if (practiceText.contains(term)) {
          score += 8;
        }
        if (translationText.contains(term)) {
          score += 7;
        }
        if (meaningText.contains(term)) {
          score += 5;
        }
        if (transliterationText.contains(term)) {
          score += 4;
        }
        if (sanskritText.contains(term)) {
          score += 4;
        }
        if (referenceText.contains(term) || numberText.contains(term)) {
          score += 3;
        }
        if (chapterText.contains(term)) {
          score += 2;
        }
      }
      if (terms.every(translationText.contains)) {
        score += 8;
      } else if (terms.every(text.contains)) {
        score += 3;
      }
      if (score > 0) {
        results.add(GitaSearchResult(
          verse: verse,
          chapter: chapter,
          score: score,
        ));
      }
    }

    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final chapterCompare =
          a.verse.chapterNumber.compareTo(b.verse.chapterNumber);
      if (chapterCompare != 0) {
        return chapterCompare;
      }
      return a.verse.verseNumber.compareTo(b.verse.verseNumber);
    });
    return results.take(limit).toList(growable: false);
  }
}

String _expandSpiritualSearchQuery(String query) {
  const topicMap = {
    'anxiety': ['fear', 'peace', 'mind', 'steady', 'calm'],
    'worry': ['fear', 'peace', 'mind', 'steady', 'calm'],
    'stress': ['peace', 'mind', 'action', 'steady'],
    'anger': ['anger', 'desire', 'mind', 'control'],
    'discipline': ['practice', 'mind', 'yoga', 'action'],
    'attachment': ['attachment', 'fruit', 'result', 'karma', 'action'],
    'purpose': ['dharma', 'duty', 'action', 'purpose'],
    'peace': ['peace', 'mind', 'steady', 'devotion'],
    'karma': ['karma', 'action', 'duty', 'work'],
    'devotion': ['devotion', 'surrender', 'love', 'worship'],
    'fear': ['fear', 'peace', 'self', 'mind'],
    'clarity': ['clarity', 'wisdom', 'knowledge', 'mind', 'steady'],
  };
  final additions = <String>[];
  for (final entry in topicMap.entries) {
    if (query.contains(entry.key)) {
      additions.addAll(entry.value);
    }
  }
  return [query, ...additions].join(' ');
}

Map<int, List<GitaVerse>> _groupVersesByChapter(List<GitaVerse> verses) {
  final grouped = <int, List<GitaVerse>>{};
  for (final verse in verses) {
    grouped.putIfAbsent(verse.chapterNumber, () => []).add(verse);
  }
  return {
    for (final entry in grouped.entries)
      entry.key: List<GitaVerse>.unmodifiable(entry.value),
  };
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.parse(value.toString());
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

List<Map<String, dynamic>> _extractVerseMaps(
  dynamic decodedJson,
  int chapterNumber,
) {
  final rawVerses = _extractRawVerseList(decodedJson);
  return rawVerses.whereType<Map>().map((rawVerse) {
    final verseMap = Map<String, dynamic>.from(rawVerse);
    verseMap['chapterNumber'] ??= chapterNumber;
    verseMap['verseNumber'] ??= verseMap['verse_number'] ??
        verseMap['number'] ??
        verseMap['verse'] ??
        verseMap['verse_index'];
    final verseNumber = _readInt(verseMap['verseNumber']);
    verseMap['id'] ??= '$chapterNumber.$verseNumber';
    return verseMap;
  }).toList(growable: false);
}

List<dynamic> _extractRawVerseList(dynamic decodedJson) {
  if (decodedJson is List) {
    return decodedJson;
  }
  if (decodedJson is Map) {
    final root = Map<String, dynamic>.from(decodedJson);
    final rootVerses = root['verses'];
    if (rootVerses is List) {
      return rootVerses;
    }
    final chapter = root['chapter'];
    if (chapter is Map) {
      final chapterVerses = chapter['verses'];
      if (chapterVerses is List) {
        return chapterVerses;
      }
    }
    final data = root['data'];
    if (data is Map) {
      final dataVerses = data['verses'];
      if (dataVerses is List) {
        return dataVerses;
      }
    }
  }
  throw const FormatException(
    'Unsupported Gita chapter JSON. Expected a verse list, {"verses":[]}, '
    '{"chapter":{"verses":[]}}, or {"data":{"verses":[]}}.',
  );
}

GitaVerse? _firstVerseOrNull(Iterable<GitaVerse> verses) {
  for (final verse in verses) {
    return verse;
  }
  return null;
}
