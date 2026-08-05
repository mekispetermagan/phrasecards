import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/learn.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:phrasecards/screens/learn_screen.dart';

void main() {
  testWidgets('selector forwards merged group selections', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Set<PhraseGroup>? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: LearnScreen(
          viewData: const LearnViewData(
            phrase: null,
            isTurned: false,
            isNew: false,
            selectedGroups: {PhraseGroup.learning},
            pronunciation: null,
          ),
          onBack: () {},
          turn: () {},
          next: () async {},
          playAudio: () async {},
          setSelectedGroups: (groups) => selected = groups,
        ),
      ),
    );

    expect(find.byType(SegmentedButton<PhraseGroup>), findsOneWidget);
    expect(find.text('No phrases in the selected groups.'), findsOneWidget);

    await tester.tap(find.text('Practiced'));
    await tester.pump();

    expect(selected, {PhraseGroup.learning, PhraseGroup.practiced});
  });
}
