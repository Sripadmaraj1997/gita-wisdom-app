/// ------------------------------------------------------------
/// StorageService
///
/// Purpose:
/// Single local persistence boundary for the offline-first app.
///
/// Responsibilities:
/// - Store saved verses, highlights, saved reflections, journal entries, and
///   Ask Gita history.
/// - Store reader preferences and Continue/Journey continuity.
/// - Track Days of Reflection without pressure or account identity.
/// - Keep UI widgets from reading SharedPreferences directly.
///
/// Architecture:
/// Gita Wisdom intentionally has no Firebase, cloud account, or OpenAI runtime
/// dependency. Screens call this service for private local state, while
/// scripture and editorial content come from bundled JSON assets.
///
/// SharedPreferences keys:
/// - gita_saved_verses: JSON list of saved scripture snapshots.
/// - gita_saved_reflections: JSON list of saved reflection/practice snapshots.
/// - gita_highlighted_verses: string list of highlighted verse IDs.
/// - gita_journal_entries: JSON list of local journal entries.
/// - gita_ask_history: compact local Ask Gita history.
/// - gita_recent_verses: recently opened verse snapshots for continuity.
/// - gita_recent_reflections: recently reflected topics/verses for Home.
/// - gita_completed_practice_dates: date keys for Days of Reflection.
/// - gita_reader_font_scale: reader typography preference.
/// - gita_reader_show_sanskrit: Sanskrit visibility preference.
/// - gita_reader_show_transliteration: transliteration visibility preference.
/// - gita_theme_mode: local visual theme choice.
/// - gita_current_journey: currentJourneyId; active guided path.
/// - gita_current_journey_day: currentJourneyDay; day to resume.
/// - gita_reading_plan_progress: completedDaysByJourney as {journeyId: [days]}.
/// - gita_completed_journeys: completedJourneyIds for completion state on Home.
///
/// TODO(cloud-sync): Keep these keys as the local cache contract if accounts
/// are introduced later.
/// ------------------------------------------------------------
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gita_data.dart';
import 'personalization_service.dart';

class LocalSavedVerse {
  const LocalSavedVerse({
    required this.id,
    required this.verseId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.sanskrit,
    required this.translation,
    required this.savedAt,
  });

  factory LocalSavedVerse.fromJson(Map<String, dynamic> json) {
    final chapterNumber = _readInt(json['chapterNumber']);
    final verseNumber = _readInt(json['verseNumber']);
    return LocalSavedVerse(
      id: (json['id'] as String?) ?? '$chapterNumber.$verseNumber',
      verseId: (json['verseId'] as String?) ?? '$chapterNumber.$verseNumber',
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      sanskrit: (json['sanskrit'] as String?) ?? '',
      translation: (json['translation'] as String?) ?? '',
      savedAt: _readDate(json['savedAt']),
    );
  }

  factory LocalSavedVerse.fromVerse(GitaVerseData verse) {
    return LocalSavedVerse(
      id: verse.id,
      verseId: verse.id,
      chapterNumber: verse.chapterNumber,
      verseNumber: verse.verseNumber,
      sanskrit: verse.sanskrit,
      translation: verse.englishTranslation,
      savedAt: DateTime.now(),
    );
  }

  final String id;
  final String verseId;
  final int chapterNumber;
  final int verseNumber;
  final String sanskrit;
  final String translation;
  final DateTime savedAt;

  String get reference => 'Gita $chapterNumber.$verseNumber';

  Map<String, dynamic> toJson() => {
        'id': id,
        'verseId': verseId,
        'chapterNumber': chapterNumber,
        'verseNumber': verseNumber,
        'sanskrit': sanskrit,
        'translation': translation,
        'savedAt': savedAt.toIso8601String(),
      };
}

class LocalSavedReflection {
  const LocalSavedReflection({
    required this.id,
    required this.verseId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseReference,
    required this.reflection,
    required this.practiceToday,
    required this.englishTranslation,
    required this.savedAt,
  });

