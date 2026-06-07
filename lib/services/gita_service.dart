// Compatibility facade for the local Gita data layer.
//
// Older FlutterFlow-generated pages imported GitaService directly. Newer code
// usually calls GitaDataService or GitaRepository, but this wrapper keeps legacy
// imports stable while still serving the same local JSON-backed scripture data.
import '../data/gita_data.dart';

export '../data/gita_data.dart'
    show
        GitaChapter,
        GitaChapterData,
        GitaDataBundle,
        GitaSearchResult,
        GitaVerse;

class GitaService {
  const GitaService._();

  static Future<GitaDataBundle> loadAll() {
    return GitaDataService.load();
  }

  static Future<List<GitaChapterData>> loadChapters() {
    return GitaDataService.allChapters();
  }

  static Future<List<GitaVerse>> loadVerses() {
    return GitaDataService.allVerses();
  }

  static Future<List<GitaVerse>> loadChapter(int chapterNumber) {
    return GitaDataService.loadChapter(chapterNumber);
  }

  static Future<Map<int, List<GitaVerse>>> groupedByChapter() {
    return GitaDataService.versesGroupedByChapter();
  }

  static Future<GitaVerse?> verseById(String id) {
    return GitaDataService.verseById(id);
  }

  static Future<GitaVerse> dailyVerse() {
    return GitaRepository.dailyVerse();
  }

  static Future<List<GitaSearchResult>> search(
    String query, {
    int limit = 20,
  }) {
    return GitaRepository.search(query, limit: limit);
  }
}

Future<List<dynamic>> loadChapter(int chapterNumber) async {
  return GitaDataService.loadRawChapter(chapterNumber);
}
