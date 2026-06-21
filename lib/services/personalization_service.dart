/// ------------------------------------------------------------
/// PersonalizationService
///
/// Purpose:
/// Offline personalization and recommendation engine.
///
/// Responsibilities:
/// - Record compact local signals: opened verses, saved/highlighted verses,
///   Ask Gita topics, emotional searches, journal activity, and completed
///   Journeys.
/// - Convert signals into spiritual theme counts such as peace, fear,
///   anger, discipline, purpose, devotion, clarity, attachment, and compassion.
/// - Personalize Today's Guidance and quiet Home recommendations.
///
/// Architecture:
/// No accounts, cloud sync, analytics feed, or AI model is used. All signals are
/// stored in SharedPreferences and can be cleared locally.
///
/// Notes:
/// Personalization should feel like continuity, not surveillance. The UI never
/// shows profile scores or tracking language.
///
/// TODO(personalization-engine): Keep this local model as the privacy-preserving
/// baseline if recommendations become richer.
/// ------------------------------------------------------------
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gita_data.dart';
import 'daily_companion_service.dart';

class PersonalizationProfile {
  const PersonalizationProfile({
    required this.seeking,
    required this.language,
    required this.reminderHour,
    required this.reminderMinute,
  });

  static const defaultProfile = PersonalizationProfile(
    seeking: 'Peace',
    language: 'English',
    reminderHour: 7,
    reminderMinute: 0,
  );

  final String seeking;
  final String language;
  final int reminderHour;
  final int reminderMinute;

  String get reminderLabel {
    final hour12 = reminderHour % 12 == 0 ? 12 : reminderHour % 12;
    final minute = reminderMinute.toString().padLeft(2, '0');
    final period = reminderHour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}

class UserInterestProfile {
  const UserInterestProfile({
    required this.themeCounts,
    required this.recentThemes,
  });

  final Map<String, int> themeCounts;
  final List<String> recentThemes;

  bool get hasSignals => themeCounts.values.any((count) => count > 0);

  List<String> get topThemes {
    final recencyBoost = <String, int>{};
    for (var i = 0; i < recentThemes.length; i++) {
      recencyBoost[recentThemes[i]] =
          (recencyBoost[recentThemes[i]] ?? 0) + (recentThemes.length - i);
    }
    final entries =
        themeCounts.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) {
            final bScore = b.value + (recencyBoost[b.key] ?? 0);
            final aScore = a.value + (recencyBoost[a.key] ?? 0);
            return bScore.compareTo(aScore);
          });
    return entries.map((entry) => entry.key).take(5).toList(growable: false);
  }
}

class PersonalizedRecommendation {
  const PersonalizedRecommendation({
    required this.title,
    required this.subtitle,
    required this.reason,
    this.verseId,
    this.journeyId,
  });

  final String title;
  final String subtitle;
  final String reason;
  final String? verseId;
  final String? journeyId;

  bool get opensVerse => verseId != null;
  bool get opensJourney => journeyId != null;
}

class PersonalizationService {
  const PersonalizationService._();

  static const seekingOptions = [
    'Peace',
    'Purpose',
    'Discipline',
    'Devotion',
    'Clarity',
  ];

