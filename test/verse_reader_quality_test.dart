import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VerseReader keeps scripture first and action row compact', () {
    final source = File(
      'lib/pages/verse_reader_page/verse_reader_page_widget.dart',
    ).readAsStringSync();

    final contentStart = source.indexOf('final content = PremiumCard');
    final referenceIndex = source.indexOf(
        '_ReadingProgressHeader(', source.indexOf('children: [', contentStart));
    final sanskritIndex =
        source.indexOf("const _ReadingSectionLabel('Sanskrit')", contentStart);
    final transliterationIndex = source.indexOf(
        "const _ReadingSectionLabel('Transliteration')", contentStart);
    final translationIndex =
        source.indexOf('_TranslationReadingCard(', contentStart);
    final actionsIndex = source.indexOf('_VerseBottomActions(', contentStart);
    final interpretationIndex =
        source.indexOf('_GitaWisdomInterpretationPanel(', contentStart);
    final reflectionIndex =
        source.indexOf('_ReflectionAndPracticePanels(', contentStart);

    expect(referenceIndex, greaterThanOrEqualTo(0));
    expect(sanskritIndex, greaterThan(referenceIndex));
    expect(transliterationIndex, greaterThan(sanskritIndex));
    expect(translationIndex, greaterThan(transliterationIndex));
    expect(actionsIndex, greaterThan(translationIndex));
    expect(interpretationIndex, greaterThan(actionsIndex));
    expect(reflectionIndex, greaterThan(interpretationIndex));

    final actionsStart = source.indexOf('class _VerseBottomActions');
    final saveIndex = source.indexOf('_SaveActionChip(', actionsStart);
    final shareIndex = source.indexOf("label: 'Share'", actionsStart);
    final playIndex = source.indexOf('_VerseAudioControl(', actionsStart);
    final highlightIndex =
        source.indexOf('_HighlightActionChip(', actionsStart);

    expect(saveIndex, greaterThanOrEqualTo(0));
    expect(shareIndex, greaterThan(saveIndex));
    expect(playIndex, greaterThan(shareIndex));
    expect(highlightIndex, greaterThan(playIndex));
    expect(source, contains("label: isSaved ? 'Saved Wisdom' : 'Save'"));
    expect(source, isNot(contains("label: 'Save Reflection'")));
    expect(
      source,
      contains('Carry one insight from this verse into your day.'),
    );
  });
}
