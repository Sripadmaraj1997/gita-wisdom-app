// Content quality framework for Gita Wisdom.
//
// This is the editorial contract for practical verse notes. Scripture text
// still comes from the local Bhagavad Gita JSON; this framework supplies
// reviewed reflection, Practice Today, and topic-tag coverage for important
// verses so the app feels like a wise daily companion rather than a database.

enum EmotionalIntent {
  anxiety,
  fear,
  anger,
  grief,
  uncertainty,
  attachment,
  discipline,
  motivation,
  purpose,
  workStress,
  relationships,
  devotion,
  peace,
  selfMastery,
}

extension EmotionalIntentLabel on EmotionalIntent {
  String get label => switch (this) {
        EmotionalIntent.workStress => 'work stress',
        EmotionalIntent.selfMastery => 'self-mastery',
        _ => name,
      };
}

class TopicTags {
  const TopicTags(this.values);

  final List<String> values;
}

class PracticeToday {
  const PracticeToday({
    required this.text,
    required this.category,
  });

  final String text;
  final EmotionalIntent category;
}

class Reflection {
  const Reflection({
    required this.text,
    required this.intent,
  });

  final String text;
  final EmotionalIntent intent;
}

class VerseContentQuality {
  const VerseContentQuality({
    required this.verseId,
    required this.reflection,
    required this.practiceToday,
    required this.topicTags,
    this.gitaWisdomInterpretation = '',
  });

  final String verseId;
  final Reflection reflection;
  final PracticeToday practiceToday;
  final TopicTags topicTags;
  final String gitaWisdomInterpretation;

  int get chapterNumber => int.parse(verseId.split('.').first);
  int get verseNumber => int.parse(verseId.split('.').last);
}

class ContentQualityFramework {
  const ContentQualityFramework._();

  static const topImportantVerseIds = [
    '2.7',
    '2.11',
    '2.13',
    '2.14',
    '2.20',
    '2.22',
    '2.23',
    '2.27',
    '2.38',
    '2.40',
    '2.41',
    '2.47',
    '2.48',
    '2.50',
    '2.55',
    '2.56',
    '2.57',
    '2.58',
    '2.59',
    '2.60',
    '2.61',
    '2.62',
    '2.63',
    '2.64',
    '2.65',
    '2.66',
    '2.67',
    '2.70',
    '2.71',
    '2.72',
    '3.5',
    '3.8',
    '3.9',
    '3.19',
    '3.20',
    '3.21',
    '3.25',
    '3.27',
    '3.30',
    '3.35',
    '3.37',
    '3.43',
    '4.7',
    '4.8',
    '4.10',
    '4.13',
    '4.18',
    '4.24',
    '4.34',
    '4.36',
    '4.38',
    '4.39',
    '5.7',
    '5.10',
    '5.12',
    '5.18',
    '5.23',
    '5.29',
    '6.5',
    '6.6',
    '6.10',
    '6.16',
    '6.17',
    '6.19',
    '6.26',
    '6.35',
    '6.40',
    '6.47',
    '7.7',
    '7.14',
    '7.16',
    '7.19',
    '8.5',
    '8.7',
    '8.15',
    '9.22',
    '9.26',
    '9.27',
    '9.29',
    '9.34',
    '10.8',
    '10.10',
    '10.20',
    '10.41',
    '11.33',
    '11.55',
    '12.2',
    '12.6',
    '12.7',
    '12.13',
    '12.14',
    '12.15',
    '13.8',
    '13.23',
    '14.11',
    '14.22',
    '14.26',
    '15.15',
    '18.66',
    '18.78',
  ];

  static Map<String, VerseContentQuality> reviewedReflections() {
    return {
      for (var i = 0; i < _reviewedSeeds.length; i++)
        _reviewedSeeds[i].verseId: _contentFor(_reviewedSeeds[i], i),
    };
  }

  static VerseContentQuality? contentForVerse(String verseId) {
    final index = _reviewedSeeds.indexWhere((seed) => seed.verseId == verseId);
    if (index < 0) {
      return null;
    }
    return _contentFor(_reviewedSeeds[index], index);
  }