  static const languageOptions = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Spanish',
  ];

  static const themes = [
    'peace',
    'fear',
    'anger',
    'discipline',
    'purpose',
    'devotion',
    'clarity',
    'attachment',
    'compassion',
  ];

  static const _seekingKey = 'gita_wisdom_personalization_seeking';
  static const _languageKey = 'gita_wisdom_personalization_language';
  static const _reminderHourKey = 'gita_wisdom_personalization_reminder_hour';
  static const _reminderMinuteKey =
      'gita_wisdom_personalization_reminder_minute';

  static const _themeCountsKey = 'gita_personal_theme_counts';
  static const _recentThemesKey = 'gita_personal_recent_themes';
  static const _openedVersesKey = 'gita_personal_opened_verses';
  static const _askTopicsKey = 'gita_personal_ask_topics';
  static const _searchTopicsKey = 'gita_personal_search_topics';
  static const _completedJourneySignalsKey = 'gita_personal_completed_journeys';

  static Future<PersonalizationProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return PersonalizationProfile(
      seeking: prefs.getString(_seekingKey) ??
          PersonalizationProfile.defaultProfile.seeking,
      language: prefs.getString(_languageKey) ??
          PersonalizationProfile.defaultProfile.language,
      reminderHour: prefs.getInt(_reminderHourKey) ??
          PersonalizationProfile.defaultProfile.reminderHour,
      reminderMinute: prefs.getInt(_reminderMinuteKey) ??
          PersonalizationProfile.defaultProfile.reminderMinute,
    );
  }

  static Future<void> saveProfile(PersonalizationProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seekingKey, profile.seeking);
    await prefs.setString(_languageKey, profile.language);
    await prefs.setInt(_reminderHourKey, profile.reminderHour);
    await prefs.setInt(_reminderMinuteKey, profile.reminderMinute);
    await recordThemes([profile.seeking], weight: 1);
  }

  static Future<UserInterestProfile> interestProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return UserInterestProfile(
        themeCounts: _decodeCounts(prefs.getString(_themeCountsKey)),
        recentThemes: (prefs.getStringList(_recentThemesKey) ?? const [])
            .map(_canonicalTheme)
            .whereType<String>()
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      debugPrint('Personalization profile load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const UserInterestProfile(themeCounts: {}, recentThemes: []);
    }
  }

  static Future<void> recordVerseOpened(GitaVerseData verse) async {
    await _rememberValue(_openedVersesKey, verse.id, limit: 50);
    await recordThemes(_themesForVerse(verse), weight: 1);
  }

  static Future<void> recordVerseSaved(GitaVerseData verse) async {
    await recordThemes(_themesForVerse(verse), weight: 3);
  }

  static Future<void> recordVerseHighlighted(GitaVerseData verse) async {
    await recordThemes(_themesForVerse(verse), weight: 2);
  }

  static Future<void> recordJournalActivity(String text) async {
    await recordThemes(_themesForText(text), weight: 1);
  }

  static Future<void> recordAskGitaTopic(String topic) async {
    final canonical = _canonicalTheme(topic);
    if (canonical == null) {
      return;
    }
    await _rememberValue(_askTopicsKey, canonical, limit: 25);
    await recordThemes([canonical], weight: 2);
  }

  static Future<void> recordAskGitaQuestion(String question) async {
    final matchedThemes = _themesForText(question);
    if (matchedThemes.isEmpty) {
      return;
    }
    await _rememberValue(_askTopicsKey, matchedThemes.first, limit: 25);
    await recordThemes(matchedThemes, weight: 2);
  }

  static Future<void> recordEmotionalSearch(String query) async {
    final matchedThemes = _themesForText(query);
    if (matchedThemes.isEmpty) {
      return;
    }
    await _rememberValue(_searchTopicsKey, matchedThemes.first, limit: 25);
    await recordThemes(matchedThemes, weight: 2);
  }

  static Future<void> recordJourneyCompleted(String journeyId) async {
    await _rememberValue(_completedJourneySignalsKey, journeyId, limit: 20);
    await recordThemes(_themesForJourney(journeyId), weight: 3);
  }

  static Future<List<GitaVerseData>> recommendedVerses({
    int limit = 4,
  }) async {
    final profile = await interestProfile();
    if (!profile.hasSignals) {
      return const [];
    }
    final openedIds = await _rememberedValues(_openedVersesKey);
    final selected = <String, GitaVerseData>{};
    for (final topic in _guidanceTopicsFor(profile.topThemes)) {
      final verses = await _recommendedVersesFor(topic, limit: limit + 4);
      for (final verse in verses) {
        if (openedIds.contains(verse.id)) {
          continue;
        }
        selected[verse.id] = verse;
        if (selected.length >= limit) {
          return selected.values.toList(growable: false);
        }
      }
    }
    return selected.values.take(limit).toList(growable: false);
  }

  static Future<List<String>> suggestedJourneyIds({
    Iterable<String> excludeJourneyIds = const [],
  }) async {
    const fallback = [
      'journey_discipline_14',
      'journey_karma_yoga_14',
      'journey_anxiety_7',
      'journey_clarity_21',
      'journey_peace_7',
    ];
    final excluded = excludeJourneyIds.toSet();
    final profile = await interestProfile();
    final suggested = <String>[];
    if (profile.hasSignals) {
      for (final theme in profile.topThemes) {
        suggested.addAll(_journeysForTheme(theme));
      }
    }
    suggested.addAll(fallback);
    return _dedupe(suggested)
        .where((id) => !excluded.contains(id))
        .toList(growable: false);
  }

  static Future<void> recordThemes(
    Iterable<String> rawThemes, {
    int weight = 1,
  }) async {
    final normalizedThemes = rawThemes
        .map(_canonicalTheme)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    if (normalizedThemes.isEmpty) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final counts = _decodeCounts(prefs.getString(_themeCountsKey));
      for (final theme in normalizedThemes) {
        counts[theme] = (counts[theme] ?? 0) + weight;
      }
      await prefs.setString(_themeCountsKey, jsonEncode(counts));
      final recent = [
        ...normalizedThemes,
        ...(prefs.getStringList(_recentThemesKey) ?? const <String>[]),
      ];
      await prefs.setStringList(
        _recentThemesKey,
        _dedupe(recent).take(12).toList(growable: false),
      );
    } catch (error, stackTrace) {
      debugPrint('Personalization signal save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<DailyGuidance> personalizedTodaysGuidance([
    DateTime? date,
  ]) async {
    final profile = await interestProfile();
    if (!profile.hasSignals) {
      return DailyCompanionService.todaysGuidance(date);
    }
    final preferredTopics = _guidanceTopicsFor(profile.topThemes);
    for (final topic in preferredTopics) {
      for (final item in DailyCompanionService.guidanceItems) {
        if (item.topic == topic) {
          return item;
        }
      }
    }
    return DailyCompanionService.todaysGuidance(date);
  }

  static Future<GitaVerseData> personalizedDailyVerse() async {
    final guidance = await personalizedTodaysGuidance();
    final verse = await GitaRepository.verseById(guidance.verseId);
    if (verse != null) {
      return verse;
    }
    final profile = await interestProfile();
    final query = profile.topThemes.isEmpty
        ? _queryFor((await loadProfile()).seeking)
        : profile.topThemes.join(' ');
    final results = await GitaRepository.search(query);
    if (results.isNotEmpty) {
      return results.first.verse;
    }
    return GitaRepository.dailyVerse();
  }

  static Future<List<PersonalizedRecommendation>> recommendations({
    int limit = 2,
  }) async {
    final profile = await interestProfile();
    if (!profile.hasSignals) {
      return const [];
    }

    final recommendations = <PersonalizedRecommendation>[];
    final completedJourneys = await _rememberedValues(
      _completedJourneySignalsKey,
    );
    if (completedJourneys.contains('journey_peace_7')) {
      recommendations.add(
        const PersonalizedRecommendation(
          title: 'Journey of Discipline',
          subtitle: 'Turn yesterday\'s peace into one steady habit.',
          reason: 'Continue what you began',
          journeyId: 'journey_discipline_14',
        ),
      );
    }

    final topThemes = profile.topThemes;
    final topTheme = topThemes.isEmpty ? null : topThemes.first;
    if (topTheme != null) {
      final verse = await _recommendedVerseFor(topTheme);
      if (verse != null) {
        recommendations.add(
          PersonalizedRecommendation(
            title: verse.shortReference,
            subtitle: _recommendationSubtitleFor(topTheme),
            reason: 'For ${_themeLabel(topTheme)}',
            verseId: verse.id,
          ),
        );
      }
    }

    if (recommendations.length < limit) {
      final journeyIds = await suggestedJourneyIds();
      for (final journeyId in journeyIds) {
        if (completedJourneys.contains(journeyId)) {
          continue;
        }
        final journey = _journeyRecommendationFor(journeyId);
        if (journey != null) {
          recommendations.add(journey);
        }
        if (recommendations.length >= limit) {
          break;
        }
      }
    }

    return recommendations.take(limit).toList(growable: false);
  }

  static Future<List<String>> personalizedAskSuggestions() async {
    final profile = await interestProfile();
    final themes = profile.topThemes;
    if (themes.isNotEmpty) {
      return [
        for (final theme in themes.take(3)) ..._suggestionsFor(theme),
      ].take(6).toList(growable: false);
    }

    final legacyProfile = await loadProfile();
    final seeking = legacyProfile.seeking.toLowerCase();
    final language = legacyProfile.language;
    return [
      'What does the Gita teach about $seeking?',
      'Give me one practice for $seeking today',
      'Which verse should I reflect on for $seeking?',
      if (language != 'English')
        'Explain $seeking simply for a $language-speaking reader',
      ..._suggestionsFor(legacyProfile.seeking),
    ].take(6).toList(growable: false);
  }

  static Future<void> clearLocalPersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seekingKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_reminderHourKey);
    await prefs.remove(_reminderMinuteKey);
    await prefs.remove(_themeCountsKey);
    await prefs.remove(_recentThemesKey);
    await prefs.remove(_openedVersesKey);
    await prefs.remove(_askTopicsKey);
    await prefs.remove(_searchTopicsKey);
    await prefs.remove(_completedJourneySignalsKey);
  }

  static List<String> relatedThemesForAsk(String topic) {
    final canonical = _canonicalTheme(topic);
    if (canonical == null) {
      return const [];
    }
    return switch (canonical) {
      'fear' => const ['peace', 'clarity', 'attachment'],
      'anger' => const ['peace', 'compassion', 'discipline'],
      'attachment' => const ['peace', 'discipline', 'clarity'],
      'discipline' => const ['discipline', 'clarity'],
      'purpose' => const ['clarity', 'discipline'],
      'devotion' => const ['compassion', 'peace'],
      _ => [canonical],
    };
  }

  static Map<String, int> _decodeCounts(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return <String, int>{};
    }
    return decoded.map((key, value) {
      final theme = _canonicalTheme(key);
      return MapEntry(theme ?? key, value is num ? value.toInt() : 0);
    })
      ..removeWhere((key, _) => !themes.contains(key));
  }

  static Future<void> _rememberValue(
    String key,
    String value, {
    required int limit,
  }) async {
    if (value.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final values = [
      value.trim(),
      ...(prefs.getStringList(key) ?? const <String>[]),
    ];
    await prefs.setStringList(
      key,
      _dedupe(values).take(limit).toList(growable: false),
    );
  }

  static Future<Set<String>> _rememberedValues(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? const []).toSet();
  }

  static List<String> _dedupe(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }

  static List<String> _themesForVerse(GitaVerseData verse) {
    final tags = verse.allTags.map(_canonicalTheme).whereType<String>();
    final fromText = _themesForText([
      verse.gitaWisdomInterpretation,
      verse.reflectionText,
      verse.practiceToday,
      verse.englishTranslation,
    ].join(' '));
    return {...tags, ...fromText}.toList(growable: false);
  }

  static List<String> _themesForText(String text) {
    final lower = text.toLowerCase();
    final matches = <String>{};
    for (final entry in _themeSynonyms.entries) {
      if (entry.value.any((term) => lower.contains(term))) {
        matches.add(entry.key);
      }
    }
    return matches.toList(growable: false);
  }

  static List<String> _themesForJourney(String journeyId) {
    return switch (journeyId) {
      'journey_peace_7' => const ['peace', 'clarity'],
      'journey_discipline_14' => const ['discipline', 'clarity'],
      'journey_karma_yoga_14' => const ['purpose', 'attachment'],
      'journey_anxiety_7' => const ['fear', 'peace'],
      'journey_clarity_21' => const ['clarity', 'purpose'],
      _ => const [],
    };
  }

  static List<String> _guidanceTopicsFor(List<String> topThemes) {
    final topics = <String>[];
    for (final theme in topThemes) {
      topics.addAll(switch (theme) {
        'fear' => const ['peace', 'clarity'],
        'anger' => const ['peace', 'compassion'],
        'attachment' => const ['attachment', 'peace'],
        'discipline' => const ['discipline', 'clarity'],
        'purpose' => const ['clarity', 'discipline'],
        'devotion' => const ['devotion', 'compassion'],
        'compassion' => const ['compassion', 'devotion'],
        _ => [theme],
      });
    }
    return _dedupe(topics);
  }

  static Future<GitaVerseData?> _recommendedVerseFor(String theme) async {
    final verses = await _recommendedVersesFor(theme, limit: 1);
    return verses.isEmpty ? null : verses.first;
  }

  static Future<List<GitaVerseData>> _recommendedVersesFor(
    String theme, {
    required int limit,
  }) async {
    final query = switch (theme) {
      'fear' => 'peace steadiness trust fear uncertainty',
      'anger' => 'anger patience compassion self-control',
      'attachment' => 'attachment results action peace',
      'discipline' => 'discipline focus mind practice',
      'purpose' => 'purpose dharma duty clarity service',
      'devotion' => 'devotion compassion surrender service',
      'compassion' => 'compassion kindness devotion',
      'clarity' => 'clarity wisdom mind steady',
      'peace' => 'peace calm steady mind trust',
      _ => 'peace mind steady',
    };
    final results = await GitaRepository.search(query, limit: limit + 6);
    final enriched = [
      for (final result in results)
        if (result.verse.hasEnrichment) result.verse,
    ];
    final all = [
      ...enriched,
      for (final result in results)
        if (!enriched.any((verse) => verse.id == result.verse.id)) result.verse,
    ];
    return {
      for (final verse in all) verse.id: verse,
    }.values.take(limit).toList(growable: false);
  }

  static String _recommendationSubtitleFor(String theme) {
    return switch (theme) {
      'fear' => 'Read for steadiness; practice one trusted step.',
      'anger' => 'Read before reacting; practice one pause.',
      'attachment' => 'Read for effort; practice releasing one result.',
      'discipline' => 'Read for steadiness; practice one focused action.',
      'purpose' => 'Read for direction; practice the duty nearest to you.',
      'devotion' => 'Read for devotion; practice one sincere offering.',
      'compassion' => 'Read for gentleness; practice one kinder response.',
      'clarity' => 'Read for clarity; practice one honest decision.',
      'peace' => 'Read for calm; practice carrying one insight.',
      _ => 'Read once; carry one small action.',
    };
  }

  static String _queryFor(String seeking) {
    return switch (seeking.toLowerCase()) {
      'purpose' => 'purpose duty dharma action',
      'discipline' => 'discipline mind practice self control',
      'devotion' => 'devotion bhakti love surrender',
      'clarity' => 'clarity wisdom knowledge discernment',
      _ => 'peace calm anxiety steady mind',
    };
  }

  static List<String> _suggestionsFor(String seeking) {
    return switch (_canonicalTheme(seeking) ?? seeking.toLowerCase()) {
      'purpose' => [
          'How do I understand my dharma?',
          'How do I act without fear?',
        ],
      'discipline' => [
          'How can I control the restless mind?',
          'What daily discipline does the Gita suggest?',
        ],
      'devotion' => [
          'How do I practice devotion daily?',
          'What does surrender mean in daily life?',
        ],
      'clarity' => [
          'How do I make a wise decision?',
          'How do I see clearly when confused?',
        ],
      'fear' => [
          'How do I stop worrying?',
          'How can I act with courage?',
        ],
      'anger' => [
          'How do I pause before reacting?',
          'How can I calm anger?',
        ],
      _ => [
          'How can I steady my mind today?',
          'What does the Gita say about anxiety?',
        ],
    };
  }

  static String _themeLabel(String theme) {
    return switch (theme) {
      'self-control' => 'self-control',
      _ => '${theme[0].toUpperCase()}${theme.substring(1)}',
    };
  }

  static String? _canonicalTheme(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) {
      return null;
    }
    if (themes.contains(lower)) {
      return lower;
    }
    for (final entry in _themeSynonyms.entries) {
      if (entry.value.contains(lower)) {
        return entry.key;
      }
    }
    if (lower.contains('anx') ||
        lower.contains('worr') ||
        lower.contains('uncertain') ||
        lower.contains('failure')) {
      return 'fear';
    }
    if (lower.contains('focus') || lower.contains('self-control')) {
      return 'discipline';
    }
    if (lower.contains('meaning') || lower.contains('direction')) {
      return 'purpose';
    }
    if (lower.contains('relationship') || lower.contains('kindness')) {
      return 'compassion';
    }
    if (lower.contains('karma') || lower.contains('duty')) {
      return 'purpose';
    }
    return null;
  }

  static List<String> _journeysForTheme(String theme) {
    return switch (theme) {
      'fear' => const ['journey_anxiety_7', 'journey_peace_7'],
      'anger' => const ['journey_peace_7', 'journey_discipline_14'],
      'attachment' => const ['journey_karma_yoga_14', 'journey_peace_7'],
      'discipline' => const ['journey_discipline_14'],
      'purpose' => const ['journey_karma_yoga_14', 'journey_clarity_21'],
      'devotion' => const ['journey_karma_yoga_14', 'journey_peace_7'],
      'clarity' => const ['journey_clarity_21', 'journey_discipline_14'],
      'compassion' => const ['journey_peace_7', 'journey_karma_yoga_14'],
      _ => const ['journey_peace_7'],
    };
  }

  static PersonalizedRecommendation? _journeyRecommendationFor(
    String journeyId,
  ) {
    return switch (journeyId) {
      'journey_peace_7' => const PersonalizedRecommendation(
          title: 'Journey to Peace',
          subtitle: 'Practice calm through one guided reflection at a time.',
          reason: 'A path for daily practice',
          journeyId: 'journey_peace_7',
        ),
      'journey_discipline_14' => const PersonalizedRecommendation(
          title: 'Journey of Discipline',
          subtitle: 'Build focus through one sincere step each day.',
          reason: 'A path for daily practice',
          journeyId: 'journey_discipline_14',
        ),
      'journey_karma_yoga_14' => const PersonalizedRecommendation(
          title: 'Journey of Karma Yoga',
          subtitle: 'Practice action without clinging to the result.',
          reason: 'A path for daily practice',
          journeyId: 'journey_karma_yoga_14',
        ),
      'journey_anxiety_7' => const PersonalizedRecommendation(
          title: 'Journey Through Anxiety',
          subtitle: 'Return from worry to one grounded step.',
          reason: 'A path for daily practice',
          journeyId: 'journey_anxiety_7',
        ),
      'journey_clarity_21' => const PersonalizedRecommendation(
          title: 'Journey to Inner Clarity',
          subtitle: 'Reflect daily until the next right step becomes clearer.',
          reason: 'A path for daily practice',
          journeyId: 'journey_clarity_21',
        ),
      _ => null,
    };
  }
}

const _themeSynonyms = <String, List<String>>{
  'peace': [
    'peace',
    'calm',
    'steady',
    'steadiness',
    'restless',
    'trust',
  ],
  'fear': [
    'fear',
    'afraid',
    'scared',
    'anxiety',
    'anxious',
    'worry',
    'worried',
    'uncertainty',
    'uncertain',
    'failure',
    'stress',
    'overwhelmed',
  ],
  'anger': ['anger', 'angry', 'rage', 'frustration', 'resentment', 'irritat'],
  'attachment': ['attachment', 'attached', 'result', 'outcome', 'fruit'],
  'discipline': [
    'discipline',
    'focus',
    'practice',
    'habit',
    'self-control',
    'control',
  ],
  'purpose': [
    'purpose',
    'meaning',
    'direction',
    'dharma',
    'calling',
    'duty',
    'karma',
    'service',
    'work',
    'responsibility',
    'offering',
  ],
  'clarity': ['clarity', 'wisdom', 'discernment', 'confused', 'decision'],
  'devotion': ['devotion', 'devoted', 'bhakti', 'surrender', 'krishna', 'god'],
  'compassion': [
    'compassion',
    'kindness',
    'gentleness',
    'relationship',
    'family',
    'friend',
  ],
};
