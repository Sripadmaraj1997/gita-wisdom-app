// Local personalization preferences.
//
// Stores a small offline profile for older personalized-plan flows: what the
// user is seeking, language preference, and reminder time. Current Journeys do
// not require this setup; this service remains useful for future tailoring.
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gita_data.dart';

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

  static const _seekingKey = 'gita_wisdom_personalization_seeking';
  static const _languageKey = 'gita_wisdom_personalization_language';
  static const _reminderHourKey = 'gita_wisdom_personalization_reminder_hour';
  static const _reminderMinuteKey =
      'gita_wisdom_personalization_reminder_minute';

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
  }

  static Future<GitaVerseData> personalizedDailyVerse() async {
    final profile = await loadProfile();
    final results = await GitaRepository.search(_queryFor(profile.seeking));
    if (results.isNotEmpty) {
      return results.first.verse;
    }
    return GitaRepository.dailyVerse();
  }

  static Future<List<String>> personalizedAskSuggestions() async {
    final profile = await loadProfile();
    final seeking = profile.seeking.toLowerCase();
    final language = profile.language;
    return [
      'What does the Gita teach about $seeking?',
      'Give me one practice for $seeking today',
      'Which verse should I reflect on for $seeking?',
      if (language != 'English')
        'Explain $seeking simply for a $language-speaking reader',
      ..._suggestionsFor(profile.seeking),
    ].take(6).toList(growable: false);
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
    return switch (seeking.toLowerCase()) {
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
      _ => [
          'How can I steady my mind today?',
          'What does the Gita say about anxiety?',
        ],
    };
  }
}
