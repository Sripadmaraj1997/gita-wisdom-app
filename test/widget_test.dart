import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/main.dart';
import 'package:gita_wisdom/pages/gita_common/gita_common.dart';
import 'package:gita_wisdom/pages/ask_gita_page/ask_gita_page_widget.dart';
import 'package:gita_wisdom/pages/chapters_page/chapters_page_widget.dart';
import 'package:gita_wisdom/pages/home_page/home_page_widget.dart';
import 'package:gita_wisdom/pages/search_page/search_page_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> launchFreshApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(HomePageWidget), findsOneWidget);
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tapHomeAction(WidgetTester tester, String label) async {
    final labelFinder = find.text(label);
    await tester.ensureVisible(labelFinder);
    await tester.pump(const Duration(milliseconds: 300));
    final button = find
        .ancestor(
          of: labelFinder,
          matching: find.byType(PressableScale),
        )
        .last;
    await tester.tap(button);
  }

  testWidgets('fresh launch opens Home once', (WidgetTester tester) async {
    await launchFreshApp(tester);
    await disposeApp(tester);
  });

  testWidgets('fresh launch Read Gita navigation remains on Read', (
    WidgetTester tester,
  ) async {
    await launchFreshApp(tester);

    await tapHomeAction(tester, 'Read Gita');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(ChaptersPageWidget), findsOneWidget);
    expect(find.byType(HomePageWidget), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('fresh launch Ask Gita navigation remains on Ask Gita', (
    WidgetTester tester,
  ) async {
    await launchFreshApp(tester);

    await tapHomeAction(tester, 'Ask Gita');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AskGitaPageWidget), findsOneWidget);
    expect(find.byType(HomePageWidget), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('fresh launch Search navigation remains on Search', (
    WidgetTester tester,
  ) async {
    await launchFreshApp(tester);

    await tester.tap(find.text('Search').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(SearchPageWidget), findsOneWidget);
    expect(find.byType(HomePageWidget), findsNothing);
    await disposeApp(tester);
  });
}
