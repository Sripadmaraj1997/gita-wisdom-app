import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium UX copy keeps warm empty states and trust language', () {
    final savedSource = File(
      'lib/pages/saved_verses_page/saved_verses_page_widget.dart',
    ).readAsStringSync();
    final searchSource = File(
      'lib/pages/search_page/search_page_widget.dart',
    ).readAsStringSync();
    final settingsSource = File(
      'lib/pages/settings_page/settings_page_widget.dart',
    ).readAsStringSync();
    final askSource = File(
      'lib/pages/ask_gita_page/ask_gita_page_widget.dart',
    ).readAsStringSync();
    final homeSource = File(
      'lib/pages/home_page/home_page_widget.dart',
    ).readAsStringSync();
    final journeySource = File(
      'lib/pages/transformation_page/transformation_page_widget.dart',
    ).readAsStringSync();

    expect(savedSource, contains('Your wisdom collection is empty.'));
    expect(
      savedSource,
      contains('Save one verse or reflection when it gives you an insight'),
    );
    expect(savedSource, contains('Return to the verses and reflections'));
    expect(savedSource, contains('choose one wiser action'));
    expect(searchSource, contains('No matching verse surfaced yet.'));
    expect(searchSource, contains('Find a verse for what you are carrying'));
    expect(
      settingsSource,
      contains(
        'Gita Wisdom Interpretation offers practical contemplative insights',
      ),
    );
    expect(
      askSource,
      contains('What is one thing you will remember from this today?'),
    );
    expect(
      askSource,
      contains('Return to this once today when the same feeling appears.'),
    );
    expect(homeSource, contains('Apply Today'));
    expect(homeSource, contains('Read once. Carry one action.'));
    expect(homeSource, contains('Continue Your Journey'));
    expect(homeSource, contains("label: 'Continue'"));
    expect(journeySource, contains('What insight will you carry forward?'));
    expect(journeySource, contains('Mark Day Complete'));
    expect(journeySource, contains("label: 'Continue'"));
  });

  test('final cleanup keeps Home and Settings uncluttered', () {
    final homeSource = File(
      'lib/pages/home_page/home_page_widget.dart',
    ).readAsStringSync();
    final settingsSource = File(
      'lib/pages/settings_page/settings_page_widget.dart',
    ).readAsStringSync();
    final navSource = File('lib/flutter_flow/nav/nav.dart').readAsStringSync();

    expect(homeSource, isNot(contains("Today's Verse")));
    expect(homeSource, isNot(contains('One Minute Wisdom')));
    expect(homeSource, contains('Recently Reflected On'));
    expect(homeSource, isNot(contains('Private study tools')));
    expect(settingsSource, isNot(contains('Send Feedback')));
    expect(settingsSource, isNot(contains('Project Source')));
    expect(settingsSource, isNot(contains('Community Links')));
    expect(homeSource, isNot(contains('Take one slow breath')));
    expect(navSource, isNot(contains('OneMinuteWisdomPageWidget')));
  });

  test('Home follows calm companion section order', () {
    final homeSource = File(
      'lib/pages/home_page/home_page_widget.dart',
    ).readAsStringSync();

    final continueIndex = homeSource.indexOf('// Continue Reading:');
    final readAskIndex = homeSource.indexOf('// Read Gita / Ask Gita:');
    final guidanceIndex = homeSource.indexOf("// Today's Guidance:");
    final journeyIndex = homeSource.indexOf('// Journeys:');
    final reflectedIndex = homeSource.indexOf(
      '_RecentlyReflectedSection(',
      journeyIndex,
    );
    final secondaryIndex = homeSource.indexOf(
      '// Secondary actions:',
      reflectedIndex,
    );

    expect(continueIndex, greaterThanOrEqualTo(0));
    expect(guidanceIndex, greaterThan(continueIndex));
    expect(journeyIndex, greaterThan(guidanceIndex));
    expect(readAskIndex, greaterThan(journeyIndex));
    expect(reflectedIndex, greaterThan(readAskIndex));
    expect(secondaryIndex, greaterThan(reflectedIndex));

    final primaryStart = homeSource.indexOf('class _PrimaryActionCards');
    final primaryEnd = homeSource.indexOf('class _SecondaryActionCards');
    final primarySource = homeSource.substring(primaryStart, primaryEnd);
    expect(primarySource, contains('highlightedIndexes: const {}'));
  });

  test('Journal uses guided rotating reflection prompts', () {
    final journalSource = File(
      'lib/pages/journal_page/journal_page_widget.dart',
    ).readAsStringSync();

    expect(journalSource, contains('A quiet place to understand your day'));
    expect(journalSource, contains('What disturbed your peace today?'));
    expect(journalSource, contains('What gave you clarity today?'));
    expect(journalSource, contains('What attachment can you soften?'));
    expect(journalSource, contains('What insight stayed with you?'));
    expect(journalSource, contains('Reflection prompt'));
  });
}
