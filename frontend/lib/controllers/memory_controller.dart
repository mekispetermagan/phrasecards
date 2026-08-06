import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/memory.dart';
import '../models/phrase.dart';

class MemoryController extends ChangeNotifier {
  static const int pairCount = 9;

  final List<Phrase> _phrases;
  final Random _random;
  final Duration revealDuration;
  final Future<void> Function(String? audioPath) _playPronunciation;

  List<MemoryCardData> _cards = const [];
  int? _firstCardId;
  int _revealCounter = 0;
  bool _isEvaluating = false;
  bool _disposed = false;

  MemoryController({
    required List<Phrase> phrases,
    required Future<void> Function(String? audioPath) pronunciationPlayer,
    Random? random,
    this.revealDuration = const Duration(milliseconds: 900),
  }) : _phrases = List.unmodifiable(phrases),
       _playPronunciation = pronunciationPlayer,
       _random = random ?? Random() {
    startNewGame(notify: false);
  }

  List<MemoryCardData> get cards => List.unmodifiable(_cards);
  bool get canPlay => _cards.length == pairCount * 2;
  bool get isComplete => canPlay && _cards.every((card) => card.isMatched);

  void startNewGame({bool notify = true}) {
    final Map<String, List<Phrase>> phrasesByTarget = {};
    for (final phrase in _phrases) {
      phrasesByTarget
          .putIfAbsent(_normalize(phrase.target), () => [])
          .add(phrase);
    }

    final groups = phrasesByTarget.values.toList()..shuffle(_random);
    if (groups.length < pairCount) {
      _cards = const [];
    } else {
      final selected = [
        for (final group in groups.take(pairCount))
          group[_random.nextInt(group.length)],
      ];

      _cards = [
        for (int pairId = 0; pairId < selected.length; pairId++) ...[
          MemoryCardData(
            cardId: pairId * 2,
            pairId: pairId,
            text: selected[pairId].source,
            audioPath: null,
            side: MemoryCardSide.source,
          ),
          MemoryCardData(
            cardId: pairId * 2 + 1,
            pairId: pairId,
            text: selected[pairId].target,
            audioPath: selected[pairId].audioPath,
            side: MemoryCardSide.target,
          ),
        ],
      ]..shuffle(_random);
    }

    _firstCardId = null;
    _revealCounter = 0;
    _isEvaluating = false;
    if (notify) notifyListeners();
  }

  Future<void> select(int cardId) async {
    if (_isEvaluating || !canPlay) return;

    final selectedIndex = _cards.indexWhere((card) => card.cardId == cardId);
    if (selectedIndex == -1 || _cards[selectedIndex].isFaceUp) return;
    final selectedCard = _cards[selectedIndex];

    _revealCounter++;
    _setState(cardId, MemoryCardState.revealed, revealOrder: _revealCounter);
    if (selectedCard.side == MemoryCardSide.target) {
      unawaited(_playPronunciation(selectedCard.audioPath));
    }
    final firstCardId = _firstCardId;
    if (firstCardId == null) {
      _firstCardId = cardId;
      notifyListeners();
      return;
    }

    _isEvaluating = true;
    notifyListeners();
    await Future<void>.delayed(revealDuration);
    if (_disposed) return;

    final first = _cardById(firstCardId);
    final second = _cardById(cardId);
    final nextState = first.pairId == second.pairId
        ? MemoryCardState.matched
        : MemoryCardState.hidden;
    _setState(firstCardId, nextState);
    _setState(cardId, nextState);
    _firstCardId = null;
    _isEvaluating = false;
    notifyListeners();
  }

  MemoryCardData _cardById(int cardId) =>
      _cards.firstWhere((card) => card.cardId == cardId);

  void _setState(int cardId, MemoryCardState state, {int? revealOrder}) {
    _cards = [
      for (final card in _cards)
        if (card.cardId == cardId)
          card.copyWith(state: state, revealOrder: revealOrder)
        else
          card,
    ];
  }

  String _normalize(String target) =>
      target.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