  factory LocalSavedReflection.fromJson(Map<String, dynamic> json) {
    final chapterNumber = _readInt(json['chapterNumber']);
    final verseNumber = _readInt(json['verseNumber']);
    return LocalSavedReflection(
      id: (json['id'] as String?) ?? '$chapterNumber.$verseNumber',
      verseId: (json['verseId'] as String?) ?? '$chapterNumber.$verseNumber',
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
      verseReference: (json['verseReference'] as String?) ??
          'Bhagavad Gita $chapterNumber.$verseNumber',
      reflection: (json['reflection'] as String?) ?? '',
      practiceToday: (json['practiceToday'] as String?) ?? '',
      englishTranslation: (json['englishTranslation'] as String?) ?? '',
      savedAt: _readDate(json['savedAt']),
    );
  }

  factory LocalSavedReflection.fromVerse(
    GitaVerseData verse, {
    String? reflection,
    String? practiceToday,
  }) {
    return LocalSavedReflection(
      id: verse.id,
      verseId: verse.id,
      chapterNumber: verse.chapterNumber,
      verseNumber: verse.verseNumber,
      verseReference: verse.reference,
      reflection: reflection ?? verse.reflectionText,
      practiceToday: practiceToday ?? verse.practiceToday,
      englishTranslation: verse.englishTranslation,
      savedAt: DateTime.now(),
    );
  }

  final String id;
  final String verseId;
  final int chapterNumber;
  final int verseNumber;
  final String verseReference;
  final String reflection;
  final String practiceToday;
  final String englishTranslation;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'verseId': verseId,
        'chapterNumber': chapterNumber,
        'verseNumber': verseNumber,
        'verseReference': verseReference,
        'reflection': reflection,
        'practiceToday': practiceToday,
        'englishTranslation': englishTranslation,
        'savedAt': savedAt.toIso8601String(),
      };
}

