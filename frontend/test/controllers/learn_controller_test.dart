import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordcards/audio/phrase_audio_player.dart';
import 'package:wordcards/controllers/learn_controller.dart';
import 'package:wordcards/models/phrase.dart';

class FakePhraseAudioPlayer implements PhraseAudioPlayer {
  final Completer<void> playback = Completer<void>();
  final List<String> paths = [];

  @override
  Future<void> playPhrase(String audioPath) {
    paths.add(audioPath);
    return playback.future;
  }
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
      final player = FakePhraseAudioPlayer();
      final controller = LearnController(phrases: [phrase], audio: player);
      addTearDown(controller.dispose);

      final playback = controller.playAudio();
      expect(controller.isPlayingAudio, isTrue);
      expect(player.paths, ['/audio/phrase-3-hash.mp3']);

      player.playback.complete();
      await playback;

      expect(controller.isPlayingAudio, isFalse);
      expect(controller.audioError, isNull);
    },
  );

  test('phrases without audio remain fully usable', () async {
    final player = FakePhraseAudioPlayer();
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
      audio: player,
    );
    addTearDown(controller.dispose);

    await controller.playAudio();

    expect(player.paths, isEmpty);
    controller.turnCard();
    expect(controller.cardIsTurned, isTrue);
  });
}
