/// ------------------------------------------------------------
/// DailyCompanionService
///
/// Purpose:
/// Small local set of daily guidance entries for Home.
///
/// Responsibilities:
/// - Provide a date-rotated verse, reflection, Practice Today, and journal
///   prompt.
/// - Keep Today's Guidance consistent across Home and related companion flows.
/// - Avoid duplicated editorial copy in UI widgets.
///
/// Notes:
/// The daily companion is intentionally local and deterministic. It should feel
/// like a steady spiritual rhythm, not a notification-driven content feed.
///
/// TODO(wisdom-collections): Move this list to reviewed versioned JSON if it
/// grows into curated wisdom collections.
/// ------------------------------------------------------------
library;

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
          'Take one sincere action today without worrying about the result.',
      journalPrompt: 'What attachment can you soften today?',
      topic: 'attachment',
    ),
    DailyGuidance(
      verseId: '2.14',
      chapterNumber: 2,
      reference: 'Bhagavad Gita 2.14',
      reflection:
          'Difficult feelings rise and pass. You do not have to become every feeling that visits you.',
      practiceToday: 'Pause before reacting. Let one feeling move through.',
      journalPrompt: 'What disturbed your peace today?',
      topic: 'peace',
    ),
    DailyGuidance(
      verseId: '3.8',
      chapterNumber: 3,
      reference: 'Bhagavad Gita 3.8',
      reflection:
          'A simple duty done with care can become a quiet path back to peace.',
      practiceToday: 'Give one responsibility your full attention for a while.',
      journalPrompt: 'Where can you act with more steadiness?',
      topic: 'discipline',
    ),
    DailyGuidance(
      verseId: '6.5',
      chapterNumber: 6,
      reference: 'Bhagavad Gita 6.5',
      reflection:
          'Your mind can become a friend when you guide it with patience instead of force.',
      practiceToday: 'Speak to yourself once today with patience.',
      journalPrompt: 'What gave you clarity today?',
      topic: 'clarity',
    ),
    DailyGuidance(
      verseId: '12.13',
      chapterNumber: 12,
      reference: 'Bhagavad Gita 12.13',
      reflection:
          'Devotion becomes real in small moments of kindness, patience, and care.',
      practiceToday: 'Offer one quiet act of kindness without needing credit.',
      journalPrompt: 'Where can you bring more gentleness today?',
      topic: 'devotion',
    ),
  ];

  static DailyGuidance todaysGuidance([DateTime? date]) {
    // The date-based index gives users a fresh daily prompt without storing
    // server state. It is deterministic, so reopening the app on the same day
    // shows the same guidance.
    final now = date ?? DateTime.now();
    final dayKey = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year, 1, 1))
        .inDays;
    return guidanceItems[dayKey % guidanceItems.length];
  }
}
