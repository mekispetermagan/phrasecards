import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/pronunciation.dart';
import 'package:phrasecards/models/quiz.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:phrasecards/screens/quiz_screen.dart';
import 'package:phrasecards/widgets/buttons.dart';

final _question = QuizQuestion(
  source: 'Hello',
  options: [
    QuizOption(text: 'One', audioPath: '/audio/one.mp3'),
    QuizOption(text: 'Two', audioPath: '/audio/two.mp3'),
    QuizOption(text: 'Three', audioPath: '/audio/three.mp3'),
    QuizOption(text: 'Four', audioPath: '/audio/four.mp3'),
  ],
  correctIndex: 0,
);

QuizViewData _viewData({required bool showPronunciationButtons}) =>
    QuizViewData(
      question: _question,
      score: 0,
      attemptCount: 0,
      correctHighlightIndex: null,
      wrongHighlightIndex: null,
      optionPronunciations: const [
        PronunciationData(path: '/audio/one.mp3'),
        PronunciationData(path: '/audio/two.mp3'),
        PronunciationData(path: '/audio/three.mp3'),
        PronunciationData(path: '/audio/four.mp3'),
      ],
      showPronunciationButtons: showPronunciationButtons,
    );

Widget _app({
  required bool showPronunciationButtons,
  ValueChanged<bool>? onVisibilityChanged,
}) => MaterialApp(
  home: QuizScreen(
    viewData: _viewData(showPronunciationButtons: showPronunciationButtons),
    onBack: () {},
    submit: (_) async {},
    playAudio: (_) async {},
    setShowPronunciationButtons: onVisibilityChanged ?? (_) {},
  ),
);

void main() {
  testWidgets('switch forwards pronunciation visibility changes', (
    tester,
  ) async {
    bool? changedValue;
    await tester.pumpWidget(
      _app(
        showPronunciationButtons: true,
        onVisibilityChanged: (value) => changedValue = value,
      ),
    );

    await tester.tap(find.byType(Switch));

    expect(changedValue, isFalse);
  });

  testWidgets('option buttons fill the row when speakers are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(_app(showPronunciationButtons: true));
    final widthWithSpeaker = tester
        .getSize(find.byType(FilledButton).first)
        .width;
    expect(find.byType(SpeakerButton), findsNWidgets(4));

    await tester.pumpWidget(_app(showPronunciationButtons: false));
    final fullRowWidth = tester.getSize(find.byType(FilledButton).first).width;

    expect(find.byType(SpeakerButton), findsNothing);
    expect(fullRowWidth, greaterThan(widthWithSpeaker));
  });
}
