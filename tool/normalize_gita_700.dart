import 'dart:convert';
import 'dart:io';

const path = 'assets/data/gita_verses/gita_verses.json';

const devanagariDigits = {
  '0': '०',
  '1': '१',
  '2': '२',
  '3': '३',
  '4': '४',
  '5': '५',
  '6': '६',
  '7': '७',
  '8': '८',
  '9': '९',
};

String devanagariNumber(int value) {
  return value
      .toString()
      .split('')
      .map((digit) => devanagariDigits[digit]!)
      .join();
}

void main() {
  final file = File(path);
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  data['verseCount'] = 700;
  data['source'] =
      'Bhagavad Gita data sourced from VedicScriptures via Voider22/bhagavad-gita-verses-sanskrit-translations dataset; normalized to the common 700-verse canon by omitting the optional Chapter 13 opening question.';

  final chapters = (data['chapters'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((chapter) {
    if (chapter['chapterNumber'] == 13) {
      return {
        ...chapter,
        'verseCount': 34,
      };
    }
    return chapter;
  }).toList();

  final verses = <Map<String, dynamic>>[];
  for (final original
      in (data['verses'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final chapterNumber = original['chapterNumber'] as int;
    final verseNumber = original['verseNumber'] as int;
    if (chapterNumber == 13 && verseNumber == 1) {
      continue;
    }

    if (chapterNumber == 13 && verseNumber > 1) {
      final newVerseNumber = verseNumber - 1;
      final oldDevRef = '१३-${devanagariNumber(verseNumber)}';
      final newDevRef = '१३-${devanagariNumber(newVerseNumber)}';
      final oldLatinRef = '13-$verseNumber';
      final newLatinRef = '13-$newVerseNumber';
      verses.add({
        ...original,
        'id': '13.$newVerseNumber',
        'verseNumber': newVerseNumber,
        'sanskrit':
            (original['sanskrit'] as String).replaceAll(oldDevRef, newDevRef),
        'transliteration': (original['transliteration'] as String)
            .replaceAll(oldLatinRef, newLatinRef),
      });
    } else {
      verses.add(original);
    }
  }

  data['chapters'] = chapters;
  data['verses'] = verses;

  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(data)}\n');
}
