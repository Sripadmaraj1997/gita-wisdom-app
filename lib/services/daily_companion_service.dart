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
}

class DailyCompanionService {
  const DailyCompanionService._();

  static const guidanceItems = [
    DailyGuidance(
      verseId: '2.47',
      chapterNumber: 2,
      reference: 'Bhagavad Gita 2.47',
      reflection:
          'Peace grows when you give sincere effort without trying to control every result.',
      practiceToday:
          'Take one meaningful action today without checking for outcome.',
      journalPrompt: 'What outcome are you attached to today?',
      topic: 'attachment',
    ),
    DailyGuidance(
      verseId: '2.14',
      chapterNumber: 2,
      reference: 'Bhagavad Gita 2.14',
      reflection:
          'Difficult feelings rise and pass. You do not have to become every feeling that visits you.',
      practiceToday: 'Pause before reacting and let one feeling move through.',
      journalPrompt: 'What feeling can you allow without becoming it?',
      topic: 'peace',
    ),
    DailyGuidance(
      verseId: '3.8',
      chapterNumber: 3,
      reference: 'Bhagavad Gita 3.8',
      reflection:
          'A simple duty done with care can become a quiet path back to peace.',
      practiceToday: 'Give one responsibility fifteen minutes of full effort.',
      journalPrompt: 'What duty can you do with love today?',
      topic: 'discipline',
    ),
    DailyGuidance(
      verseId: '6.5',
      chapterNumber: 6,
      reference: 'Bhagavad Gita 6.5',
      reflection:
          'Your mind can become a friend when you guide it with patience instead of force.',
      practiceToday: 'Speak to yourself once today with patience and courage.',
      journalPrompt: 'Where can you become your own ally today?',
      topic: 'clarity',
    ),
    DailyGuidance(
      verseId: '12.13',
      chapterNumber: 12,
      reference: 'Bhagavad Gita 12.13',
      reflection:
          'Devotion becomes real in small moments of kindness, patience, and care.',
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
