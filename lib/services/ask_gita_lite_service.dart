// Retrieval-based Ask Gita Lite service.
//
// Converts a user's question into a calm, six-part devotional answer using
// local topic profiles and the bundled Bhagavad Gita JSON. The service avoids
// OpenAI/API dependency in this MVP so answers remain deterministic, private,
// offline-capable, and grounded in verified local scripture translations.
//
// TODO(stronger-content-review): Expand these topic profiles through a formal
// editorial review pass before adding more sensitive guidance categories.
import '../data/gita_data.dart';
import 'content_quality_framework.dart';

class AskGitaLiteAnswer {
  // The UI renders these fields in order as the required six-part response:
  // Gentle Guidance, Relevant Verse, Meaning, Reflection, Practice Today,
  // and Source. Keeping the structure explicit avoids free-form chatbot copy.
  const AskGitaLiteAnswer({
    required this.topic,
    required this.gentleGuidance,
    required this.verse,
    required this.meaning,
    required this.reflection,
    required this.practiceToday,
  });

  final String topic;
  final String gentleGuidance;
  final GitaVerseData verse;
  final String meaning;
  final String reflection;
  final String practiceToday;

  String get source => verse.reference;
}

class AskGitaLiteService {
  const AskGitaLiteService._();

  static Future<AskGitaLiteAnswer> answer(String question) async {
    // Question matching:
    // The profile supplies human-written guidance, reflection, and practice
    // text. Verse text still comes from the local scripture dataset.
    final profile = _profileFor(question);
    final verse = await _bestVerse(profile, question);
    return AskGitaLiteAnswer(
      topic: profile.topic,
      gentleGuidance: _guidanceFor(profile, question),
      verse: verse,
      meaning: _interpretationFor(profile, verse),
      reflection: _reflectionFor(profile, verse),
      practiceToday: profile.practice,
    );
  }

  static Future<GitaVerseData> _bestVerse(
    _AskTopicProfile profile,
    String question,
  ) async {
    // Verse selection:
    // Prefer curated verse IDs for each topic. If the dataset is missing one,
    // fall back to local search, then to the daily verse so the UI never shows
    // an empty or generated placeholder.
    for (final id in profile.verseIds) {
      final verse = await GitaRepository.verseById(id);
      if (verse != null && verse.englishTranslation.trim().isNotEmpty) {
        return verse;
      }
    }

    final matches = await GitaRepository.search(
      '${profile.searchTerms} $question',
      limit: 5,
    );
    for (final match in matches) {
      if (match.verse.englishTranslation.trim().isNotEmpty) {
        return match.verse;
      }
    }

    return GitaRepository.verseByIdOrDaily(null);
  }

  static _AskTopicProfile _profileFor(String question) {
    final lower = question.toLowerCase();
    bool hasAny(List<String> terms) => terms.any(lower.contains);

    // Topic mapping intentionally uses transparent keyword groups instead of
    // opaque model classification. That keeps behavior easy to review and tune.
    if (hasAny(['anger', 'angry', 'rage', 'resent', 'irritat'])) {
      return _profiles['anger']!;
    }
    if (hasAny(
        ['work', 'job', 'deadline', 'pressure', 'burnout', 'overwhelmed'])) {
      return _profiles['work']!;
    }
    if (hasAny([
      'anxious',
      'anxiety',
      'worry',
      'worried',
      'worries',
      'worrying',
      'overthinking',
      'stress',
      'stressed',
    ])) {
      return _profiles['anxiety']!;
    }
    if (hasAny(['purpose', 'meaning of life', 'dharma', 'direction'])) {
      return _profiles['purpose']!;
    }
    if (hasAny([
      'future',
      'uncertain',
      'uncertainty',
      'unknown',
      'what if',
      'confused',
      'confusion',
      'decision',
    ])) {
      return _profiles['uncertainty']!;
    }
    if (hasAny(['failure', 'fail', 'afraid', 'fear', 'scared'])) {
      return _profiles['fear']!;
    }
    if (hasAny(['attached', 'attachment', 'results', 'outcome', 'let go'])) {
      return _profiles['attachment']!;
    }
    if (hasAny(['motivation', 'motivated', 'lazy', 'lost motivation'])) {
      return _profiles['motivation']!;
    }
    if (hasAny(['discipline', 'focus', 'habit', 'consistency'])) {
      return _profiles['discipline']!;
    }
    if (hasAny([
      'control my mind',
      'mind control',
      'restless mind',
      'wandering mind',
      'thoughts',
      'distracted',
      'distraction',
    ])) {
      return _profiles['mind']!;
    }
    if (hasAny(['devotion', 'devoted', 'bhakti', 'god', 'krishna'])) {
      return _profiles['devotion']!;
    }
    if (hasAny(['grief', 'loss', 'lost someone', 'sad', 'sorrow'])) {
      return _profiles['grief']!;
    }
    if (hasAny(['relationship', 'family', 'friend', 'partner', 'conflict'])) {
      return _profiles['relationships']!;
    }
    if (hasAny(['peace', 'calm', 'restless', 'mind'])) {
      return _profiles['peace']!;
    }
    return _profiles['fallback']!;
  }

