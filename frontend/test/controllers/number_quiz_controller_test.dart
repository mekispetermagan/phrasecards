import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/controllers/number_quiz_controller.dart';

void main() {
  test(
    'plays correct feedback and waits before generating the next question',
    () async {
      final playback = Completer<void>();
      String? playedPath;
      final controller = NumberQuizController((path) {
        playedPath = path;
        return playback.future;
      });
      addTearDown(controller.dispose);

      final initialSolution = controller.solution;
      final correctIndex = controller.options.indexOf(
        hungarianNumberNames[initialSolution - 1],
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
    final controller = NumberQuizController((path) async {
      playedPath = path;
    });
    addTearDown(controller.dispose);

    final correctIndex = controller.options.indexOf(
      hungarianNumberNames[controller.solution - 1],
    );
    final wrongIndex = correctIndex == 0 ? 1 : 0;
    final guessedNumber =
        hungarianNumberNames.indexOf(controller.options[wrongIndex]) + 1;

    controller.submit!(wrongIndex);
    await Future<void>.delayed(Duration.zero);

    expect(playedPath, 'assets/audio/numbers/${guessedNumber}w.mp3');
    expect(controller.score, 0);
  });

  test('continues with a new question when audio playback fails', () async {
    final controller = NumberQuizController(
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

  test('uses an injected random source for repeatable questions', () {
    final first = NumberQuizController((_) async {}, random: Random(123));
    final second = NumberQuizController((_) async {}, random: Random(123));
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    expect(first.solution, second.solution);
    expect(first.options, second.options);
    expect(first.emoji, second.emoji);
  });

  test('ignores a stale second submission while feedback is playing', () async {
    final playback = Completer<void>();
    var playCount = 0;
    final controller = NumberQuizController((_) {
      playCount++;
      return playback.future;
    }, random: Random(1));
    addTearDown(controller.dispose);

    final correctIndex = controller.options.indexOf(
      hungarianNumberNames[controller.solution - 1],
    );
    final staleSubmit = controller.submit!;

    final firstSubmission = staleSubmit(correctIndex);
    await staleSubmit(correctIndex);

    expect(playCount, 1);
    expect(controller.score, 1);

    playback.complete();
    await firstSubmission;
  });

  test('rejects invalid option indices without changing state', () async {
    var played = false;
    final controller = NumberQuizController((_) async {
      played = true;
    });
    addTearDown(controller.dispose);

    await expectLater(controller.submit!(-1), throwsRangeError);

    expect(played, isFalse);
    expect(controller.score, 0);
    expect(controller.submit, isNotNull);
    expect(controller.successHighlightIndex, isNull);
    expect(controller.failureHighlightIndex, isNull);
  });

  test('does not generate or notify after disposal during playback', () async {
    final playback = Completer<void>();
    final controller = NumberQuizController((_) => playback.future);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final submission = controller.submit!(0);
    expect(notifications, 1);

    controller.dispose();
    playback.complete();
    await submission;

    expect(notifications, 1);
  });
}
