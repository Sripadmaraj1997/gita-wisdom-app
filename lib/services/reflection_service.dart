// Reflection data service.
//
// Loads optional verse-level reflections and Practice Today prompts from
// assets/data/reflections.json. This service is deliberately separate from the
// main Gita dataset so editorial reflections can be updated independently.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VerseReflectionData {
  const VerseReflectionData({
    required this.chapterNumber,
    required this.verseNumber,
    required this.reflection,
    required this.practiceToday,
    required this.tags,
  });

  factory VerseReflectionData.fromJson(Map<String, dynamic> json) {
    return VerseReflectionData(
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

class ReflectionService {
  const ReflectionService._();

  static const assetPath = 'assets/data/reflections.json';
  static Future<List<VerseReflectionData>>? _reflectionsFuture;

  static Future<List<VerseReflectionData>> loadReflections() {
    // Cache parsed reflections to avoid re-reading the asset while swiping
    // through verses.
    return _reflectionsFuture ??= _loadFromAsset().catchError((Object error) {
      _reflectionsFuture = null;
      throw error;
    });
  }

  static Future<VerseReflectionData?> reflectionForVerse({
    required int chapterNumber,
    required int verseNumber,
  }) async {
    final reflections = await loadReflections();
    // Matching is by chapter + verse number, which is stable across dataset
    // formats even if JSON IDs are regenerated later.
    final match = reflections.where(
      (reflection) =>
          reflection.chapterNumber == chapterNumber &&
          reflection.verseNumber == verseNumber,
    );
    final found = match.isNotEmpty;
    if (kDebugMode) {
      debugPrint('ReflectionService: current chapterNumber $chapterNumber');
      debugPrint('ReflectionService: current verseNumber $verseNumber');
      debugPrint(
          'ReflectionService: reflections loaded count ${reflections.length}');
      debugPrint('ReflectionService: matched reflection found $found');
    }
    return found ? match.first : null;
  }

  static Future<List<VerseReflectionData>> _loadFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        debugPrint('ReflectionService: reflections.json root is not a list.');
        return const [];
      }
      final reflections = decoded
          .whereType<Map>()
          .map((item) =>
              VerseReflectionData.fromJson(Map<String, dynamic>.from(item)))
          .where((reflection) =>
              reflection.chapterNumber > 0 &&
              reflection.verseNumber > 0 &&
              (reflection.reflection.isNotEmpty ||
                  reflection.practiceToday.isNotEmpty))
          .toList(growable: false);
      if (kDebugMode) {
        debugPrint(
          'ReflectionService: reflections loaded count ${reflections.length}',
        );
      }
      return reflections;
    } catch (error, stackTrace) {
      debugPrint('ReflectionService: reflections.json load failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return const [];
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
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