  static String _guidanceFor(_AskTopicProfile profile, String question) {
    // Personal tone without AI generation:
    // A topic-specific opening sentence makes the answer feel addressed to the
    // concern, then the reviewed profile guidance carries the main counsel. If
    // local interpretation exists, that same verse is preferred below in the
    // interpretation section instead of generating a new explanation.
    final opening = _tailoredOpening(profile, question) ?? profile.opening;
    return '$opening ${profile.guidance}';
  }

  static String? _tailoredOpening(_AskTopicProfile profile, String question) {
    final lower = question.toLowerCase();
    final normalized = lower.trim().replaceAll(RegExp(r'[.!?]+$'), '');
    if (profile.topic == 'anxiety') {
      if (lower.contains('stop worrying')) {
        return 'Worry loses strength when it is met one clear moment at a time.';
      }
      if (normalized == 'i am anxious') {
        return 'Anxiety can make even this moment feel crowded.';
      }
      if (lower.contains('worried')) {
        return 'For this worry, give yourself permission to handle only the next step.';
      }
      if (lower.contains('future')) {
        return 'Your future does not need to be solved all at once.';
      }
    }
    if (profile.topic == 'purpose' && lower.contains('confused')) {
      return 'Confusion about purpose does not mean you are off the path.';
    }
    if (profile.topic == 'anger' && lower.contains('angry')) {
      return 'Anger can feel powerful, but power is not the same as truth.';
    }
    if (profile.topic == 'fear' && lower.contains('failure')) {
      return 'Fear of failure is heavy because it ties your worth to one result.';
    }
    if (profile.topic == 'grief') {
      return 'Grief needs room to breathe before it can become bearable.';
    }
    if (profile.topic == 'relationships') {
      return 'In a difficult relationship, steadiness can protect both truth and tenderness.';
    }
    if (profile.topic == 'work pressure' &&
        (lower.contains('overwhelmed') || lower.contains('pressure'))) {
      return 'When work feels too large, return to the one responsibility directly in front of you.';
    }
    if (profile.topic == 'attachment' && lower.contains('results')) {
      return 'Wanting a good result is natural; suffering begins when the result owns your peace.';
    }
    if (profile.topic == 'discipline' && lower.contains('consistency')) {
      return 'Consistency grows from small promises kept without harshness.';
    }
    if (profile.topic == 'devotion') {
      return 'Devotion can be practiced quietly before it is felt deeply.';
    }
    return null;
  }

  static String _interpretationFor(
    _AskTopicProfile profile,
    GitaVerseData verse,
  ) {
    final interpretation = verse.gitaWisdomInterpretation.trim();
    if (interpretation.isEmpty) {
      return profile.meaning;
    }
    return _firstReadablePortion(interpretation);
  }

