import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/phrasebuilding_controller.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';
import 'package:phrasecards/models/phrase.dart';
import 'package:phrasecards/models/phrasebuilding_state.dart';

Phrase _phrase(int id, String target) =>
    Phrase(id: id, source: 'Source $id', target: target, audioPath: null);

List<Phrase> get _phrases => [
  _phrase(1, 'one'),
  _phrase(2, 'two'),
  _phrase(3, 'three'),
  _phrase(4, 'four'),
];

class _RecordingPronunciationPlayer implements PronunciationPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String audioPath) async => playedPaths.add(audioPath);

  @override
  Future<void> stop() async {}
}

PhraseBuildingController _controller({
  Random? random,
  _RecordingPronunciationPlayer? pronunciationPlayer,
  Future<void> Function(String path)? feedbackPlayer,
}) {
  final pronunciation = PronunciationController(
    player: pronunciationPlayer ?? _RecordingPronunciationPlayer(),
  );
  addTearDown(pronunciation.dispose);
  return PhraseBuildingController(
    phrases: _phrases,
    pronunciationController: pronunciation,
    feedbackPlayer: feedbackPlayer ?? (_) async {},
    minimumFeedbackDuration: Duration.zero,
    random: random,
  );
}

void main() {
  test('supports a distractor pool smaller than the requested count', () {
    for (var seed = 0; seed < 20; seed++) {
      final controller = _controller(random: Random(seed));

      expect(controller.sourcePool, isNotEmpty);
      controller.dispose();
    }
  });

  test('moves tiles between the source and target pools', () {
    final controller = _controller(random: Random(1));
    addTearDown(controller.dispose);
    final tile = controller.sourcePool.first;

    controller.move!(tile);
    expect(controller.sourcePool, isNot(contains(tile)));
    expect(controller.targetPool, contains(tile));

    controller.move!(tile);
    expect(controller.sourcePool, contains(tile));
    expect(controller.targetPool, isNot(contains(tile)));
  });

  test('exposes pools as unmodifiable views', () {
    final controller = _controller(random: Random(1));
    addTearDown(controller.dispose);

    expect(() => controller.sourcePool.clear(), throwsUnsupportedError);
    expect(() => controller.targetPool.clear(), throwsUnsupportedError);
  });

  test('shows failure feedback and then accepts corrections', () async {
    final playedPaths = <String>[];
    final controller = _controller(
      random: Random(1),
      feedbackPlayer: (path) async => playedPaths.add(path),
    );
    addTearDown(controller.dispose);

    controller.move!(controller.sourcePool.first);
    controller.move!(controller.sourcePool.first);
    final submission = controller.submit!();

    expect(controller.state, PhraseBuildingState.failureFeedback);
    expect(controller.move, isNull);
    expect(controller.submit, isNull);
    expect(playedPaths, ['assets/audio/wrong.mp3']);

    await submission;
    expect(controller.state, PhraseBuildingState.guessing);
    expect(controller.move, isNotNull);
  });

  test('does not notify or advance after disposal during feedback', () async {
    final controller = _controller(random: Random(1));
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.move!(controller.sourcePool.first);

    final submission = controller.submit!();
    final notificationsBeforeDisposal = notifications;
    controller.dispose();
    await submission;

    expect(notifications, notificationsBeforeDisposal);
  });

  test('plays the current phrase pronunciation', () async {
    final player = _RecordingPronunciationPlayer();
    final phrasesWithAudio = [
      for (final phrase in _phrases)
        Phrase(
          id: phrase.id,
          source: phrase.source,
          target: phrase.target,
          audioPath: '/audio/${phrase.id}.mp3',
        ),
    ];
    final pronunciation = PronunciationController(player: player);
    addTearDown(pronunciation.dispose);
    final controller = PhraseBuildingController(
      phrases: phrasesWithAudio,
      pronunciationController: pronunciation,
      feedbackPlayer: (_) async {},
      minimumFeedbackDuration: Duration.zero,
      random: Random(1),
    );
    addTearDown(controller.dispose);

    final currentPath = controller.pronunciation.path;
    await controller.playAudio();

    expect(currentPath, isNotNull);
    expect(player.playedPaths, [currentPath]);
  });

  test('continues after feedback playback fails', () async {
    final controller = _controller(
      random: Random(1),
      feedbackPlayer: (_) => Future<void>.error(StateError('missing asset')),
    );
    addTearDown(controller.dispose);
    controller.move!(controller.sourcePool.first);
    controller.move!(controller.sourcePool.first);

    await controller.submit!();

    expect(controller.state, PhraseBuildingState.guessing);
    expect(controller.submit, isNotNull);
  });

  test('plays correct feedback and advances to the next phrase', () async {
    final phrasesWithAudio = [
      for (final phrase in _phrases)
        Phrase(
          id: phrase.id,
          source: phrase.source,
          target: phrase.target,
          audioPath: '/audio/${phrase.id}.mp3',
        ),
    ];
    final pronunciation = PronunciationController(
      player: _RecordingPronunciationPlayer(),
    );
    addTearDown(pronunciation.dispose);
    final playedPaths = <String>[];
    final controller = PhraseBuildingController(
      phrases: phrasesWithAudio,
      pronunciationController: pronunciation,
      feedbackPlayer: (path) async => playedPaths.add(path),
      minimumFeedbackDuration: Duration.zero,
      random: Random(1),
    );
    addTearDown(controller.dispose);
    final initialAudioPath = controller.pronunciation.path!;
    final phraseId = int.parse(
      initialAudioPath.split('/').last.split('.').first,
    );
    final solution = phrasesWithAudio
        .singleWhere((phrase) => phrase.id == phraseId)
        .target
        .toUpperCase();
    controller.move!(
      controller.sourcePool.firstWhere((tile) => tile.word == solution),
    );

    await controller.submit!();

    expect(playedPaths, ['assets/audio/correct.mp3']);
    expect(controller.pronunciation.path, isNot(initialAudioPath));
  });
}
