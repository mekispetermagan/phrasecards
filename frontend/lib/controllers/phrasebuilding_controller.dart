import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/phrasebuilding_state.dart';
import '../models/phrasebuilding_tile.dart';
import '../models/phrase.dart';
import '../utils/string_utils.dart';

class PhraseBuildingController extends ChangeNotifier {
  final Random _random;
  final _sourcePool = <PhraseBuildingTile>[];
  final _targetPool = <PhraseBuildingTile>[];
  late final List<Phrase> _phrases;
  final _distractors = <String>[];
  int _counter = 0;
  final _solutionWords = <String>[];
  PhraseBuildingState _state = PhraseBuildingState.guessing;
  bool _disposed = false;

  PhraseBuildingController({required List<Phrase> phrases, Random? random})
    : _random = random ?? Random() {
    _phrases = phrases.shuffled(_random);
    _distractors.addAll([
      for (final p in _phrases) ...[
        for (final w in toWords(p.target.toUpperCase())) w,
      ],
    ]);
    _generateExercise();
  }

  UnmodifiableListView<PhraseBuildingTile> get sourcePool =>
      UnmodifiableListView(_sourcePool);
  UnmodifiableListView<PhraseBuildingTile> get targetPool =>
      UnmodifiableListView(_targetPool);

  PhraseBuildingState get state => _state;

  Future<void> Function()? get submit =>
      _state == PhraseBuildingState.guessing && _targetPool.isNotEmpty
      ? _submit
      : null;

  void Function(PhraseBuildingTile)? get move =>
      _state == PhraseBuildingState.guessing ? _move : null;

  void _move(PhraseBuildingTile tile) {
    if (_sourcePool.contains(tile)) {
      _sourcePool.remove(tile);
      _targetPool.add(tile);
      notifyListeners();
      return;
    }
    if (_targetPool.contains(tile)) {
      _targetPool.remove(tile);
      _sourcePool.add(tile);
      notifyListeners();
      return;
    }
    notifyListeners();
    return;
  }

  void _generateExercise() {
    _solutionWords
      ..clear()
      ..addAll(toWords(_phrases[_counter].target.toUpperCase()));
    final shuffledDistractors = _distractors.shuffled(_random);
    final distractorCount = min(
      _random.nextInt(3) + 3,
      shuffledDistractors.length,
    );
    final selectedDistractors = shuffledDistractors.take(distractorCount);
    final shuffledWords = [
      ..._solutionWords,
      ...selectedDistractors,
    ].shuffled(_random);
    _sourcePool
      ..clear()
      ..addAll([
        for (final (i, word) in shuffledWords.indexed)
          PhraseBuildingTile(id: i, word: word),
      ]);
    _targetPool.clear();
    notifyListeners();
  }

  Future<void> _submit() async {
    final submittedWords = [for (final tile in _targetPool) tile.word];
    if (listEquals(_solutionWords, submittedWords)) {
      _state = PhraseBuildingState.successFeedback;
      notifyListeners();
      await Future.delayed(Duration(seconds: 1));
      if (_disposed) return;
      _state = PhraseBuildingState.guessing;
      notifyListeners();
      _next();
    } else {
      _state = PhraseBuildingState.failureFeedback;
      notifyListeners();
      await Future.delayed(Duration(seconds: 1));
      if (_disposed) return;
      _state = PhraseBuildingState.guessing;
      notifyListeners();
    }
  }

  void _next() {
    _counter = (_counter + 1) % _phrases.length;
    _generateExercise();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
