import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/accents.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:phrasecards/screens/accents_screen.dart';

Widget _screen(AccentsPhase phase) {
  return MaterialApp(
    home: AccentsScreen(
      viewData: AccentsViewData(
        currentLetterData: null,
        accentedVowelData: const [],
        pronunciation: null,
        phase: phase,
      ),
      onBack: () {},
      onNext: () {},
      onDrop:
          ({required String dragTargetId, required String draggableLetter}) {},
      playAudio: () async {},
    ),
  );
}

void main() {
  testWidgets('distinguishes unavailable exercises from completion', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(AccentsPhase.unavailable));

    expect(find.text('No suitable accent exercises found.'), findsOneWidget);
    expect(find.text('You completed all accent exercises.'), findsNothing);

    await tester.pumpWidget(_screen(AccentsPhase.completed));

    expect(find.text('No suitable accent exercises found.'), findsNothing);
    expect(find.text('You completed all accent exercises.'), findsOneWidget);
  });
}
