import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/learn_controller.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';
import 'package:phrasecards/models/learn.dart';
import 'package:phrasecards/models/phrase.dart';
import 'package:phrasecards/storage/phrase_view_store.dart';

class _FakePronunciationPlayer implements PronunciationPlayer {
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

class _MemoryPhraseViewRepository implements PhraseViewRepository {
  Map<int, int> counts;
  final saved = <Map<int, int>>[];

  _MemoryPhraseViewRepository([Map<int, int>? counts])
    : counts = Map.of(counts ?? {});

  @override
  Future<Map<int, int>> load() async => Map.of(counts);

  @override
  Future<void> save(Map<int, int> viewCounts) async {
    counts = Map.of(viewCounts);
    saved.add(Map.of(viewCounts));
  }
}

Phrase _phrase(int id, {String? source, String? target, String? audioPath}) =>
    Phrase(
      id: id,
      source: source ?? 'Source $id',
      target: target ?? 'Target $id',
      rating: 3,
      isNew: true,
      audioPath: audioPath,
    );

Future<PhraseViewStore> _store([Map<int, int>? counts]) async {
  final store = PhraseViewStore(_MemoryPhraseViewRepository(counts));
  await store.load();
  return store;
}

void main() {
  test(
    'exposes playback progress and delegates the backend audio path',
    () async {
      final player = _FakePronunciationPlayer();
      final pronunciation = PronunciationController(player: player);
      final controller = LearnController(
        phrases: [_phrase(3, audioPath: '/audio/phrase.mp3')],
        pronunciation: pronunciation,
        viewStore: await _store(),
      );
      addTearDown(controller.dispose);
      addTearDown(pronunciation.dispose);

      final playback = controller.playAudio();
      expect(controller.pronunciationData!.isPlaying, isTrue);
      expect(player.paths, ['/audio/phrase.mp3']);

      player.playback.complete();
      await playback;

      expect(controller.pronunciationData!.isPlaying, isFalse);
      expect(controller.pronunciationData!.error, isNull);
    },
  );

  test('phrases without audio remain fully usable', () async {
    final player = _FakePronunciationPlayer();
    final pronunciation = PronunciationController(player: player);
    final controller = LearnController(
      phrases: [_phrase(4)],
      pronunciation: pronunciation,
      viewStore: await _store(),
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    await controller.playAudio();
    expect(player.paths, isEmpty);

    controller.turnCard();
    expect(controller.cardIsTurned, isTrue);
  });

  test('counts completed views and keeps New through three views', () async {
    final repository = _MemoryPhraseViewRepository();
    final store = PhraseViewStore(repository);
    await store.load();
    final pronunciation = PronunciationController(
      player: _FakePronunciationPlayer(),
    );
    final controller = LearnController(
      phrases: [_phrase(7)],
      pronunciation: pronunciation,
      viewStore: store,
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    expect(controller.isCurrentPhraseNew, isTrue);
    for (var views = 1; views <= 3; views++) {
      await controller.next();
      expect(store.viewsFor(7), views);
      expect(controller.isCurrentPhraseNew, isTrue);
    }

    await controller.next();
    expect(store.viewsFor(7), 4);
    expect(controller.isCurrentPhraseNew, isFalse);
    expect(repository.saved, hasLength(4));
  });

  test('merges selected groups and puts locally new phrases first', () async {
    final pronunciation = PronunciationController(
      player: _FakePronunciationPlayer(),
    );
    final controller = LearnController(
      phrases: [_phrase(1), _phrase(2), _phrase(3), _phrase(4)],
      pronunciation: pronunciation,
      viewStore: await _store({1: 0, 2: 4, 3: 13, 4: 25}),
      random: Random(1),
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    expect(controller.currentPhrase!.id, 1);

    controller.setSelectedGroups({
      PhraseGroup.practiced,
      PhraseGroup.established,
    });
    expect({3, 4}, contains(controller.currentPhrase!.id));

    controller.setSelectedGroups({PhraseGroup.practiced});
    expect(controller.currentPhrase!.id, 3);

    controller.setSelectedGroups({PhraseGroup.learning});
    expect(controller.currentPhrase!.id, 1);
  });

  test('shows no phrase when selected groups contain no matches', () async {
    final pronunciation = PronunciationController(
      player: _FakePronunciationPlayer(),
    );
    final controller = LearnController(
      phrases: [_phrase(1)],
      pronunciation: pronunciation,
      viewStore: await _store(),
    );
    addTearDown(controller.dispose);
    addTearDown(pronunciation.dispose);

    controller.setSelectedGroups({PhraseGroup.established});

    expect(controller.currentPhrase, isNull);
    expect(controller.pronunciationData, isNull);
  });
}