class LocalJournalEntry {
  const LocalJournalEntry({
    required this.id,
    required this.title,
    required this.text,
    required this.mood,
    required this.intention,
    required this.gratitude,
    required this.actionStep,
    required this.linkedVerse,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocalJournalEntry.create({
    required String title,
    required String text,
    required String mood,
    String intention = '',
    String gratitude = '',
    String actionStep = '',
    String linkedVerse = '',
  }) {
    final now = DateTime.now();
    return LocalJournalEntry(
      id: 'journal_${now.microsecondsSinceEpoch}',
      title: title,
      text: text,
      mood: mood,
      intention: intention,
      gratitude: gratitude,
      actionStep: actionStep,
      linkedVerse: linkedVerse,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory LocalJournalEntry.fromJson(Map<String, dynamic> json) {
    return LocalJournalEntry(
      id: (json['id'] as String?) ??
          'journal_${DateTime.now().microsecondsSinceEpoch}',
      title: (json['title'] as String?) ?? 'Untitled reflection',
      text: (json['text'] as String?) ?? '',
      mood: (json['mood'] as String?) ?? 'Peaceful',
      intention: (json['intention'] as String?) ?? '',
      gratitude: (json['gratitude'] as String?) ?? '',
      actionStep: (json['actionStep'] as String?) ?? '',
      linkedVerse: (json['linkedVerse'] as String?) ?? '',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  final String id;
  final String title;
  final String text;
  final String mood;
  final String intention;
  final String gratitude;
  final String actionStep;
  final String linkedVerse;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get formattedDate {
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '$month/$day/${createdAt.year}';
  }

  String get searchableText => [
        title,
        text,
        mood,
        intention,
        gratitude,
        actionStep,
        linkedVerse,
      ].join(' ');

  LocalJournalEntry copyWith({
    String? title,
    String? text,
    String? mood,
    String? intention,
    String? gratitude,
    String? actionStep,
    String? linkedVerse,
  }) {
    return LocalJournalEntry(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      intention: intention ?? this.intention,
      gratitude: gratitude ?? this.gratitude,
      actionStep: actionStep ?? this.actionStep,
      linkedVerse: linkedVerse ?? this.linkedVerse,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'mood': mood,
        'intention': intention,
        'gratitude': gratitude,
        'actionStep': actionStep,
        'linkedVerse': linkedVerse,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class AskGitaHistoryEntry {
  const AskGitaHistoryEntry({
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory AskGitaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AskGitaHistoryEntry(
      question: (json['question'] as String?) ?? '',
      answer: (json['answer'] as String?) ?? '',
      createdAt: _readDate(json['createdAt']),
    );
  }

  final String question;
  final String answer;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'createdAt': createdAt.toIso8601String(),
      };
}

class LocalRecentVerse {
  const LocalRecentVerse({
    required this.verseId,
    required this.reference,
    required this.translation,
    required this.openedAt,
  });

  factory LocalRecentVerse.fromJson(Map<String, dynamic> json) {
    final chapterNumber = _readInt(json['chapterNumber']);
    final verseNumber = _readInt(json['verseNumber']);
    return LocalRecentVerse(
      verseId: (json['verseId'] as String?) ?? '$chapterNumber.$verseNumber',
      reference: (json['reference'] as String?) ??
          'Bhagavad Gita $chapterNumber.$verseNumber',
      translation: (json['translation'] as String?) ?? '',
      openedAt: _readDate(json['openedAt']),
    );
  }

  factory LocalRecentVerse.fromVerse(GitaVerseData verse) {
    return LocalRecentVerse(
      verseId: verse.id,
      reference: verse.reference,
      translation: verse.englishTranslation,
      openedAt: DateTime.now(),
    );
  }

  final String verseId;
  final String reference;
  final String translation;
  final DateTime openedAt;

  Map<String, dynamic> toJson() => {
        'verseId': verseId,
        'reference': reference,
        'translation': translation,
        'openedAt': openedAt.toIso8601String(),
      };
}

class LocalReflectedItem {
  const LocalReflectedItem({
    required this.id,
    required this.type,
    required this.label,
    required this.reflectedAt,
    this.verseId,
    this.topic,
  });

  factory LocalReflectedItem.fromJson(Map<String, dynamic> json) {
    return LocalReflectedItem(
      id: (json['id'] as String?) ??
          'reflection_${DateTime.now().microsecondsSinceEpoch}',
      type: (json['type'] as String?) ?? 'topic',
      label: (json['label'] as String?) ?? 'Reflection',
      verseId: json['verseId'] as String?,
      topic: json['topic'] as String?,
      reflectedAt: _readDate(json['reflectedAt']),
    );
  }

  factory LocalReflectedItem.fromVerse(GitaVerseData verse) {
    return LocalReflectedItem(
      id: 'verse_${verse.id}',
      type: 'verse',
      label: verse.reference,
      verseId: verse.id,
      reflectedAt: DateTime.now(),
    );
  }

  factory LocalReflectedItem.fromTopic(String topic) {
    final normalized = topic.trim();
    return LocalReflectedItem(
      id: 'topic_${normalized.toLowerCase()}',
      type: 'topic',
      label: normalized,
      topic: normalized.toLowerCase(),
      reflectedAt: DateTime.now(),
    );
  }

  final String id;
  final String type;
  final String label;
  final String? verseId;
  final String? topic;
  final DateTime reflectedAt;

  bool get isVerse => type == 'verse' && verseId != null;
  bool get isTopic => type == 'topic' && topic != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'verseId': verseId,
        'topic': topic,
        'reflectedAt': reflectedAt.toIso8601String(),
      };
}

class LocalStorageService {
  const LocalStorageService._();

  // Storage keys are intentionally namespaced with "gita_" where possible.
  // If cloud sync is added later, these keys define the local cache contract.
  // TODO(cloud-sync): Move these calls behind a sync repository if accounts are
  // introduced, while preserving these keys for local-first migration.
  //
  // User-owned collections:
  // These values represent private device-local activity. Saved verses keep a
  // small snapshot for fast display, while highlights keep verse IDs so the
  // latest local Gita JSON remains the source of scripture text.
  static const savedVersesKey = 'gita_saved_verses';
  static const savedReflectionsKey = 'gita_saved_reflections';
  static const highlightedVersesKey = 'gita_highlighted_verses';
  static const journalEntriesKey = 'gita_journal_entries';
  static const askHistoryKey = 'gita_ask_history';
  static const recentVersesKey = 'gita_recent_verses';

  // Journey continuity:
  // The progress key keeps its original "reading_plan" value for migration
  // safety, but all user-facing copy now calls the feature Journeys.
  static const journeyProgressKey = 'gita_reading_plan_progress';
  static const completedJourneysKey = 'gita_completed_journeys';
  static const currentJourneyKey = 'gita_current_journey';
  static const currentJourneyDayKey = 'gita_current_journey_day';

  // Reader preferences:
  // These are intentionally simple scalar preferences so Verse Reader can
  // restore typography and Sanskrit/transliteration visibility instantly.
  static const readerFontScaleKey = 'gita_reader_font_scale';
  static const readerShowSanskritKey = 'gita_reader_show_sanskrit';
  static const readerShowTransliterationKey =
      'gita_reader_show_transliteration';

  // Daily reflection memory:
  // These keys drive the gentle "Days of Reflection" and recent activity
  // surfaces without requiring accounts, tracking, or remote analytics.
  static const completedPracticeDatesKey = 'gita_completed_practice_dates';
  static const recentReflectionsKey = 'gita_recent_reflections';
  static const themeModeKey = 'gita_theme_mode';

  // Screens listen to this notifier to refresh journey cards immediately after
  // progress changes, instead of waiting for a full route rebuild or app restart.
  static final ValueNotifier<int> journeyProgressRevision =
      ValueNotifier<int>(0);

  // Saved/highlight storage:
  // Saved verses store compact snapshots for fast rendering. Highlights store
  // only IDs because scripture content remains owned by the local Gita JSON.
  static Future<List<LocalSavedVerse>> savedVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(savedVersesKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalSavedVerse.fromJson)
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (error, stackTrace) {
      debugPrint('Local saved verses load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  static Future<bool> isVerseSaved(String verseId) async {
    final verses = await savedVerses();
    return verses.any((verse) => verse.verseId == verseId);
  }

  static Future<void> saveVerse(GitaVerseData verse) async {
    // Save operations are idempotent: the newest copy is moved to the front and
    // older duplicates are removed.
    final verses = await savedVerses();
    final updated = [
      LocalSavedVerse.fromVerse(verse),
      ...verses.where((saved) => saved.verseId != verse.id),
    ];
    await _saveJsonList(savedVersesKey, updated.map((item) => item.toJson()));
    await PersonalizationService.recordVerseSaved(verse);
  }

  static Future<void> removeSavedVerse(String verseId) async {
    final verses = await savedVerses();
    final updated = verses.where((verse) => verse.verseId != verseId);
    await _saveJsonList(savedVersesKey, updated.map((item) => item.toJson()));
  }

  static Future<List<LocalSavedReflection>> savedReflections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(savedReflectionsKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalSavedReflection.fromJson)
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (error, stackTrace) {
      debugPrint('Local saved reflections load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  static Future<bool> isReflectionSaved(String verseId) async {
    final reflections = await savedReflections();
    return reflections.any((reflection) => reflection.verseId == verseId);
  }

  static Future<void> saveReflection(
    GitaVerseData verse, {
    String? reflection,
    String? practiceToday,
  }) async {
    final reflections = await savedReflections();
    final updated = [
      LocalSavedReflection.fromVerse(
        verse,
        reflection: reflection,
        practiceToday: practiceToday,
      ),
      ...reflections.where((reflection) => reflection.verseId != verse.id),
    ];
    await _saveJsonList(
      savedReflectionsKey,
      updated.map((item) => item.toJson()),
    );
    await PersonalizationService.recordThemes(verse.allTags, weight: 2);
  }

  static Future<void> removeSavedReflection(String verseId) async {
    final reflections = await savedReflections();
    final updated =
        reflections.where((reflection) => reflection.verseId != verseId);
    await _saveJsonList(
      savedReflectionsKey,
      updated.map((item) => item.toJson()),
    );
  }

  static Future<Set<String>> highlightedVerseIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(highlightedVersesKey) ?? const []).toSet();
    } catch (error, stackTrace) {
      debugPrint('Local highlights load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <String>{};
    }
  }

  static Future<bool> isVerseHighlighted(String verseId) async {
    final ids = await highlightedVerseIds();
    return ids.contains(verseId);
  }

  static Future<void> setVerseHighlighted(
    String verseId, {
    required bool highlighted,
  }) async {
    try {
      // Highlights are lightweight verse IDs rather than full verse payloads.
      // The Saved screen resolves IDs through GitaDataService when displaying.
      final prefs = await SharedPreferences.getInstance();
      final ids = await highlightedVerseIds();
      if (highlighted) {
        ids.add(verseId);
      } else {
        ids.remove(verseId);
      }
      await prefs.setStringList(highlightedVersesKey, ids.toList()..sort());
    } catch (error, stackTrace) {
      debugPrint('Local highlight save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<List<LocalJournalEntry>> journalEntries() async {
    // Journal notes are user-authored local data. They are intentionally kept
    // separate from scripture, translation, Gita Wisdom Interpretation, and
    // reflection datasets.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(journalEntriesKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalJournalEntry.fromJson)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (error, stackTrace) {
      debugPrint('Local journal load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  static Future<void> upsertJournalEntry(LocalJournalEntry entry) async {
    final entries = await journalEntries();
    final updated = [
      entry,
      ...entries.where((item) => item.id != entry.id),
    ];
    await _saveJsonList(
      journalEntriesKey,
      updated.map((item) => item.toJson()),
    );
    await recordJournalReflection();
    await PersonalizationService.recordJournalActivity(entry.searchableText);
  }

  static Future<void> deleteJournalEntry(String id) async {
    final entries = await journalEntries();
    final updated = entries.where((entry) => entry.id != id);
    await _saveJsonList(
      journalEntriesKey,
      updated.map((item) => item.toJson()),
    );
  }

  static Future<void> recordAskGitaHistory({
    required String question,
    required String answer,
  }) async {
    try {
      // Keep only a compact local history so the MVP remains lightweight.
      final history = await askGitaHistory();
      final updated = [
        AskGitaHistoryEntry(
          question: question,
          answer: answer,
          createdAt: DateTime.now(),
        ),
        ...history,
      ].take(25);
      await _saveJsonList(askHistoryKey, updated.map((item) => item.toJson()));
    } catch (error, stackTrace) {
      debugPrint('Ask Gita local history save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<List<LocalRecentVerse>> recentVerses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(recentVersesKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalRecentVerse.fromJson)
          .toList()
        ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    } catch (error, stackTrace) {
      debugPrint('Recent verses load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  static Future<void> recordRecentVerse(GitaVerseData verse) async {
    try {
      final recent = await recentVerses();
      // Home only needs a short "recently opened" list for quick return.
      final updated = [
        LocalRecentVerse.fromVerse(verse),
        ...recent.where((item) => item.verseId != verse.id),
      ].take(3);
      await _saveJsonList(
          recentVersesKey, updated.map((item) => item.toJson()));
      await PersonalizationService.recordVerseOpened(verse);
    } catch (error, stackTrace) {
      debugPrint('Recent verse save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<List<LocalReflectedItem>> recentReflections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(recentReflectionsKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocalReflectedItem.fromJson)
          .toList()
        ..sort((a, b) => b.reflectedAt.compareTo(a.reflectedAt));
    } catch (error, stackTrace) {
      debugPrint('Recent reflections load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  static Future<void> recordReflectedVerse(GitaVerseData verse) async {
    await _recordReflectedItem(LocalReflectedItem.fromVerse(verse));
  }

  static Future<void> recordReflectedTopic(String topic) async {
    if (topic.trim().isEmpty) {
      return;
    }
    await _recordReflectedItem(LocalReflectedItem.fromTopic(topic));
    await PersonalizationService.recordEmotionalSearch(topic);
  }

  static Future<void> _recordReflectedItem(LocalReflectedItem item) async {
    try {
      final recent = await recentReflections();
      // Recently reflected items can be either verse references or emotional
      // topics. The Home screen maps them back to Verse Reader or Search.
      final updated = [
        item,
        ...recent.where((existing) => existing.id != item.id),
      ].take(3);
      await _saveJsonList(
        recentReflectionsKey,
        updated.map((entry) => entry.toJson()),
      );
    } catch (error, stackTrace) {
      debugPrint('Recent reflection save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> recordDailyGuidanceOpened() async {
    // Opening Today's Guidance counts as a gentle reflection day. This is
    // intentionally low-pressure; there are no badges, reminders, or penalties.
    await recordReflectionActivity();
  }

  static Future<void> recordVerseReadForReflection() async {
    await recordReflectionActivity();
  }

  static Future<void> recordJournalReflection() async {
    await recordReflectionActivity();
  }

  static Future<void> recordPracticeCompleted() async {
    await recordReflectionActivity();
  }

  static Future<void> recordReflectionActivity() async {
    await _recordReflectionDate(DateTime.now());
  }

  static Future<int> reflectionStreak() async {
    try {
      // Count consecutive local dates backwards from today. This avoids
      // timezone-sensitive timestamp comparisons for the gentle streak display.
      final dates = await _completedPracticeDates();
      if (dates.isEmpty) {
        return 0;
      }
      var cursor = _dateKey(DateTime.now());
      var streak = 0;
      while (dates.contains(cursor)) {
        streak += 1;
        final date = DateTime.parse(cursor);
        cursor = _dateKey(date.subtract(const Duration(days: 1)));
      }
      return streak;
    } catch (error, stackTrace) {
      debugPrint('Reflection streak load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return 0;
    }
  }

  static Future<Set<String>> _completedPracticeDates() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(completedPracticeDatesKey) ?? const []).toSet();
  }

  static Future<void> _recordReflectionDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dates = await _completedPracticeDates();
      dates.add(_dateKey(date));
      await prefs.setStringList(
        completedPracticeDatesKey,
        dates.toList()..sort(),
      );
    } catch (error, stackTrace) {
      debugPrint('Reflection streak save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<List<AskGitaHistoryEntry>> askGitaHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(askHistoryKey);
      if (raw == null || raw.isEmpty) {
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AskGitaHistoryEntry.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (error, stackTrace) {
      debugPrint('Ask Gita local history load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(savedVersesKey);
    await prefs.remove(savedReflectionsKey);
    await prefs.remove(highlightedVersesKey);
    await prefs.remove(journalEntriesKey);
    await prefs.remove(askHistoryKey);
    await prefs.remove(recentVersesKey);
    await prefs.remove(journeyProgressKey);
    await prefs.remove(completedJourneysKey);
    await prefs.remove(readerFontScaleKey);
    await prefs.remove(readerShowSanskritKey);
    await prefs.remove(readerShowTransliterationKey);
    await prefs.remove(completedPracticeDatesKey);
    await prefs.remove(recentReflectionsKey);
    await prefs.remove(themeModeKey);
    await PersonalizationService.clearLocalPersonalization();
    debugPrint('Journey progress saved: cleared');
    journeyProgressRevision.value += 1;
  }

  static Future<double> readerFontScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(readerFontScaleKey) ?? 1;
      return value.clamp(0.86, 1.28);
    } catch (error, stackTrace) {
      debugPrint('Reader font scale load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return 1;
    }
  }

  static Future<void> setReaderFontScale(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(readerFontScaleKey, value.clamp(0.86, 1.28));
    } catch (error, stackTrace) {
      debugPrint('Reader font scale save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<bool> readerShowSanskrit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(readerShowSanskritKey) ?? true;
    } catch (error, stackTrace) {
      debugPrint('Reader Sanskrit visibility load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return true;
    }
  }

  static Future<void> setReaderShowSanskrit(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(readerShowSanskritKey, value);
    } catch (error, stackTrace) {
      debugPrint('Reader Sanskrit visibility save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<bool> readerShowTransliteration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(readerShowTransliterationKey) ?? true;
    } catch (error, stackTrace) {
      debugPrint('Reader transliteration visibility load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return true;
    }
  }

  static Future<void> setReaderShowTransliteration(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(readerShowTransliterationKey, value);
    } catch (error, stackTrace) {
      debugPrint('Reader transliteration visibility save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<String> themeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(themeModeKey) ?? 'golden_flute_lotus';
    } catch (error, stackTrace) {
      debugPrint('Theme setting load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return 'golden_flute_lotus';
    }
  }

  static Future<void> setThemeMode(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeModeKey, value);
    } catch (error, stackTrace) {
      debugPrint('Theme setting save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<Map<String, Set<int>>> journeyProgress() async {
    // Journey progress:
    // Each map entry is journeyId -> completed day numbers. The key name still
    // contains "reading_plan" for backwards compatibility with existing
    // installs, but every code path now treats this data as Journeys.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(journeyProgressKey);
      if (raw == null || raw.isEmpty) {
        debugPrint('Journey progress loaded: empty');
        return <String, Set<int>>{};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('Journey progress loaded: invalid payload');
        return <String, Set<int>>{};
      }
      final progress = decoded.map((key, value) {
        final days = value is List
            ? value.map(_readInt).where((day) => day > 0).toSet()
            : <int>{};
        return MapEntry(key, days);
      });
      debugPrint(
        'Journey progress loaded: '
        '${progress.map((key, value) => MapEntry(key, value.toList()..sort()))}',
      );
      return progress;
    } catch (error, stackTrace) {
      debugPrint('Journey progress load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <String, Set<int>>{};
    }
  }

  static Future<Set<int>> completedJourneyDays(String journeyId) async {
    final progress = await journeyProgress();
    return progress[journeyId] ?? <int>{};
  }

  static Future<Set<String>> completedJourneyIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = (prefs.getStringList(completedJourneysKey) ?? const [])
          .where((id) => id.trim().isNotEmpty)
          .toSet();
      debugPrint('Completed journeys loaded: ${ids.toList()..sort()}');
      return ids;
    } catch (error, stackTrace) {
      debugPrint('Completed journeys load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return <String>{};
    }
  }

  static Future<String?> currentJourneyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(currentJourneyKey)?.trim();
      debugPrint(
          'Current journey loaded: ${id?.isEmpty ?? true ? 'none' : id}');
      return id == null || id.isEmpty ? null : id;
    } catch (error, stackTrace) {
      debugPrint('Current journey load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> setCurrentJourneyId(String journeyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(currentJourneyKey, journeyId);
      debugPrint('Current journey saved: $journeyId');
      journeyProgressRevision.value += 1;
    } catch (error, stackTrace) {
      debugPrint('Current journey save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<int> currentJourneyDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final day = prefs.getInt(currentJourneyDayKey) ?? 1;
      return day < 1 ? 1 : day;
    } catch (error, stackTrace) {
      debugPrint('Current journey day load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return 1;
    }
  }

  static Future<void> setCurrentJourneyDay({
    required String journeyId,
    required int day,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(currentJourneyKey, journeyId);
      await prefs.setInt(currentJourneyDayKey, day < 1 ? 1 : day);
      debugPrint('Current journey saved: $journeyId');
      debugPrint('Current journey day saved: ${day < 1 ? 1 : day}');
      journeyProgressRevision.value += 1;
    } catch (error, stackTrace) {
      debugPrint('Current journey day save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> startJourney(String journeyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await journeyProgress();
      progress.remove(journeyId);
      final json = progress.map(
        (key, value) => MapEntry(key, value.toList()..sort()),
      );
      await prefs.setString(journeyProgressKey, jsonEncode(json));
      await prefs.setString(currentJourneyKey, journeyId);
      await prefs.setInt(currentJourneyDayKey, 1);
      debugPrint('Current journey saved: $journeyId');
      debugPrint('Current journey day saved: 1');
      debugPrint('Journey progress reset for: $journeyId');
      journeyProgressRevision.value += 1;
    } catch (error, stackTrace) {
      debugPrint('Journey start save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> markJourneyCompleted(String journeyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = await completedJourneyIds();
      ids.add(journeyId);
      final sortedIds = ids.toList()..sort();
      await prefs.setStringList(completedJourneysKey, sortedIds);
      debugPrint('Journey completion saved: $journeyId');
      journeyProgressRevision.value += 1;
    } catch (error, stackTrace) {
      debugPrint('Journey completion save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> setJourneyDayComplete({
    required String journeyId,
    required int day,
    required bool complete,
    int? totalDays,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await journeyProgress();
      final completedDays = {...(progress[journeyId] ?? <int>{})};
      if (complete) {
        completedDays.add(day);
      } else {
        completedDays.remove(day);
      }
      progress[journeyId] = completedDays;
      final json = progress.map(
        (key, value) => MapEntry(key, value.toList()..sort()),
      );
      await prefs.setString(journeyProgressKey, jsonEncode(json));
      debugPrint('Journey progress saved: $json');
      if (totalDays != null) {
        final completedIds = await completedJourneyIds();
        if (complete && completedDays.length >= totalDays) {
          completedIds.add(journeyId);
          debugPrint('Journey completion saved: $journeyId');
          await PersonalizationService.recordJourneyCompleted(journeyId);
        } else {
          completedIds.remove(journeyId);
          debugPrint('Journey completion saved: removed $journeyId');
        }
        final sortedIds = completedIds.toList()..sort();
        await prefs.setStringList(completedJourneysKey, sortedIds);
      }
      journeyProgressRevision.value += 1;
    } catch (error, stackTrace) {
      debugPrint('Journey progress save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> _saveJsonList(
    String key,
    Iterable<Map<String, dynamic>> values,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(values.toList()));
    } catch (error, stackTrace) {
      debugPrint('Local storage save failed for $key: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 1;
}

DateTime _readDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

String _dateKey(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  return normalized.toIso8601String().split('T').first;
}
