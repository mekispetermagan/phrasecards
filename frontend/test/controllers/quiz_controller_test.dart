import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';
import 'package:phrasecards/controllers/quiz_controller.dart';
import 'package:phrasecards/models/phrase.dart';

class _UnusedPronunciationPlayer implements PronunciationPlayer {
  @override
  Future<void> play(String audioPath) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  test('uses new phrases as distractors but not as questions', () {
    final pronunciation = PronunciationController(
      player: _UnusedPronunciationPlayer(),
    );
    addTearDown(pronunciation.dispose);
    final controller = QuizController(
      phrases: const [
        Phrase(
          id: 1,
          source: 'New',
          target: 'Új',
          rating: 3,
          isNew: true,
          audioPath: null,
        ),
        Phrase(
          id: 2,
          source: 'Known one',
          target: 'Ismert egy',
          rating: 3,
          isNew: false,
          audioPath: null,
        ),
        Phrase(
          id: 3,
          source: 'Known two',
          target: 'Ismert kettő',
          rating: 3,
          isNew: false,
          audioPath: null,
        ),
        Phrase(
          id: 4,
          source: 'Known three',
          target: 'Ismert három',
          rating: 3,
          isNew: false,
          audioPath: null,
        ),
      ],
      pronunciation: pronunciation,
    );
    addTearDown(controller.dispose);

    expect(controller.currentQuestion.source, 'Known one');
    expect(
      controller.currentQuestion.options.map((option) => option.text),
      contains('Új'),
    );
  });
}
