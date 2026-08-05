import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/accents_controller.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';
import 'package:phrasecards/models/accents.dart';
import 'package:phrasecards/models/phrase.dart';

class _SilentPronunciationPlayer implements PronunciationPlayer {
  @override
  Future<void> play(String audioPath) async {}

  @override
  Future<void> stop() async {}
}

Phrase _phrase(String target) => Phrase(
  id: 1,
  source: 'Source',
  target: target,
  rating: 3,
  isNew: false,
  audioPath: '/audio/phrase.mp3',
);

void main() {
  late PronunciationController pronunciation;

  setUp(() {
    pronunciation = PronunciationController(
      player: _SilentPronunciationPlayer(),
    );
  });

  tearDown(() {
    pronunciation.dispose();
  });

  test('reports unavailable when there are no accented phrases', () {
    final controller = AccentsController(
      phrases: [_phrase('Egy')],
      pronunciation: pronunciation,
    );
    addTearDown(controller.dispose);

    expect(controller.phase, AccentsPhase.unavailable);
    expect(controller.currentLetterData, isNull);
    expect(controller.next(), isFalse);
  });

  test('validates drops and advances only after solving', () {
    final controller = AccentsController(
      phrases: [_phrase('Kettő')],
      pronunciation: pronunciation,
    );
    addTearDown(controller.dispose);

    final hiddenLetter = controller.currentLetterData!
        .expand((word) => word)
        .singleWhere((letter) => !letter.isRevealed);

    expect(controller.phase, AccentsPhase.solving);
    expect(controller.next(), isFalse);

    controller.onDrop(dragTargetId: hiddenLetter.id, draggableLetter: 'Á');
    expect(hiddenLetter.isRevealed, isFalse);
    expect(controller.phase, AccentsPhase.solving);

    controller.onDrop(
      dragTargetId: hiddenLetter.id,
      draggableLetter: hiddenLetter.letter,
    );
    expect(hiddenLetter.isRevealed, isTrue);
    expect(controller.phase, AccentsPhase.solved);

    expect(controller.next(), isTrue);
    expect(controller.phase, AccentsPhase.completed);
    expect(controller.currentLetterData, isNull);
    expect(controller.next(), isFalse);
  });

  test('builds letters from grapheme clusters consistently', () {
    final controller = AccentsController(
      phrases: [_phrase('😀Á')],
      pronunciation: pronunciation,
    );
    addTearDown(controller.dispose);

    final letters = controller.currentLetterData!.single;

    expect(letters.map((letter) => letter.letter), ['😀', 'Á']);
    expect(letters.map((letter) => letter.isRevealed), [isTrue, isFalse]);
    expect(letters.map((letter) => letter.id).toSet(), hasLength(2));
    expect(controller.phase, AccentsPhase.solving);
  });
}
