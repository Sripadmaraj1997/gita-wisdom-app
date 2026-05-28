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
        contains('Thy right is to work only'));
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

  test('loads generated chapter JSON assets', () async {
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
    final byChapterVerse = await GitaRepository.search('1.1', limit: 1);
    final bySanskrit = await GitaRepository.search('धर्मक्षेत्रे', limit: 5);
    final byTransliteration =
        await GitaRepository.search('dharmakṣetre', limit: 5);

    expect(byReference.single.verse.id, '2.47');
    expect(byText.map((result) => result.verse.id), contains('2.47'));
    expect(byChapterVerse.single.verse.id, '1.1');
    expect(bySanskrit.map((result) => result.verse.id), contains('1.1'));
    expect(byTransliteration.map((result) => result.verse.id), contains('1.1'));
  });
}
