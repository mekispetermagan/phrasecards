import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/phrasebuilding_state.dart';
import 'package:phrasecards/models/phrasebuilding_tile.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:phrasecards/screens/phrasebuilding_screen.dart';

const _sourceTile = PhraseBuildingTile(id: 1, word: 'HELLO');
const _targetTile = PhraseBuildingTile(id: 2, word: 'WORLD');

Widget _app({
  void Function(PhraseBuildingTile)? move,
  VoidCallback? submit,
  PhraseBuildingState state = PhraseBuildingState.guessing,
}) => MaterialApp(
  theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
  home: PhraseBuildingScreen(
    viewData: PhraseBuildingViewData(
      sourcePool: const [_sourceTile],
      targetPool: const [_targetTile],
      state: state,
    ),
    onBack: () {},
    move: move,
    submit: submit,
  ),
);

void main() {
  testWidgets('renders both pools and forwards tile movement', (tester) async {
    PhraseBuildingTile? movedTile;
    await tester.pumpWidget(_app(move: (tile) => movedTile = tile));

    expect(find.text('HELLO'), findsOneWidget);
    expect(find.text('WORLD'), findsOneWidget);

    await tester.tap(find.text('HELLO'));
    expect(movedTile, same(_sourceTile));
  });

  testWidgets('forwards submission and disables it when unavailable', (
    tester,
  ) async {
    var submissions = 0;
    await tester.pumpWidget(_app(submit: () => submissions++));
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    expect(submissions, 1);

    await tester.pumpWidget(_app());
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('uses different card colors for feedback states', (tester) async {
    await tester.pumpWidget(_app(state: PhraseBuildingState.successFeedback));
    final successColor = tester.widget<Card>(find.byType(Card).first).color;

    await tester.pumpWidget(_app(state: PhraseBuildingState.failureFeedback));
    final failureColor = tester.widget<Card>(find.byType(Card).first).color;

    expect(successColor, isNot(failureColor));
  });
}
