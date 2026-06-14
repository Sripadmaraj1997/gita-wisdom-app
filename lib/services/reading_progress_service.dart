/// ------------------------------------------------------------
/// ReadingProgressService
///
/// Purpose:
/// Fast local persistence for Home's Continue Reading card.
///
/// Responsibilities:
/// - Save the last opened verse ID, chapter, verse number, and timestamp.
/// - Restore the user's reading place without loading larger saved collections.
/// - Clear progress when local data is reset.
///
/// SharedPreferences keys:
/// - reading_progress_verse_id: exact verse ID, e.g. "2.47".
/// - reading_progress_chapter_number: chapter number for fallback display.
/// - reading_progress_verse_number: verse number for fallback display.
/// - reading_progress_saved_at: timestamp used only for local continuity.
///
/// Notes:
/// Continue Reading is intentionally separate from saved verses. Reading a verse
/// should update continuity without implying the user saved it.
/// ------------------------------------------------------------
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gita_data.dart';

class ReadingProgress {
  const ReadingProgress({
    required this.verseId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.savedAt,
  });

  final String verseId;
  final int chapterNumber;
  final int verseNumber;
  final DateTime savedAt;

  String get reference => 'Bhagavad Gita $chapterNumber.$verseNumber';
}

class ReadingProgressService {
  const ReadingProgressService._();

  static const _verseIdKey = 'reading_progress_verse_id';
  static const _chapterNumberKey = 'reading_progress_chapter_number';
  static const _verseNumberKey = 'reading_progress_verse_number';
  static const _savedAtKey = 'reading_progress_saved_at';

  static Future<void> saveVerse(GitaVerseData verse) async {
    try {
      // Write each field separately for simple migration and easy manual
      // debugging in shared_preferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_verseIdKey, verse.id);
      await prefs.setInt(_chapterNumberKey, verse.chapterNumber);
      await prefs.setInt(_verseNumberKey, verse.verseNumber);
      await prefs.setString(_savedAtKey, DateTime.now().toIso8601String());
      debugPrint('ReadingProgress saved ${verse.id}');
    } catch (error, stackTrace) {
      debugPrint('ReadingProgress save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<ReadingProgress?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verseId = prefs.getString(_verseIdKey);
      final chapterNumber = prefs.getInt(_chapterNumberKey);
      final verseNumber = prefs.getInt(_verseNumberKey);
      if (verseId == null || chapterNumber == null || verseNumber == null) {
        return null;
      }
      return ReadingProgress(
        verseId: verseId,
        chapterNumber: chapterNumber,
        verseNumber: verseNumber,
        savedAt: DateTime.tryParse(prefs.getString(_savedAtKey) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (error, stackTrace) {
      debugPrint('ReadingProgress load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_verseIdKey);
      await prefs.remove(_chapterNumberKey);
      await prefs.remove(_verseNumberKey);
      await prefs.remove(_savedAtKey);
    } catch (error, stackTrace) {
      debugPrint('ReadingProgress clear failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
