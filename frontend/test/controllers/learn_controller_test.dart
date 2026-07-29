import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordcards/api/api.dart';
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

class FakePhraseProgressApi implements PhraseProgressApi {
  final bool succeeds;
  final List<int> markedIds = [];

  FakePhraseProgressApi({this.succeeds = true});

  @override
  Future<bool> markPhraseSeen(int phraseId) async {
    markedIds.add(phraseId);
    return succeeds;
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
      final player = FakePronunciationPlayer();
      final pronunciation = PronunciationController(player: player);
      final phraseProgressApi = FakePhraseProgressApi();
      final controller = LearnController(
        phrases: [phrase],
        pronunciation: pronunciation,
        progressApi: phraseProgressApi,
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
    final phraseProgressApi = FakePhraseProgressApi();
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
      progressApi: phraseProgressApi,
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    await controller.playAudio();

    expect(player.paths, isEmpty);
    controller.turnCard();
    expect(controller.cardIsTurned, isTrue);
  });

  test('marks a new phrase seen locally before advancing', () async {
    final pronunciation = PronunciationController(
      player: FakePronunciationPlayer(),
    );
    final phraseProgressApi = FakePhraseProgressApi();
    final phrases = [
      const Phrase(
        id: 7,
        source: 'New',
        target: 'Új',
        rating: 3,
        isNew: true,
        audioPath: null,
      ),
      phrase,
    ];
    final controller = LearnController(
      phrases: phrases,
      pronunciation: pronunciation,
      progressApi: phraseProgressApi,
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);
    await controller.next();
    expect(phraseProgressApi.markedIds, [7]);
    expect(phrases.first.isNew, isFalse);
    expect(controller.currentPhrase, phrase);
  });

  test('advances but keeps new state when marking seen fails', () async {
    final pronunciation = PronunciationController(
      player: FakePronunciationPlayer(),
    );
    final phraseProgressApi = FakePhraseProgressApi(succeeds: false);
    final phrases = [
      const Phrase(
        id: 7,
        source: 'New',
        target: 'Új',
        rating: 3,
        isNew: true,
        audioPath: null,
      ),
      phrase,
    ];
    final controller = LearnController(
      phrases: phrases,
      pronunciation: pronunciation,
      progressApi: phraseProgressApi,
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);
    await controller.next();
    expect(phrases.first.isNew, isTrue);
    expect(controller.currentPhrase, phrase);
  });
}
