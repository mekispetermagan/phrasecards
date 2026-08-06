import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:phrasecards/screens/numbers_screen.dart';
import 'package:phrasecards/widgets/buttons.dart';

const _options = ['kettő', 'öt', 'hét'];

NumbersViewData _viewData({
  int? successHighlightIndex,
  int? failureHighlightIndex,
}) => NumbersViewData(
  solution: 5,
  options: _options,
  emoji: '🍎',
  score: 3,
  successHighlightIndex: successHighlightIndex,
  failureHighlightIndex: failureHighlightIndex,
);

Widget _app({
  NumbersViewData? viewData,
  Future<void> Function(int)? onSubmit,
  VoidCallback? onBack,
}) => MaterialApp(
  theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
  home: NumbersScreen(
    viewData: viewData ?? _viewData(),
    onBack: onBack ?? () {},
    onSubmit: onSubmit,
  ),
);

void main() {
  testWidgets('renders the count, options, and score', (tester) async {
    await tester.pumpWidget(_app(onSubmit: (_) async {}));

    expect(find.text('🍎'), findsNWidgets(5));
    for (final option in _options) {
      expect(find.text(option), findsOneWidget);
    }
    expect(find.text('Score: 3'), findsOneWidget);
  });

  testWidgets('forwards the selected option index', (tester) async {
    int? submittedIndex;
    await tester.pumpWidget(
      _app(onSubmit: (index) async => submittedIndex = index),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'öt'));

    expect(submittedIndex, 1);
  });

  testWidgets('disables every option while submission is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    final buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));
    expect(buttons, hasLength(3));
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });

  testWidgets('uses distinct success and failure feedback colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        viewData: _viewData(successHighlightIndex: 0, failureHighlightIndex: 1),
      ),
    );

    final buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));
    final backgrounds = buttons
        .map((button) => button.style!.backgroundColor!.resolve({}))
        .toList();

    expect(backgrounds[0], isNot(backgrounds[1]));
    expect(backgrounds[1], isNot(backgrounds[2]));
  });

  testWidgets('forwards back navigation', (tester) async {
    var wentBack = false;
    await tester.pumpWidget(
      _app(onSubmit: (_) async {}, onBack: () => wentBack = true),
    );

    await tester.tap(find.byType(ExitButton));

    expect(wentBack, isTrue);
  });
}
