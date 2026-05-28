import 'dart:convert';
import 'dart:io';

const sourcePath = 'assets/data/gita_verses/gita_verses.json';
const outputDirectory = 'assets/data/gita';

void main() {
  final sourceFile = File(sourcePath);
  final data =
      jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;
  final verses = (data['verses'] as List<dynamic>).cast<Map<String, dynamic>>();
  final directory = Directory(outputDirectory)..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');

  for (var chapterNumber = 1; chapterNumber <= 18; chapterNumber++) {
    final chapterVerses = verses
        .where((verse) => verse['chapterNumber'] == chapterNumber)
        .toList()
      ..sort((a, b) =>
          (a['verseNumber'] as int).compareTo(b['verseNumber'] as int));
    final outputFile = File('${directory.path}/chapter_$chapterNumber.json');
    outputFile.writeAsStringSync('${encoder.convert(chapterVerses)}\n');
    final appOutputFile = File('${directory.path}/chapter$chapterNumber.json');
    appOutputFile.writeAsStringSync('${encoder.convert(chapterVerses)}\n');
  }
}