  static String? interpretationForVerse(String verseId) {
    final text = _curatedContent[verseId]?.gitaWisdomInterpretation.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static VerseContentQuality _contentFor(_ReviewedVerseSeed seed, int index) {
    final curated = _curatedContent[seed.verseId];
    if (curated != null) {
      return curated;
    }
    final reflections = _reflectionBank[seed.intent]!;
    final practices = _practiceBank[seed.intent]!;
    return VerseContentQuality(
      verseId: seed.verseId,
      reflection: Reflection(
        text: reflections[index % reflections.length],
        intent: seed.intent,
      ),
      practiceToday: PracticeToday(
        text: practices[index % practices.length],
        category: seed.intent,
      ),
      topicTags: TopicTags(_tagsFor(seed.intent)),
    );
  }

  static List<String> _tagsFor(EmotionalIntent intent) {
    return [
      intent.label,
      ...switch (intent) {
        EmotionalIntent.anxiety => ['peace', 'uncertainty', 'grounding'],
        EmotionalIntent.fear => ['courage', 'faith', 'steadiness'],
        EmotionalIntent.anger => ['self-mastery', 'patience', 'clarity'],
        EmotionalIntent.grief => ['loss', 'tenderness', 'hope'],
        EmotionalIntent.uncertainty => ['clarity', 'choice', 'trust'],
        EmotionalIntent.attachment => ['detachment', 'karma', 'outcomes'],
        EmotionalIntent.discipline => ['practice', 'habit', 'duty'],
        EmotionalIntent.motivation => ['effort', 'focus', 'beginning'],
        EmotionalIntent.purpose => ['dharma', 'service', 'meaning'],
        EmotionalIntent.workStress => ['work', 'duty', 'pressure'],
        EmotionalIntent.relationships => ['kindness', 'speech', 'compassion'],
        EmotionalIntent.devotion => ['bhakti', 'surrender', 'love'],
        EmotionalIntent.peace => ['calm', 'mind', 'balance'],
        EmotionalIntent.selfMastery => ['mind', 'restraint', 'awareness'],
      },
    ];
  }
}

class _ReviewedVerseSeed {
  const _ReviewedVerseSeed(this.verseId, this.intent);

