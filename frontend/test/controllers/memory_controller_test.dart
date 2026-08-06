import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/controllers/memory_controller.dart';
import 'package:phrasecards/models/memory.dart';
import 'package:phrasecards/models/phrase.dart';

Phrase _phrase(int id, String target) => Phrase(
  id: id,
  source: 'Source $id',
  target: target,
  audioPath: '/audio/$id.mp3',
);

Future<void> _ignorePronunciation(String? _) async {}

void main() {
  test('requires nine distinct normalized targets', () {
    final controller = MemoryController(
      phrases: [
        for (int i = 0; i < 8; i++) _phrase(i, 'Target $i'),
        _phrase(9, '  TARGET 0  '),
      ],
      pronunciationPlayer: _ignorePronunciation,
      random: Random(1),
    );
    addTearDown(controller.dispose);

    expect(controller.canPlay, isFalse);
    expect(controller.cards, isEmpty);
  });

  test('builds nine unambiguous shuffled pairs', () {
    final controller = MemoryController(
      phrases: [
        for (int i = 0; i < 10; i++) _phrase(i, 'Target $i'),
        _phrase(20, ' target 0 '),
      ],
      pronunciationPlayer: _ignorePronunciation,
      random: Random(2),
    );
    addTearDown(controller.dispose);

    expect(controller.cards, hasLength(18));
    expect(
      controller.cards
          .where((card) => card.side == MemoryCardSide.target)
          .map((card) => card.text.trim().toLowerCase())
          .toSet(),
      hasLength(9),
    );
    for (int pairId = 0; pairId < MemoryController.pairCount; pairId++) {
      expect(
        controller.cards.where((card) => card.pairId == pairId),
        hasLength(2),
      );
    }
  });

  test(
    'turns a mismatch back over and ignores input while evaluating',
    () async {
      final controller = MemoryController(
        phrases: [for (int i = 0; i < 9; i++) _phrase(i, 'Target $i')],
        pronunciationPlayer: _ignorePronunciation,
        random: Random(3),
        revealDuration: Duration.zero,
      );
      addTearDown(controller.dispose);

      final first = controller.cards.first;
      final second = controller.cards.firstWhere(
        (card) => card.pairId != first.pairId,
      );
      final ignored = controller.cards.firstWhere(
        (card) => card.cardId != first.cardId && card.cardId != second.cardId,
      );

      await controller.select(first.cardId);
      final evaluation = controller.select(second.cardId);
      await controller.select(ignored.cardId);
      expect(
        controller.cards
            .singleWhere((card) => card.cardId == ignored.cardId)
            .state,
        MemoryCardState.hidden,
      );
      await evaluation;

      expect(
        controller.cards
            .where(
              (card) =>
                  card.cardId == first.cardId || card.cardId == second.cardId,
            )
            .every((card) => card.state == MemoryCardState.hidden),
        isTrue,
      );
    },
  );

  test('marks a matching pair and can start a fresh game', () async {
    final controller = MemoryController(
      phrases: [for (int i = 0; i < 9; i++) _phrase(i, 'Target $i')],
      pronunciationPlayer: _ignorePronunciation,
      random: Random(4),
      revealDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    final first = controller.cards.first;
    final second = controller.cards.firstWhere(
      (card) => card.pairId == first.pairId && card.cardId != first.cardId,
    );
    await controller.select(first.cardId);
    await controller.select(second.cardId);

    expect(
      controller.cards
          .where((card) => card.pairId == first.pairId)
          .every((card) => card.isMatched),
      isTrue,
    );

    controller.startNewGame();
    expect(controller.cards.every((card) => !card.isFaceUp), isTrue);
  });

  test('pronounces target cards but not source cards', () async {
    final playedPaths = <String?>[];
    final controller = MemoryController(
      phrases: [for (int i = 0; i < 9; i++) _phrase(i, 'Target $i')],
      pronunciationPlayer: (path) async => playedPaths.add(path),
      random: Random(5),
      revealDuration: Duration.zero,
    );
    addTearDown(controller.dispose);

    final source = controller.cards.firstWhere(
      (card) => card.side == MemoryCardSide.source,
    );
    final target = controller.cards.firstWhere(
      (card) =>
          card.side == MemoryCardSide.target && card.pairId != source.pairId,
    );

    await controller.select(source.cardId);
    await controller.select(target.cardId);

    expect(playedPaths, [target.audioPath]);
  });
}