  static String _reflectionFor(
    _AskTopicProfile profile,
    GitaVerseData _,
  ) {
    // Reflection remains human-written and topic-specific. The selected
    // verse's Gita Wisdom Interpretation strengthens the answer through the
    // separate interpretation section, so reflection does not paraphrase or
    // duplicate local scripture-adjacent content.
    return profile.reflection;
  }

  static String _firstReadablePortion(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 520) {
      return normalized;
    }
    final sentenceEnds = RegExp(r'[.!?]').allMatches(normalized).take(3);
    RegExpMatch? sentenceEnd;
    for (final match in sentenceEnds) {
      sentenceEnd = match;
    }
    if (sentenceEnd != null && sentenceEnd.end >= 180) {
      return normalized.substring(0, sentenceEnd.end).trim();
    }
    return '${normalized.substring(0, 520).trim()}...';
  }
}

class _AskTopicProfile {
  const _AskTopicProfile({
    required this.topic,
    required this.intent,
    required this.verseIds,
    required this.searchTerms,
    required this.opening,
    required this.guidance,
    required this.meaning,
    required this.reflection,
    required this.practice,
  });

  final String topic;
  final EmotionalIntent intent;
  final List<String> verseIds;
  final String searchTerms;
  final String opening;
  final String guidance;
  final String meaning;
  final String reflection;
  final String practice;
}

