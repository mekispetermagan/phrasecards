import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/controllers/numbers_controller.dart';

void main() {
  test(
    'plays correct feedback and waits before generating the next question',
    () async {
      final playback = Completer<void>();
      String? playedPath;
      final controller = NumbersController((path) {
        playedPath = path;
        return playback.future;
      });
      addTearDown(controller.dispose);

      final initialSolution = controller.solution;
      final correctIndex = controller.options.indexOf(
        numberNames[initialSolution - 1],
      );

      controller.submit!(correctIndex);
      await Future<void>.delayed(Duration.zero);

      expect(playedPath, 'assets/audio/numbers/${initialSolution}c.mp3');
      expect(controller.score, 1);
      expect(controller.successHighlightIndex, correctIndex);
      expect(controller.submit, isNull);
      expect(controller.solution, initialSolution);

      playback.complete();
      await Future<void>.delayed(Duration.zero);

      expect(controller.submit, isNotNull);
      expect(controller.successHighlightIndex, isNull);
    },
  );

  test('plays feedback for the incorrectly guessed number', () async {
    String? playedPath;
    final controller = NumbersController((path) async {
      playedPath = path;
    });
    addTearDown(controller.dispose);

    final correctIndex = controller.options.indexOf(
      numberNames[controller.solution - 1],
    );
    final wrongIndex = correctIndex == 0 ? 1 : 0;
    final guessedNumber =
        numberNames.indexOf(controller.options[wrongIndex]) + 1;

    controller.submit!(wrongIndex);
    await Future<void>.delayed(Duration.zero);

    expect(playedPath, 'assets/audio/numbers/${guessedNumber}w.mp3');
    expect(controller.score, 0);
  });

  test('continues with a new question when audio playback fails', () async {
    final controller = NumbersController(
      (_) => Future<void>.error(StateError('missing asset')),
    );
    addTearDown(controller.dispose);

    controller.submit!(0);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.submit, isNotNull);
    expect(controller.successHighlightIndex, isNull);
    expect(controller.failureHighlightIndex, isNull);
  });
}
