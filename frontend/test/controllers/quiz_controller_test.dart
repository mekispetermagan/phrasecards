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
  Phrase(
    id: 1,
    source: 'New',
    target: 'Új',
    rating: 3,
    isNew: false,
    audioPath: null,
  ),
  Phrase(
    id: 2,
    source: 'Known one',
    target: 'Ismert egy',
    rating: 3,
    isNew: true,
    audioPath: null,
  ),
  Phrase(
    id: 3,
    source: 'Known two',
    target: 'Ismert kettő',
    rating: 3,
    isNew: true,
    audioPath: null,
  ),
  Phrase(
    id: 4,
    source: 'Known three',
    target: 'Ismert három',
    rating: 3,
    isNew: true,
    audioPath: null,
  ),
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
        viewStore: await _store({1: 0, 2: 4, 3: 4, 4: 4}),
        pronunciation: pronunciation,
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
        viewStore: await _store({1: 3, 2: 0, 3: 0, 4: 0}),
        pronunciation: pronunciation,
      );
      addTearDown(controller.dispose);
      addTearDown(pronunciation.dispose);

      expect(controller.currentQuestion, isNull);
      await controller.submit(0);
      expect(controller.score, 0);
    },
  );
}
