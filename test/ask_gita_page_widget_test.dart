import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gita_wisdom/data/gita_data.dart';
import 'package:gita_wisdom/pages/ask_gita_page/ask_gita_page_widget.dart';
import 'package:gita_wisdom/pages/gita_common/gita_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitaDataService.resetForTests();
  });

  Future<void> pumpAskGita(WidgetTester tester) async {
    tester.view.physicalSize = const Size(820, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() => GitaRepository.load());
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AskGitaPageWidget(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
  }

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 24; i += 1) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('suggested worrying question sends and shows full answer', (
    tester,
  ) async {
    await pumpAskGita(tester);

    final suggestedQuestion = find.text('How do I stop worrying?');
    final suggestedQuestionChip = find
        .ancestor(
          of: suggestedQuestion,
          matching: find.byType(PressableScale),
        )
        .first;

    await tester.tap(suggestedQuestionChip);
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is EditableText &&
            widget.controller.text == 'How do I stop worrying?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Send'));
    await pumpUntilFound(tester, find.text('Gentle Guidance'));

    expect(find.text('Gentle Guidance'), findsOneWidget);
    expect(find.text('Relevant Verse'), findsOneWidget);
    expect(find.text('Meaning'), findsOneWidget);
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Practice Today'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
