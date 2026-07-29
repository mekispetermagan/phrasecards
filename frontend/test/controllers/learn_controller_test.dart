import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordcards/audio/pronunciation_player.dart';
import 'package:wordcards/controllers/learn_controller.dart';
import 'package:wordcards/controllers/pronunciation_controller.dart';
import 'package:wordcards/models/phrase.dart';

class FakePronunciationPlayer implements PronunciationPlayer {
  final Completer<void> playback = Completer<void>();
  final List<String> paths = [];

  @override
  Future<void> play(String audioPath) {
    paths.add(audioPath);
    return playback.future;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  const phrase = Phrase(
    id: 3,
    source: 'Thank you',
    target: 'Köszönöm',
    rating: 3,
    isNew: false,
    audioPath: '/audio/phrase-3-hash.mp3',
  );

  test(
    'exposes playback progress and delegates the backend audio path',
    () async {
      final player = FakePronunciationPlayer();
      final pronunciation = PronunciationController(player: player);
      final controller = LearnController(
        phrases: [phrase],
        pronunciation: pronunciation,
      );
      addTearDown(controller.dispose);
      addTearDown(pronunciation.dispose);

      final playback = controller.playAudio();
      expect(controller.pronunciationData.isPlaying, isTrue);
      expect(player.paths, ['/audio/phrase-3-hash.mp3']);

      player.playback.complete();
      await playback;

      expect(controller.pronunciationData.isPlaying, isFalse);
      expect(controller.pronunciationData.error, isNull);
    },
  );

  test('phrases without audio remain fully usable', () async {
    final player = FakePronunciationPlayer();
    final pronunciation = PronunciationController(player: player);
    final controller = LearnController(
      phrases: [
        const Phrase(
          id: 4,
          source: 'Missing',
          target: 'Hiányzik',
          rating: 3,
          isNew: false,
          audioPath: null,
        ),
      ],
      pronunciation: pronunciation,
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    await controller.playAudio();

    expect(player.paths, isEmpty);
    controller.turnCard();
    expect(controller.cardIsTurned, isTrue);
  });
}
