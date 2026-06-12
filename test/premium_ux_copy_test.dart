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

    expect(savedSource, contains('No saved wisdom yet.'));
    expect(savedSource, contains('Peace often begins with a single verse.'));
    expect(savedSource, contains('Begin your reflection journey'));
    expect(searchSource, contains('No matching verse surfaced yet.'));
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
    expect(homeSource, contains('What insight will you carry forward?'));
    expect(journeySource, contains('What insight will you carry forward?'));
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
    expect(settingsSource, contains('Community Links'));
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
    expect(readAskIndex, greaterThan(continueIndex));
    expect(guidanceIndex, greaterThan(readAskIndex));
    expect(journeyIndex, greaterThan(guidanceIndex));
    expect(reflectedIndex, greaterThan(journeyIndex));
    expect(secondaryIndex, greaterThan(reflectedIndex));

    final primaryStart = homeSource.indexOf('class _PrimaryActionCards');
    final primaryEnd = homeSource.indexOf('class _SecondaryActionCards');
    final primarySource = homeSource.substring(primaryStart, primaryEnd);
    expect(primarySource, contains('highlightedIndexes: const {}'));
  });
}