  final String verseId;
  final EmotionalIntent intent;
}

const _reviewedSeeds = [
  _ReviewedVerseSeed('2.7', EmotionalIntent.uncertainty),
  _ReviewedVerseSeed('2.11', EmotionalIntent.grief),
  _ReviewedVerseSeed('2.13', EmotionalIntent.grief),
  _ReviewedVerseSeed('2.14', EmotionalIntent.peace),
  _ReviewedVerseSeed('2.20', EmotionalIntent.grief),
  _ReviewedVerseSeed('2.22', EmotionalIntent.grief),
  _ReviewedVerseSeed('2.23', EmotionalIntent.fear),
  _ReviewedVerseSeed('2.27', EmotionalIntent.grief),
  _ReviewedVerseSeed('2.38', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('2.40', EmotionalIntent.motivation),
  _ReviewedVerseSeed('2.41', EmotionalIntent.discipline),
  _ReviewedVerseSeed('2.47', EmotionalIntent.attachment),
  _ReviewedVerseSeed('2.48', EmotionalIntent.peace),
  _ReviewedVerseSeed('2.50', EmotionalIntent.workStress),
  _ReviewedVerseSeed('2.55', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('2.56', EmotionalIntent.anxiety),
  _ReviewedVerseSeed('2.57', EmotionalIntent.attachment),
  _ReviewedVerseSeed('2.58', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('2.59', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('2.60', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('2.61', EmotionalIntent.devotion),
  _ReviewedVerseSeed('2.62', EmotionalIntent.attachment),
  _ReviewedVerseSeed('2.63', EmotionalIntent.anger),
  _ReviewedVerseSeed('2.64', EmotionalIntent.peace),
  _ReviewedVerseSeed('2.65', EmotionalIntent.peace),
  _ReviewedVerseSeed('2.66', EmotionalIntent.peace),
  _ReviewedVerseSeed('2.67', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('2.70', EmotionalIntent.peace),
  _ReviewedVerseSeed('2.71', EmotionalIntent.attachment),
  _ReviewedVerseSeed('2.72', EmotionalIntent.peace),
  _ReviewedVerseSeed('3.5', EmotionalIntent.motivation),
  _ReviewedVerseSeed('3.8', EmotionalIntent.discipline),
  _ReviewedVerseSeed('3.9', EmotionalIntent.purpose),
  _ReviewedVerseSeed('3.19', EmotionalIntent.attachment),
  _ReviewedVerseSeed('3.20', EmotionalIntent.purpose),
  _ReviewedVerseSeed('3.21', EmotionalIntent.purpose),
  _ReviewedVerseSeed('3.25', EmotionalIntent.workStress),
  _ReviewedVerseSeed('3.27', EmotionalIntent.attachment),
  _ReviewedVerseSeed('3.30', EmotionalIntent.devotion),
  _ReviewedVerseSeed('3.35', EmotionalIntent.purpose),
  _ReviewedVerseSeed('3.37', EmotionalIntent.anger),
  _ReviewedVerseSeed('3.43', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('4.7', EmotionalIntent.devotion),
  _ReviewedVerseSeed('4.8', EmotionalIntent.fear),
  _ReviewedVerseSeed('4.10', EmotionalIntent.fear),
  _ReviewedVerseSeed('4.13', EmotionalIntent.purpose),
  _ReviewedVerseSeed('4.18', EmotionalIntent.workStress),
  _ReviewedVerseSeed('4.24', EmotionalIntent.devotion),
  _ReviewedVerseSeed('4.34', EmotionalIntent.uncertainty),
  _ReviewedVerseSeed('4.36', EmotionalIntent.grief),
  _ReviewedVerseSeed('4.38', EmotionalIntent.uncertainty),
  _ReviewedVerseSeed('4.39', EmotionalIntent.discipline),
  _ReviewedVerseSeed('5.7', EmotionalIntent.workStress),
  _ReviewedVerseSeed('5.10', EmotionalIntent.attachment),
  _ReviewedVerseSeed('5.12', EmotionalIntent.peace),
  _ReviewedVerseSeed('5.18', EmotionalIntent.relationships),
  _ReviewedVerseSeed('5.23', EmotionalIntent.anger),
  _ReviewedVerseSeed('5.29', EmotionalIntent.devotion),
  _ReviewedVerseSeed('6.5', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('6.6', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('6.10', EmotionalIntent.discipline),
  _ReviewedVerseSeed('6.16', EmotionalIntent.discipline),
  _ReviewedVerseSeed('6.17', EmotionalIntent.discipline),
  _ReviewedVerseSeed('6.19', EmotionalIntent.peace),
  _ReviewedVerseSeed('6.26', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('6.35', EmotionalIntent.discipline),
  _ReviewedVerseSeed('6.40', EmotionalIntent.fear),
  _ReviewedVerseSeed('6.47', EmotionalIntent.devotion),
  _ReviewedVerseSeed('7.7', EmotionalIntent.devotion),
  _ReviewedVerseSeed('7.14', EmotionalIntent.fear),
  _ReviewedVerseSeed('7.16', EmotionalIntent.devotion),
  _ReviewedVerseSeed('7.19', EmotionalIntent.devotion),
  _ReviewedVerseSeed('8.5', EmotionalIntent.devotion),
  _ReviewedVerseSeed('8.7', EmotionalIntent.workStress),
  _ReviewedVerseSeed('8.15', EmotionalIntent.grief),
  _ReviewedVerseSeed('9.22', EmotionalIntent.anxiety),
  _ReviewedVerseSeed('9.26', EmotionalIntent.devotion),
  _ReviewedVerseSeed('9.27', EmotionalIntent.workStress),
  _ReviewedVerseSeed('9.29', EmotionalIntent.relationships),
  _ReviewedVerseSeed('9.34', EmotionalIntent.devotion),
  _ReviewedVerseSeed('10.8', EmotionalIntent.devotion),
  _ReviewedVerseSeed('10.10', EmotionalIntent.uncertainty),
  _ReviewedVerseSeed('10.20', EmotionalIntent.peace),
  _ReviewedVerseSeed('10.41', EmotionalIntent.devotion),
  _ReviewedVerseSeed('11.33', EmotionalIntent.workStress),
  _ReviewedVerseSeed('11.55', EmotionalIntent.devotion),
  _ReviewedVerseSeed('12.2', EmotionalIntent.devotion),
  _ReviewedVerseSeed('12.6', EmotionalIntent.anxiety),
  _ReviewedVerseSeed('12.7', EmotionalIntent.fear),
  _ReviewedVerseSeed('12.13', EmotionalIntent.relationships),
  _ReviewedVerseSeed('12.14', EmotionalIntent.devotion),
  _ReviewedVerseSeed('12.15', EmotionalIntent.relationships),
  _ReviewedVerseSeed('13.8', EmotionalIntent.relationships),
  _ReviewedVerseSeed('13.23', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('14.11', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('14.22', EmotionalIntent.selfMastery),
  _ReviewedVerseSeed('14.26', EmotionalIntent.devotion),
  _ReviewedVerseSeed('15.15', EmotionalIntent.devotion),
  _ReviewedVerseSeed('18.66', EmotionalIntent.anxiety),
  _ReviewedVerseSeed('18.78', EmotionalIntent.devotion),
];

const _curatedContent = <String, VerseContentQuality>{
  '2.14': VerseContentQuality(
    verseId: '2.14',
    reflection: Reflection(
      text:
          'Discomfort feels permanent when the mind is caught inside it. Krishna points to a steadier way: notice that pleasure and pain both pass through awareness. Endurance becomes gentler when you stop treating every feeling as final.',
      intent: EmotionalIntent.peace,
    ),
    practiceToday: PracticeToday(
      text: 'When discomfort appears, pause before reacting.',
      category: EmotionalIntent.peace,
    ),
    topicTags: TopicTags([
      'peace',
      'patience',
      'resilience',
      'fear',
      'self-mastery',
      'clarity',
    ]),
    gitaWisdomInterpretation:
        'Pleasure, pain, praise, and difficulty are passing contacts with life. Meet them with patience instead of letting them decide your inner state.',
  ),
  '2.47': VerseContentQuality(
    verseId: '2.47',
    reflection: Reflection(
      text:
          'Much of our stress comes from trying to own the result before the work is complete. Krishna returns the heart to sincere effort, where dignity and freedom are still available. Peace grows when action is wholehearted and expectation softens.',
      intent: EmotionalIntent.attachment,
    ),
    practiceToday: PracticeToday(
      text: 'Focus on effort, not outcome.',
      category: EmotionalIntent.attachment,
    ),
    topicTags: TopicTags([
      'attachment',
      'detachment',
      'karma',
      'outcomes',
      'work',
      'discipline',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'Your part is sincere action. The fruit of action belongs to a wider order, so work fully without making the result your identity.',
  ),
  '2.50': VerseContentQuality(
    verseId: '2.50',
    reflection: Reflection(
      text:
          'Skill in action is not only efficiency; it is inner balance while acting. A steady person works carefully without being ruled by praise, panic, or regret. The work becomes cleaner when the mind is less tangled in reward.',
      intent: EmotionalIntent.workStress,
    ),
    practiceToday: PracticeToday(
      text: 'Complete one task with quiet steadiness.',
      category: EmotionalIntent.workStress,
    ),
    topicTags: TopicTags([
      'work stress',
      'karma',
      'discipline',
      'clarity',
      'balance',
      'purpose',
    ]),
    gitaWisdomInterpretation:
        'True skill is action joined with balance. When the mind is steady, work becomes clearer and less driven by anxiety or reward.',
  ),
  '2.56': VerseContentQuality(
    verseId: '2.56',
    reflection: Reflection(
      text:
          'Life will still bring sorrow, desire, and fear, but they do not have to command the whole mind. Krishna describes a steadiness that feels grounded rather than numb. Calm grows when emotions are honored without being obeyed immediately.',
      intent: EmotionalIntent.anxiety,
    ),
    practiceToday: PracticeToday(
      text: 'Name one feeling without acting on it.',
      category: EmotionalIntent.anxiety,
    ),
    topicTags: TopicTags([
      'anxiety',
      'fear',
      'anger',
      'peace',
      'self-mastery',
      'clarity',
    ]),
    gitaWisdomInterpretation:
        'The steady person remains inwardly anchored through sorrow, desire, fear, and anger. This steadiness is not coldness; it is freedom from being ruled by every wave.',
  ),
  '2.70': VerseContentQuality(
    verseId: '2.70',
    reflection: Reflection(
      text:
          'Desires may keep arriving, but peace depends on how much space they occupy within you. The ocean receives many rivers without losing its depth. A quiet heart can meet wants without becoming owned by them.',
      intent: EmotionalIntent.peace,
    ),
    practiceToday: PracticeToday(
      text: 'Let one desire pass without feeding it.',
      category: EmotionalIntent.peace,
    ),
    topicTags: TopicTags([
      'peace',
      'desire',
      'attachment',
      'self-mastery',
      'clarity',
    ]),
    gitaWisdomInterpretation:
        'Desires may continue to arise, but they need not disturb the depth of the heart. Peace comes when longing no longer commands the whole self.',
  ),
  '3.19': VerseContentQuality(
    verseId: '3.19',
    reflection: Reflection(
      text:
          'Duty becomes lighter when it is not mixed with constant bargaining. Krishna asks for action done because it is right, not because it guarantees comfort or approval. Freedom begins when responsibility is offered cleanly.',
      intent: EmotionalIntent.attachment,
    ),
    practiceToday: PracticeToday(
      text: 'Do one duty without seeking approval.',
      category: EmotionalIntent.attachment,
    ),
    topicTags: TopicTags([
      'attachment',
      'karma',
      'duty',
      'discipline',
      'work',
      'purpose',
    ]),
    gitaWisdomInterpretation:
        'Do what ought to be done without clinging to reward. Detached action is not indifference; it is clean responsibility.',
  ),
  '3.30': VerseContentQuality(
    verseId: '3.30',
    reflection: Reflection(
      text:
          'Some burdens become heavy because the ego tries to carry them alone. Offering action to the Divine does not remove responsibility; it purifies the heart behind it. Work becomes calmer when it is joined with trust.',
      intent: EmotionalIntent.devotion,
    ),
    practiceToday: PracticeToday(
      text: 'Offer one difficult task inwardly.',
      category: EmotionalIntent.devotion,
    ),
    topicTags: TopicTags([
      'devotion',
      'surrender',
      'karma',
      'work stress',
      'purpose',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'Offer action, ego, and anxiety to the Divine. The work still matters, but the burden of ownership begins to soften.',
  ),
  '4.7': VerseContentQuality(
    verseId: '4.7',
    reflection: Reflection(
      text:
          'When disorder grows, the heart can begin to feel abandoned. Krishna speaks of Divine presence entering the world when dharma needs protection. Faith becomes steadier when you remember that goodness is not left unsupported.',
      intent: EmotionalIntent.devotion,
    ),
    practiceToday: PracticeToday(
      text: 'Notice one sign of goodness today.',
      category: EmotionalIntent.devotion,
    ),
    topicTags: TopicTags([
      'devotion',
      'faith',
      'purpose',
      'fear',
      'hope',
      'dharma',
    ]),
    gitaWisdomInterpretation:
        'Whenever dharma declines, Divine presence moves to restore balance. The verse gives courage that truth and goodness are not abandoned.',
  ),
  '4.8': VerseContentQuality(
    verseId: '4.8',
    reflection: Reflection(
      text:
          'Protection of dharma is not abstract; it matters in the choices people make each day. Krishna\'s promise gives courage when harmful forces seem louder than truth. Aligning with what is right is already participation in that protection.',
      intent: EmotionalIntent.fear,
    ),
    practiceToday: PracticeToday(
      text: 'Choose the truthful action today.',
      category: EmotionalIntent.fear,
    ),
    topicTags: TopicTags([
      'fear',
      'courage',
      'devotion',
      'dharma',
      'purpose',
      'clarity',
    ]),
    gitaWisdomInterpretation:
        'The Divine protects what is noble and corrects what destroys harmony. Human courage grows by standing with dharma in daily choices.',
  ),
  '4.38': VerseContentQuality(
    verseId: '4.38',
    reflection: Reflection(
      text:
          'Confusion often makes the mind restless for quick answers. Krishna honors knowledge as a purifier because true understanding changes how we carry life. Clarity matures through humility, practice, and time.',
      intent: EmotionalIntent.uncertainty,
    ),
    practiceToday: PracticeToday(
      text: 'Ask one honest question before deciding.',
      category: EmotionalIntent.uncertainty,
    ),
    topicTags: TopicTags([
      'uncertainty',
      'clarity',
      'wisdom',
      'discipline',
      'purpose',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'Knowledge purifies because it changes how the world is seen and carried. With time and sincere practice, confusion becomes clearer.',
  ),
  '5.10': VerseContentQuality(
    verseId: '5.10',
    reflection: Reflection(
      text:
          'Action does not have to stain the heart when it is offered without clinging. Krishna gives the image of a lotus leaf untouched by water. You can remain inwardly clean while living fully in responsibility.',
      intent: EmotionalIntent.attachment,
    ),
    practiceToday: PracticeToday(
      text: 'Offer your effort, then let it rest.',
      category: EmotionalIntent.attachment,
    ),
    topicTags: TopicTags([
      'attachment',
      'detachment',
      'karma',
      'work',
      'peace',
      'devotion',
    ]),
    gitaWisdomInterpretation:
        'One who acts without attachment remains inwardly untouched, like a lotus leaf in water. Life can be active while the heart stays free.',
  ),
  '6.5': VerseContentQuality(
    verseId: '6.5',
    reflection: Reflection(
      text:
          'The mind can pull a person downward, but it can also become a faithful helper. Krishna places real dignity in inner effort. Speak to yourself like someone you are responsible for guiding, not punishing.',
      intent: EmotionalIntent.selfMastery,
    ),
    practiceToday: PracticeToday(
      text: 'Speak to yourself once with patience.',
      category: EmotionalIntent.selfMastery,
    ),
    topicTags: TopicTags([
      'self-mastery',
      'mind',
      'discipline',
      'motivation',
      'clarity',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'Lift yourself through your own mind rather than letting it pull you down. The mind becomes a friend when it is trained with patience and truth.',
  ),
  '6.6': VerseContentQuality(
    verseId: '6.6',
    reflection: Reflection(
      text:
          'An undisciplined mind can feel like an opponent living within you. Krishna does not condemn the mind; he shows that it can be trained into friendship. Every calm return is part of that training.',
      intent: EmotionalIntent.selfMastery,
    ),
    practiceToday: PracticeToday(
      text: 'Guide one thought back gently.',
      category: EmotionalIntent.selfMastery,
    ),
    topicTags: TopicTags([
      'self-mastery',
      'mind',
      'discipline',
      'anxiety',
      'clarity',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'The disciplined mind supports spiritual growth; the untrained mind creates inner conflict. Friendship with the mind is formed through repeated guidance.',
  ),
  '6.26': VerseContentQuality(
    verseId: '6.26',
    reflection: Reflection(
      text:
          'The wandering mind is not a personal failure; it is the field of practice. Krishna\'s instruction is gentle and exact: notice the drift, then return. Progress is built through returning, not through never being distracted.',
      intent: EmotionalIntent.selfMastery,
    ),
    practiceToday: PracticeToday(
      text: 'Return your attention without self-blame.',
      category: EmotionalIntent.selfMastery,
    ),
    topicTags: TopicTags([
      'self-mastery',
      'mind',
      'discipline',
      'focus',
      'anxiety',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'Each time the mind wanders, bring it back with steadiness. The practice is not perfect control, but faithful return.',
  ),
  '9.22': VerseContentQuality(
    verseId: '9.22',
    reflection: Reflection(
      text:
          'Worry often comes from feeling that everything depends on your own strength. Krishna offers a relationship of care to the one who turns steadily toward Him. Trust does not remove effort; it helps the heart stop carrying life alone.',
      intent: EmotionalIntent.anxiety,
    ),
    practiceToday: PracticeToday(
      text: 'Place one worry in prayer today.',
      category: EmotionalIntent.anxiety,
    ),
    topicTags: TopicTags([
      'anxiety',
      'devotion',
      'faith',
      'peace',
      'uncertainty',
      'surrender',
    ]),
    gitaWisdomInterpretation:
        'For one who remembers the Divine with steady devotion, care is not absent. Trust allows effort to continue without loneliness.',
  ),
  '9.26': VerseContentQuality(
    verseId: '9.26',
    reflection: Reflection(
      text:
          'Devotion is measured by sincerity, not by the size of the offering. A leaf, flower, fruit, or water becomes sacred when given with love. The heart becomes lighter when it stops performing and simply offers.',
      intent: EmotionalIntent.devotion,
    ),
    practiceToday: PracticeToday(
      text: 'Offer one simple act with love.',
      category: EmotionalIntent.devotion,
    ),
    topicTags: TopicTags([
      'devotion',
      'bhakti',
      'love',
      'humility',
      'peace',
      'purpose',
    ]),
    gitaWisdomInterpretation:
        'The smallest offering becomes sacred when given with love. Sincerity matters more than display.',
  ),
  '12.13': VerseContentQuality(
    verseId: '12.13',
    reflection: Reflection(
      text:
          'Spiritual maturity becomes visible in how we treat others. Krishna describes a heart free from hatred, softened by friendliness and compassion. Devotion is not separate from the way we speak, forgive, and make room for people.',
      intent: EmotionalIntent.relationships,
    ),
    practiceToday: PracticeToday(
      text: 'Choose gentleness in one conversation.',
      category: EmotionalIntent.relationships,
    ),
    topicTags: TopicTags([
      'relationships',
      'devotion',
      'compassion',
      'anger',
      'humility',
      'peace',
    ]),
    gitaWisdomInterpretation:
        'A devotee is known through compassion, humility, and freedom from hatred. Love of God becomes visible in conduct toward others.',
  ),
  '12.14': VerseContentQuality(
    verseId: '12.14',
    reflection: Reflection(
      text:
          'Contentment is not passive; it is a disciplined heart resting in trust. Krishna values steadiness, self-control, and devotion joined together. A peaceful life is shaped by repeated inner alignment, not by perfect circumstances.',
      intent: EmotionalIntent.devotion,
    ),
    practiceToday: PracticeToday(
      text: 'Begin one task with quiet remembrance.',
      category: EmotionalIntent.devotion,
    ),
    topicTags: TopicTags([
      'devotion',
      'discipline',
      'peace',
      'contentment',
      'self-mastery',
      'clarity',
    ]),
    gitaWisdomInterpretation:
        'The beloved devotee is steady, content, disciplined, and surrendered in heart. Devotion shapes both inner life and daily conduct.',
  ),
  '12.15': VerseContentQuality(
    verseId: '12.15',
    reflection: Reflection(
      text:
          'A steady person does not become a source of agitation for others, and is not easily shaken by the world. Krishna points to a tenderness with strength inside it. Calm conduct can protect both your peace and the peace around you.',
      intent: EmotionalIntent.relationships,
    ),
    practiceToday: PracticeToday(
      text: 'Let one reply be calm and kind.',
      category: EmotionalIntent.relationships,
    ),
    topicTags: TopicTags([
      'relationships',
      'peace',
      'anger',
      'self-mastery',
      'compassion',
      'clarity',
    ]),
    gitaWisdomInterpretation:
        'A peaceful devotee neither disturbs the world nor is easily disturbed by it. Strength and gentleness meet in such a heart.',
  ),
  '18.66': VerseContentQuality(
    verseId: '18.66',
    reflection: Reflection(
      text:
          'There are moments when the mind is exhausted from trying to manage every path alone. Krishna\'s invitation is surrender rooted in trust, not escape from responsibility. Let the heart return to the Divine and take the next step from there.',
      intent: EmotionalIntent.anxiety,
    ),
    practiceToday: PracticeToday(
      text: 'Surrender one burden in prayer.',
      category: EmotionalIntent.anxiety,
    ),
    topicTags: TopicTags([
      'anxiety',
      'surrender',
      'devotion',
      'fear',
      'peace',
      'uncertainty',
    ]),
    gitaWisdomInterpretation:
        'Surrender means returning the whole burden to the Divine with trust. It is not avoidance, but the deepest refuge from fear and confusion.',
  ),
};

const _reflectionBank = {
  EmotionalIntent.anxiety: [
    'Anxiety often tries to solve too much at once. Trust returns when attention comes back to the next sincere action. Peace grows when the heart stops carrying every outcome alone.',
    'Worry can make the future feel heavier than the present. A steadier way becomes possible when trust returns to the next sincere action. Do what is yours today and let the rest soften.',
    'A restless mind asks for certainty before it will breathe. A calmer path begins with care, action, and a softer grip. One grounded step can restore clarity.',
  ],
  EmotionalIntent.fear: [
    'Fear often makes the result feel larger than the action. Courage grows through duty, trust, and one clear step. You can move carefully without letting fear define you.',
    'Failure feels frightening when it becomes a measure of self-worth. Your value is deeper than the outcome. Courage begins as one honest action.',
    'Fear narrows the mind and makes retreat feel safe. A wider view gives faith room to steady the body. Take the next step without letting fear name you.',
  ],
  EmotionalIntent.anger: [
    'Anger often begins as pain, pressure, or a blocked expectation. A pause keeps the mind from becoming clouded. Clarity returns when reaction loosens its grip.',
    'Strong emotion can make harsh words feel justified. Restraint does not deny the feeling; it protects the response. Let the feeling settle before choosing your words.',
    'Anger can protect something tender, but it can also burn what matters. Space between impulse and action lets wisdom return. Use the pause before choosing your response.',
  ],
  EmotionalIntent.grief: [
    'Loss can make the heart feel unsteady and alone. A wider view can hold pain without rushing it away. Grief can be held gently, one breath at a time.',
    'Sorrow changes how the world feels for a while. The heart does not have to become hard to survive loss. Let love and pain be held with steadiness.',
    'Pain often asks for tenderness more than answers. Change is real, but the deepest self is not reduced by loss. Move slowly and honestly today.',
  ],
  EmotionalIntent.uncertainty: [
    'Uncertainty can make every choice feel too large. Discernment begins with the duty nearest at hand. Clarity often appears after one sincere step.',
    'When the whole path is unclear, the next right action still matters. Thoughtful movement is often wiser than anxious waiting. Let today be simple enough to begin.',
    'Confusion grows when the mind demands the full map. Humility, listening, and steady choice make the next step visible. You do not need perfect certainty to act well.',
  ],
  EmotionalIntent.attachment: [
    'Much of our stress comes from trying to control outcomes. Sincere effort brings attention back to what can be done today. Peace often returns when the heart stops bargaining with results.',
    'Attachment makes the result feel like a verdict on the self. Action becomes cleaner when it is not tied to grasping. Let the work be complete in its offering.',
    'Expectations can quietly tighten the heart. Full effort does not need inner bargaining. Freedom begins when effort is honest and grasping softens.',
  ],
  EmotionalIntent.discipline: [
    'Discipline often fails when it becomes harsh. Steady practice, balance, and return are more durable than self-pressure. A small action repeated with care can change the direction of the mind.',
    'The mind may resist what is good for it. Patient structure works better than self-criticism. Begin again with one manageable practice.',
    'A scattered day becomes clearer when one duty is honored. Discipline can become devotion in motion. Do the next necessary thing with steadiness.',
  ],
  EmotionalIntent.motivation: [
    'Motivation comes and goes, but duty can still guide the day. Action can begin before the mood feels perfect. Energy often returns after a sincere beginning.',
    'Feeling stuck does not mean you have failed. One small movement made with honesty can change the day. Momentum is built through action, not waiting.',
    'The mind often asks to feel ready before it begins. A kinder discipline starts smaller and stays honest. Let effort warm the heart.',
  ],
  EmotionalIntent.purpose: [
    'Purpose can feel distant when life is noisy. Meaning often returns through the duty close at hand. A faithful action can become a doorway to clarity.',
    'Comparing paths can make your own responsibility feel small. Sincerity in the work that belongs to you restores dignity. Purpose grows through service, not performance.',
    'A meaningful life is built from ordinary actions done with care. Attention can move from image to offering. Let today\'s duty become part of your path.',
  ],
  EmotionalIntent.workStress: [
    'Work becomes heavy when everything feels equally important. Sincere action and steadiness narrow the field. One clear priority can bring the mind back.',
    'Pressure can scatter attention and drain dignity from the task. Care returns when action becomes steady again. Do the work without letting panic lead.',
    'A busy day can pull the heart away from purpose. Work becomes lighter when it is treated as offering rather than burden. Give one task your full presence.',
  ],
  EmotionalIntent.relationships: [
    'Relationships test the quality of our inner state. Kindness, restraint, and truthful care keep the heart clean. Peace often begins with one softer response.',
    'Conflict can make the ego want to win quickly. Steadiness before speech protects what matters. Choose words that protect both truth and tenderness.',
    'The people near us often reveal where practice is unfinished. Devotion becomes real in ordinary conduct. Let compassion shape the next exchange.',
  ],
  EmotionalIntent.devotion: [
    'Devotion becomes real in ordinary choices. Offering, humility, and trust can enter even a simple act. A small action can carry love when done sincerely.',
    'Faith is not only a feeling during prayer. Devotion can enter work, speech, and attention. Let one action today be offered quietly.',
    'The heart softens when it remembers it is not alone. Surrender does not have to become passivity. Trust can live inside steady action.',
  ],
  EmotionalIntent.peace: [
    'Peace is often disturbed by chasing, resisting, and replaying. The mind becomes quieter when it is less reactive. Calm returns when we stop feeding every movement of thought.',
    'Inner quiet does not require life to be perfect. Balance can be practiced while circumstances keep changing. Let the mind settle before the next action.',
    'The senses and thoughts can pull attention in many directions. Awareness can return to the center without force. Peace begins when attention is guided gently.',
  ],
  EmotionalIntent.selfMastery: [
    'Self-mastery begins with noticing the mind without becoming every thought. Patient inner leadership gives the mind a better direction. The mind becomes a friend through steady guidance.',
    'Impulse can feel powerful in the moment. Restraint is freedom, not punishment. Pause long enough for wisdom to return.',
    'The inner life needs care, not force. Awareness, balance, and repeated return gradually train the mind. A calm mind is shaped one choice at a time.',
  ],
};

const _practiceBank = {
  EmotionalIntent.anxiety: [
    'Release one unnecessary worry today.',
    'Take one grounded step before planning more.',
    'Name what is in your control today.',
  ],
  EmotionalIntent.fear: [
    'Do one brave action quietly.',
    'Take the next step without measuring yourself.',
    'Breathe once before facing what you avoid.',
  ],
  EmotionalIntent.anger: [
    'Pause before responding today.',
    'Let one strong emotion settle first.',
    'Speak one sentence more softly.',
  ],
  EmotionalIntent.grief: [
    'Take one gentle breath before the next task.',
    'Let one feeling be present without rushing it.',
    'Do one kind thing for your heart.',
  ],
  EmotionalIntent.uncertainty: [
    'Choose one clear next step.',
    'Ask for guidance before deciding.',
    'Write the simplest truthful option.',
  ],
  EmotionalIntent.attachment: [
    'Complete one task without checking the result.',
    'Offer your effort, then let it rest.',
    'Release one outcome you cannot control.',
  ],
  EmotionalIntent.discipline: [
    'Do one focused task for 15 minutes.',
    'Begin again gently where you slipped.',
    'Finish one necessary task first.',
  ],
  EmotionalIntent.motivation: [
    'Start with five sincere minutes.',
    'Do one small action before waiting to feel ready.',
    'Return to one habit without self-blame.',
  ],
  EmotionalIntent.purpose: [
    'Complete one duty with full attention.',
    'Serve one person through your work today.',
    'Do the responsibility nearest to you.',
  ],
  EmotionalIntent.workStress: [
    'Finish one task before starting another.',
    'Choose one priority and protect it.',
    'Work for ten minutes without panic.',
  ],
  EmotionalIntent.relationships: [
    'Listen fully before responding.',
    'Choose gentleness in one conversation.',
    'Let one reply be truthful and kind.',
  ],
  EmotionalIntent.devotion: [
    'Offer one ordinary action quietly.',
    'Begin one task with remembrance.',
    'Make one small act an offering.',
  ],
  EmotionalIntent.peace: [
    'Sit quietly for three slow breaths.',
    'Do not feed one restless thought.',
    'Make one moment simpler today.',
  ],
  EmotionalIntent.selfMastery: [
    'Notice one impulse without obeying it.',
    'Guide one thought back gently.',
    'Pause before one automatic habit.',
  ],
};
