import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';
import 'package:phrasecards/controllers/quiz_controller.dart';
import 'package:phrasecards/models/phrase.dart';
import 'package:phrasecards/storage/phrase_view_store.dart';

class _UnusedPronunciationPlayer implements PronunciationPlayer {
  @override
  Future<void> play(String audioPath) async {}

  @override
  Future<void> stop() async {}
}

class _PhraseViewRepository implements PhraseViewRepository {
  final Map<int, int> counts;

  _PhraseViewRepository(this.counts);

  @override
  Future<Map<int, int>> load() async => Map.of(counts);

  @override
  Future<void> save(Map<int, int> viewCounts) async {}
}

Future<PhraseViewStore> _store(Map<int, int> counts) async {
  final store = PhraseViewStore(_PhraseViewRepository(counts));
  await store.load();
  return store;
}

const phrases = [
  Phrase(id: 1, source: 'New', target: 'Új', audioPath: null),
  Phrase(id: 2, source: 'Known one', target: 'Ismert egy', audioPath: null),
  Phrase(id: 3, source: 'Known two', target: 'Ismert kettő', audioPath: null),
  Phrase(id: 4, source: 'Known three', target: 'Ismert három', audioPath: null),
];

void main() {
  test(
    'uses local views for questions and all phrases as distractors',
    () async {
      final pronunciation = PronunciationController(
        player: _UnusedPronunciationPlayer(),
      );
      final controller = QuizController(
        phrases: phrases,
        phraseViewStore: await _store({1: 0, 2: 4, 3: 4, 4: 4}),
        pronunciationController: pronunciation,
        feedbackPlayer: (_) async {},
        random: Random(1),
      );
      addTearDown(controller.dispose);
      addTearDown(pronunciation.dispose);

      expect(controller.currentQuestion!.source, 'Known one');
      expect(
        controller.currentQuestion!.options.map((option) => option.text),
        contains('Új'),
      );
    },
  );

  test(
    'is unavailable until a phrase has more than three local views',
    () async {
      final pronunciation = PronunciationController(
        player: _UnusedPronunciationPlayer(),
      );
      final controller = QuizController(
        phrases: phrases,
        phraseViewStore: await _store({1: 3, 2: 0, 3: 0, 4: 0}),
        pronunciationController: pronunciation,
        feedbackPlayer: (_) async {},
      );
      addTearDown(controller.dispose);
      addTearDown(pronunciation.dispose);

      expect(controller.currentQuestion, isNull);
      expect(controller.submit, isNull);
      expect(controller.score, 0);
    },
  );

  test('disables repeated submissions while feedback is active', () async {
    final pronunciation = PronunciationController(
      player: _UnusedPronunciationPlayer(),
    );
    final playback = Completer<void>();
    final playedPaths = <String>[];
    final controller = QuizController(
      phrases: phrases,
      phraseViewStore: await _store({1: 4, 2: 4, 3: 4, 4: 4}),
      pronunciationController: pronunciation,
      feedbackPlayer: (path) {
        playedPaths.add(path);
        return playback.future;
      },
      minimumFeedbackDuration: Duration.zero,
      random: Random(2),
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    final correctIndex = controller.currentQuestion!.correctIndex;
    final staleSubmit = controller.submit!;
    final submission = staleSubmit(correctIndex);
    await staleSubmit(correctIndex);

    expect(controller.submit, isNull);
    expect(controller.score, 1);
    expect(controller.correctHighlightIndex, correctIndex);
    expect(playedPaths, ['assets/audio/correct.mp3']);

    playback.complete();
    await submission;

    expect(controller.submit, isNotNull);
    expect(controller.attemptCount, 1);
    expect(controller.correctHighlightIndex, isNull);
  });

  test('wrong feedback failure still advances the quiz', () async {
    final pronunciation = PronunciationController(
      player: _UnusedPronunciationPlayer(),
    );
    final controller = QuizController(
      phrases: phrases,
      phraseViewStore: await _store({1: 4, 2: 4, 3: 4, 4: 4}),
      pronunciationController: pronunciation,
      feedbackPlayer: (_) => Future<void>.error(StateError('missing asset')),
      minimumFeedbackDuration: Duration.zero,
      random: Random(3),
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    final correctIndex = controller.currentQuestion!.correctIndex;
    final wrongIndex = correctIndex == 0 ? 1 : 0;
    await controller.submit!(wrongIndex);

    expect(controller.score, 0);
    expect(controller.attemptCount, 1);
    expect(controller.submit, isNotNull);
    expect(controller.wrongHighlightIndex, isNull);
  });

  test('rejects invalid option indices without entering feedback', () async {
    final pronunciation = PronunciationController(
      player: _UnusedPronunciationPlayer(),
    );
    final controller = QuizController(
      phrases: phrases,
      phraseViewStore: await _store({1: 4, 2: 4, 3: 4, 4: 4}),
      pronunciationController: pronunciation,
      feedbackPlayer: (_) async {},
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    await expectLater(controller.submit!(-1), throwsRangeError);

    expect(controller.submit, isNotNull);
    expect(controller.attemptCount, 0);
    expect(controller.score, 0);
  });

  test('does not advance or notify after disposal during feedback', () async {
    final pronunciation = PronunciationController(
      player: _UnusedPronunciationPlayer(),
    );
    final playback = Completer<void>();
    final controller = QuizController(
      phrases: phrases,
      phraseViewStore: await _store({1: 4, 2: 4, 3: 4, 4: 4}),
      pronunciationController: pronunciation,
      feedbackPlayer: (_) => playback.future,
      minimumFeedbackDuration: Duration.zero,
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    final submission = controller.submit!(0);
    expect(notifications, 1);

    controller.dispose();
    playback.complete();
    await submission;

    expect(notifications, 1);
    expect(controller.attemptCount, 0);
    pronunciation.dispose();
  });
}