const _profiles = <String, _AskTopicProfile>{
  'anxiety': _AskTopicProfile(
    topic: 'anxiety',
    intent: EmotionalIntent.anxiety,
    verseIds: ['2.47', '2.48', '2.14'],
    searchTerms: 'anxiety worry future action outcome steadiness peace',
    opening:
        'For this worry, give yourself permission to handle only the next step.',
    guidance:
        'You do not need to solve your whole future today. Bring your attention back to the next honest action. Anxiety softens when the mind stops trying to carry every possible outcome at once.',
    meaning:
        'Your responsibility is sincere effort. The result matters, but it is not fully in your hands.',
    reflection:
        'A worried mind often asks for certainty before it will rest. Careful action gives the heart something honest to stand on. Let the grip soften after you have done your part.',
    practice: 'Release one unnecessary worry today.',
  ),
  'uncertainty': _AskTopicProfile(
    topic: 'uncertainty',
    intent: EmotionalIntent.uncertainty,
    verseIds: ['2.47', '18.63', '2.48'],
    searchTerms: 'uncertainty future choice action wisdom outcome',
    opening: 'You are allowed to move without seeing the whole road.',
    guidance:
        'Uncertainty does not mean you are lost. It means the next step matters more than the whole map. Choose the clearest duty in front of you and do it with steadiness.',
    meaning:
        'Clarity grows through thoughtful action. You are not asked to control every condition before beginning.',
    reflection:
        'When the future is unclear, the present becomes sacred ground. One careful step is enough for today.',
    practice: 'Take one clear next step.',
  ),
  'fear': _AskTopicProfile(
    topic: 'fear',
    intent: EmotionalIntent.fear,
    verseIds: ['2.47', '2.48', '18.66'],
    searchTerms: 'fear failure courage action surrender steadiness',
    opening:
        'Fear is asking for safety; meet it without handing it your worth.',
    guidance:
        'Fear of failure makes the result feel larger than the action. Do what is yours with care, without making your worth depend on the outcome. Courage can be quiet and still be real.',
    meaning:
        'Act with steadiness and let success or failure lose some of its power over your peace.',
    reflection:
        'Failure is painful, but fear often hurts before anything has happened. Return to effort, learning, and humility.',
    practice: 'Focus on effort, not outcome.',
  ),
  'anger': _AskTopicProfile(
    topic: 'anger',
    intent: EmotionalIntent.anger,
    verseIds: ['2.63', '2.14', '6.5'],
    searchTerms: 'anger desire frustration mind control patience',
    opening:
        'Your anger deserves attention, but it does not need to choose your words.',
    guidance:
        'Before responding, allow the emotion to settle. A reaction may feel necessary in the moment, but clarity grows in the pause. Protect your peace before you choose your words.',
    meaning:
        'When anger is fed, judgment becomes clouded. A pause gives wisdom room to return.',
    reflection:
        'Anger may point to pain, fear, or a blocked expectation. Listening inward first can prevent harm outward.',
    practice: 'Pause before responding.',
  ),
  'attachment': _AskTopicProfile(
    topic: 'attachment',
    intent: EmotionalIntent.attachment,
    verseIds: ['2.47', '2.48', '3.19'],
    searchTerms: 'attachment results fruit action karma detachment',
    opening: 'It is possible to care deeply and still loosen your grip.',
    guidance:
        'You can care deeply without clinging tightly. Give the action your full sincerity, then let the result arrive in its own time. Peace grows when effort is steady and expectation softens.',
    meaning:
        'The work is yours to offer; the result is shaped by many forces beyond you.',
    reflection:
        'Attachment often hides inside good intentions. Let the action be complete in itself.',
    practice: 'Complete one duty without checking results.',
  ),
  'discipline': _AskTopicProfile(
    topic: 'discipline',
    intent: EmotionalIntent.discipline,
    verseIds: ['6.5', '3.8', '6.26'],
    searchTerms: 'discipline motivation focus mind practice duty',
    opening:
        'If motivation feels absent, begin smaller instead of judging yourself.',
    guidance:
        'Do not wait until motivation feels perfect. Begin with one small act and let steadiness build from repetition. The mind becomes stronger when it is guided gently and consistently.',
    meaning:
        'You can lift yourself through patient effort. Small disciplined actions change the direction of the mind.',
    reflection:
        'Discipline is not harshness. It is a quiet promise kept again and again.',
    practice: 'Do one focused task for 15 minutes.',
  ),
  'motivation': _AskTopicProfile(
    topic: 'motivation',
    intent: EmotionalIntent.motivation,
    verseIds: ['3.8', '2.40', '6.5'],
    searchTerms: 'motivation action duty effort beginning practice',
    opening:
        'When motivation is low, treat the first small action as the practice.',
    guidance:
        'You do not need to feel inspired before beginning. Sincere action can steady the mind before motivation returns. Start small enough that resistance does not become the whole story.',
    meaning:
        'Action taken with sincerity can lift the mind even when enthusiasm is weak.',
    reflection:
        'Waiting to feel ready can become another form of avoidance. One honest beginning is often enough to change the day.',
    practice: 'Start with five sincere minutes.',
  ),
  'purpose': _AskTopicProfile(
    topic: 'purpose',
    intent: EmotionalIntent.purpose,
    verseIds: ['3.35', '18.46', '3.8'],
    searchTerms: 'purpose dharma duty work calling path action',
    opening:
        'When purpose feels unclear, start with the responsibility that is closest.',
    guidance:
        'Purpose is often found by serving the duty nearest to you with honesty. You do not need a perfect life plan before acting well. Begin where your responsibility and sincerity meet.',
    meaning:
        'Your path becomes clearer when you honor your own duty instead of comparing it with someone else\'s.',
    reflection:
        'A meaningful life is built through faithful actions, not dramatic certainty.',
    practice: 'Complete one duty with full attention.',
  ),
  'mind': _AskTopicProfile(
    topic: 'self-mastery',
    intent: EmotionalIntent.selfMastery,
    verseIds: ['6.26', '6.5', '6.6'],
    searchTerms: 'mind thoughts restless focus self mastery discipline',
    opening:
        'A restless mind does not mean you are failing; it means practice has begun.',
    guidance:
        'Do not fight every thought as if it were an enemy. Notice where the mind has gone and bring it back with patience. Each return strengthens your inner freedom.',
    meaning:
        'The mind is trained by gentle return. Wandering is expected; coming back is the practice.',
    reflection:
        'Peace is built through repeated return, not through perfect stillness. Treat the mind firmly, but without cruelty.',
    practice: 'Return your attention without self-blame.',
  ),
  'devotion': _AskTopicProfile(
    topic: 'devotion',
    intent: EmotionalIntent.devotion,
    verseIds: ['12.13', '18.66', '12.15'],
    searchTerms: 'devotion love kindness humility surrender bhakti',
    opening:
        'Devotion can begin quietly, right inside the next ordinary action.',
    guidance:
        'Devotion does not have to be loud. It can appear as kindness, humility, and trust in ordinary moments. Let love shape one action today.',
    meaning:
        'A devoted heart becomes gentle toward others and less trapped by ego.',
    reflection:
        'Devotion is not only feeling close to God; it is living with reverence when no one is watching.',
    practice: 'Offer one quiet act of kindness.',
  ),
  'grief': _AskTopicProfile(
    topic: 'grief',
    intent: EmotionalIntent.grief,
    verseIds: ['2.14', '2.20', '2.27'],
    searchTerms: 'grief loss sorrow pain change self imperishable',
    opening:
        'For grief, gentleness is not weakness; it is the right pace for the heart.',
    guidance:
        'Grief asks for tenderness, not force. Let the pain be present without deciding it must define the whole day. Steadiness can begin as one gentle breath.',
    meaning:
        'Pain changes shape over time. You can meet it with patience instead of fighting every wave.',
    reflection:
        'Love and loss can sit in the same heart. Moving slowly is still movement.',
    practice: 'Take one gentle breath before the next task.',
  ),
  'relationships': _AskTopicProfile(
    topic: 'relationships',
    intent: EmotionalIntent.relationships,
    verseIds: ['12.13', '2.63', '6.5'],
    searchTerms: 'relationships compassion anger kindness humility conflict',
    opening:
        'With someone you care about, steadiness matters as much as being right.',
    guidance:
        'In relationships, clarity and kindness both matter. Speak from steadiness rather than from the first sharp emotion. A softer response can still be truthful.',
    meaning: 'A mature heart lets go of hatred, pride, and harshness.',
    reflection:
        'The goal is not to win every exchange. The goal is to act without losing yourself.',
    practice: 'Choose gentleness in one conversation.',
  ),
  'work': _AskTopicProfile(
    topic: 'work pressure',
    intent: EmotionalIntent.workStress,
    verseIds: ['3.8', '2.47', '2.48'],
    searchTerms: 'work pressure duty action stress overwhelm effort',
    opening:
        'When work feels overwhelming, shrink the day to one clear responsibility.',
    guidance:
        'When work feels heavy, reduce the field of attention. You do not have to carry the whole burden at once. Give one task your full presence, then move to the next.',
    meaning:
        'Action is necessary, but it becomes lighter when done steadily and without panic.',
    reflection:
        'Pressure scatters the mind by making everything feel equally important. Peace returns through one clear priority.',
    practice: 'Finish one task before starting another.',
  ),
  'peace': _AskTopicProfile(
    topic: 'peace',
    intent: EmotionalIntent.peace,
    verseIds: ['2.66', '2.70', '2.48'],
    searchTerms: 'peace calm mind desire steadiness balance',
    opening:
        'If you are seeking peace, begin by making this moment less crowded.',
    guidance:
        'Peace is not found by forcing every feeling away. It grows when the mind stops chasing and resisting so intensely. Start by making one moment simpler.',
    meaning:
        'A steady mind is less disturbed by passing desires, fears, and reactions.',
    reflection:
        'Peace often begins as restraint: not feeding every thought, not answering every pull.',
    practice: 'Sit quietly for three slow breaths.',
  ),
  'fallback': _AskTopicProfile(
    topic: 'general guidance',
    intent: EmotionalIntent.peace,
    verseIds: ['2.47', '2.48', '12.13'],
    searchTerms: 'peace duty action devotion steadiness wisdom',
    opening:
        'For what you are carrying, begin with the part that is truly yours.',
    guidance:
        'Begin with what is honestly in front of you. Act with care, keep the heart steady, and do not demand full control before taking the next step.',
    meaning:
        'Sincere action becomes clearer when it is joined with inner steadiness.',
    reflection:
        'A spiritual answer does not remove responsibility; it helps you carry it with a clearer mind.',
    practice: 'Do the next right thing calmly.',
  ),
};
