import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/services/gita_service.dart' as service;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Bhagavad Gita chapters and verses from asset JSON', () async {
    final bundle = await GitaRepository.load();

    expect(bundle.chapters, hasLength(18));
    expect(bundle.verses, hasLength(700));
    expect(
      GitaDataService.chapterAssetPath(1),
      'assets/data/gita/chapter1.json',
    );
    expect(bundle.chapterByNumber(13)?.verseCount, 34);
    expect(await GitaRepository.versesForChapter(13), hasLength(34));
    expect(bundle.verseById('2.47')?.englishTranslation,
        contains('fruits of action'));
    expect(bundle.verseById('2.47')?.tags, contains('karma'));
    expect(bundle.verseById('2.47')?.audioAssetPath, isEmpty);
    expect(bundle.verseById('2.48')?.audioAssetPath, isEmpty);
  });

  test('supports the required real verse content schema', () async {
    final bundle = await GitaRepository.load();
    final chapterOneSample =
        bundle.verses.where((verse) => verse.chapterNumber == 1).take(3);
    final chapterTwoSample =
        bundle.verses.where((verse) => verse.chapterNumber == 2).take(3);

    expect(chapterOneSample, isNotEmpty);
    expect(chapterTwoSample, isNotEmpty);
    for (final verse in [...chapterOneSample, ...chapterTwoSample]) {
      expect(verse.chapterNumber, greaterThan(0));
      expect(verse.verseNumber, greaterThan(0));
      expect(verse.sanskrit, isNotEmpty);
      expect(verse.transliteration, isNotEmpty);
      expect(verse.englishTranslation, isNotEmpty);
      expect(verse.meaning, isNotEmpty);
      expect(verse.tags, isNotEmpty);
    }
  });

  test('validates all 700 verse identities and local scripture fields',
      () async {
    final bundle = await GitaRepository.load();
    final seen = <String>{};
    const blockedUiTerms = [
      'ai translation',
      'generated',
      'lorem ipsum',
      'placeholder',
      'sanskrit unavailable',
      'transliteration unavailable',
      'english translation unavailable',
    ];

    expect(bundle.verses, hasLength(700));
    for (final verse in bundle.verses) {
      expect(verse.chapterNumber, inInclusiveRange(1, 18));
      expect(verse.verseNumber, greaterThan(0));
      expect(seen.add('${verse.chapterNumber}.${verse.verseNumber}'), isTrue);

      expect(verse.sanskrit.trim(), isNotEmpty);
      expect(verse.transliteration.trim(), isNotEmpty);
      expect(verse.englishTranslation.trim(), isNotEmpty);

      final visibleContent = [
        verse.sanskrit,
        verse.transliteration,
        verse.englishTranslation,
        verse.cleanMeaning,
        verse.reflectionText,
        verse.practiceToday,
      ].join('\n').toLowerCase();
      for (final term in blockedUiTerms) {
        expect(visibleContent, isNot(contains(term)));
      }
    }
  });

  test('scripture translations preserve Gita imagery and source wording',
      () async {
    final bundle = await GitaRepository.load();
    final karmaYoga = bundle.verseById('2.47')!.englishTranslation;
    final practiceVerse = bundle.verseById('12.9')!.englishTranslation;
    final battleVerse = bundle.verseById('11.34')!.englishTranslation;
    final chariotVerse = bundle.verseById('1.24')!.englishTranslation;

    expect(karmaYoga, contains('fruits of action'));
    expect(practiceVerse, contains('Yoga'));
    expect(battleVerse, contains('warriors'));
    expect(battleVerse, contains('battle'));
    expect(chariotVerse.toLowerCase(), contains('chariot'));

    final combined = [
      karmaYoga,
      practiceVerse,
      battleVerse,
      chariotVerse,
    ].join(' ').toLowerCase();
    expect(combined, isNot(contains('employee')));
    expect(combined, isNot(contains('office')));
  });

  test('GitaVerse supports translation and commentary aliases', () {
    final verse = GitaVerse.fromJson({
      'id': '1.1',
      'chapterNumber': 1,
      'verseNumber': 1,
      'sanskrit': 'sanskrit',
      'transliteration': 'transliteration',
      'translation': 'translation text',
      'commentary': 'commentary text',
      'tags': ['dharma'],
    });

    expect(verse.englishTranslation, 'translation text');
    expect(verse.translation, 'translation text');
    expect(verse.meaning, 'commentary text');
    expect(verse.commentary, 'commentary text');
    expect(verse.audioAssetPath, isEmpty);
  });

  test('missing optional scripture fields stay empty for graceful UI hiding',
      () {
    final verse = GitaVerse.fromJson({
      'id': '1.1',
      'chapterNumber': 1,
      'verseNumber': 1,
    });

    expect(verse.sanskrit, isEmpty);
    expect(verse.transliteration, isEmpty);
    expect(verse.englishTranslation, isEmpty);
    expect(verse.meaning, isEmpty);
  });

  test('translation is not reused as meaning when commentary is absent', () {
    final verse = GitaVerse.fromJson({
      'id': '1.1',
      'chapterNumber': 1,
      'verseNumber': 1,
      'translation': 'translation only',
    });

    expect(verse.englishTranslation, 'translation only');
    expect(verse.meaning, isEmpty);
  });

  test('GitaChapter model alias is available', () async {
    final chapters = await GitaDataService.allChapters();
    final GitaChapter firstChapter = chapters.first;

    expect(firstChapter.chapterNumber, 1);
    expect(firstChapter.verseCount, 47);
  });

  test('GitaDataService groups verses by chapter', () async {
    final grouped = await GitaDataService.versesGroupedByChapter();

    expect(grouped, hasLength(18));
    expect(grouped[1], hasLength(47));
    expect(grouped[2], hasLength(72));
    expect(grouped[13], hasLength(34));
    expect(grouped[18], hasLength(78));
    expect(grouped[1]?.first.id, '1.1');
  });

  test('loads chapter JSON assets', () async {
    final typedChapter = await GitaDataService.loadChapter(1);
    final rawChapter = await loadChapter(1);

    expect(typedChapter, hasLength(47));
    expect(typedChapter.first.id, '1.1');
    expect(rawChapter, hasLength(47));
    expect(rawChapter.first, isA<Map<String, dynamic>>());
  });

  test('GitaService facade loads full dataset and chapter assets', () async {
    final bundle = await service.GitaService.loadAll();
    final chapterOne = await service.GitaService.loadChapter(1);
    final rawChapterOne = await service.loadChapter(1);

    expect(bundle.verseCount, 700);
    expect(bundle.chapterCount, 18);
    expect(chapterOne, hasLength(47));
    expect(rawChapterOne, hasLength(47));
  });

  test('searches verses by reference and verse text', () async {
    final byReference = await GitaRepository.search('2.47', limit: 1);
    final byText = await GitaRepository.search('action fruits', limit: 10);
    final byMeaning = await GitaRepository.search('Paroksha', limit: 10);
    final byChapterVerse = await GitaRepository.search('1.1', limit: 1);
    final bySanskrit = await GitaRepository.search('धर्मक्षेत्रे', limit: 5);
    final byTransliteration =
        await GitaRepository.search('dharmakṣetre', limit: 5);

    expect(byReference.single.verse.id, '2.47');
    expect(byText.map((result) => result.verse.id), contains('2.47'));
    expect(byMeaning.map((result) => result.verse.id), contains('7.2'));
    expect(byChapterVerse.single.verse.id, '1.1');
    expect(bySanskrit.map((result) => result.verse.id), contains('1.1'));
    expect(byTransliteration.map((result) => result.verse.id), contains('1.1'));
  });

  test('search ranking prioritizes emotional topics and interpretation',
      () async {
    const topicQueries = [
      'fear',
      'stress',
      'anger',
      'anxiety',
      'attachment',
      'discipline',
      'purpose',
      'devotion',
      'focus',
      'uncertainty',
      'frustration',
      'resentment',
      'meaning',
      'direction',
    ];

    for (final query in topicQueries) {
      final results = await GitaRepository.search(query, limit: 6);
      expect(results, isNotEmpty, reason: query);

      final visibleRelevance = results.take(3).map((result) {
        final verse = result.verse;
        return [
          verse.allTags.join(' '),
          verse.gitaWisdomInterpretation,
          verse.reflectionText,
          verse.practiceToday,
        ].join(' ').toLowerCase();
      }).join(' ');

      expect(
        visibleRelevance,
        anyOf([
          contains(query),
          contains('peace'),
          contains('mind'),
          contains('action'),
          contains('duty'),
          contains('devotion'),
          contains('self-control'),
          contains('focus'),
          contains('clarity'),
        ]),
        reason: query,
      );
    }
  });
}
