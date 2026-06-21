import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/pages/home_page/home_page_widget.dart';
import 'package:gita_wisdom/pages/verse_reader_page/verse_reader_page_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitaDataService.resetForTests();
  });

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 24; i += 1) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('Today’s Guidance opens focused VerseReader without browsing', (
    tester,
  ) async {
    await tester.runAsync(GitaRepository.load);

    final router = GoRouter(
      initialLocation: '/homePage',
      routes: [
        GoRoute(
          path: '/homePage',
          builder: (context, state) => const HomePageWidget(),
        ),
        GoRoute(
          path: '/verseReaderPage',
          builder: (context, state) => VerseReaderPageWidget(
            verseId: state.uri.queryParameters['verseId'],
            source: state.uri.queryParameters['source'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(seconds: 2));
    await pumpUntilFound(tester, find.text('Read Verse'));

    await tester.ensureVisible(find.text('Read Verse'));
    await tester.pump();
    await tester.tap(find.text('Read Verse'));
    await tester.pumpAndSettle();

    expect(find.byType(VerseReaderPageWidget), findsOneWidget);
    expect(find.text('Today’s Guidance'), findsOneWidget);
    expect(find.text('Previous Verse'), findsNothing);
    expect(find.text('Next Verse'), findsNothing);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePageWidget), findsOneWidget);
    expect(find.text('Today\'s Guidance'), findsOneWidget);
  });
}
