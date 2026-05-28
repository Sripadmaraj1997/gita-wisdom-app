// Daily companion content.
//
// Provides a small rotating set of local guidance entries used by Home and One
// Minute Wisdom. Keeping this data in one service avoids duplicating reflection
// copy across screens and makes future editorial expansion straightforward.
class DailyGuidance {
  const DailyGuidance({
    required this.verseId,
    required this.chapterNumber,
    required this.reference,
    required this.reflection,
    required this.practiceToday,
    required this.journalPrompt,
    required this.topic,
  });

  final String verseId;
  final int chapterNumber;
  final String reference;
  final String reflection;
  final String practiceToday;
  final String journalPrompt;
  final String topic;

  String get shareText => [
        reference,
        reflection,
        '',
        'Practice Today:',
        practiceToday,
        '',
        '-- Gita Wisdom',
      ].join('\n');
}

class DailyCompanionService {
  const DailyCompanionService._();

  static const guidanceItems = [
    DailyGuidance(
      verseId: '2.47',
      chapterNumber: 2,
      reference: 'Bhagavad Gita 2.47',
      reflection: 'Focus on sincere effort, not anxiety over results.',
      practiceToday:
          'Take one meaningful action today without checking for outcome.',
      journalPrompt: 'What outcome are you attached to today?',
      topic: 'attachment',
    ),
    DailyGuidance(
      verseId: '2.14',
      chapterNumber: 2,
      reference: 'Bhagavad Gita 2.14',
      reflection: 'Difficult feelings rise and pass. Your steadiness can grow.',
      practiceToday: 'Pause before reacting and let one feeling move through.',
      journalPrompt: 'What feeling can you allow without becoming it?',
      topic: 'peace',
    ),
    DailyGuidance(
      verseId: '3.8',
      chapterNumber: 3,
      reference: 'Bhagavad Gita 3.8',
      reflection: 'A clear duty done with care becomes a path to peace.',
      practiceToday: 'Give one responsibility fifteen minutes of full effort.',
      journalPrompt: 'What duty can you do with love today?',
      topic: 'discipline',
    ),
    DailyGuidance(
      verseId: '6.5',
      chapterNumber: 6,
      reference: 'Bhagavad Gita 6.5',
      reflection: 'Your own mind can become your helper through gentle effort.',
      practiceToday: 'Speak to yourself once today with patience and courage.',
      journalPrompt: 'Where can you become your own ally today?',
      topic: 'clarity',
    ),
    DailyGuidance(
      verseId: '12.13',
      chapterNumber: 12,
      reference: 'Bhagavad Gita 12.13',
      reflection: 'Devotion is expressed through kindness, patience, and care.',
      practiceToday: 'Offer one quiet act of kindness without needing credit.',
      journalPrompt: 'How can devotion become visible in your actions?',
      topic: 'devotion',
    ),
  ];

  static DailyGuidance todaysGuidance([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayKey = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year, 1, 1))
        .inDays;
    return guidanceItems[dayKey % guidanceItems.length];
  }
}
