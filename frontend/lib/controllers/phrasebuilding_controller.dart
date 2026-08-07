import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/phrasebuilding_state.dart';
import '../models/phrasebuilding_tile.dart';
import '../models/phrase.dart';
import '../models/pronunciation.dart';
import '../utils/string_utils.dart';
import 'pronunciation_controller.dart';

class PhraseBuildingController extends ChangeNotifier {
  final Random _random;
  final PronunciationController _pronunciation;
  final Future<void> Function(String assetPath) _playFeedback;
  final Duration _feedbackDuration;
  final _sourcePool = <PhraseBuildingTile>[];
  final _targetPool = <PhraseBuildingTile>[];
  late final List<Phrase> _phrases;
  final _distractors = <String>[];
  int _counter = 0;
  final _solutionWords = <String>[];
  PhraseBuildingState _state = PhraseBuildingState.guessing;
  bool _disposed = false;

  PhraseBuildingController({
    required List<Phrase> phrases,
    required PronunciationController pronunciationController,
    required Future<void> Function(String assetPath) feedbackPlayer,
    Duration minimumFeedbackDuration = const Duration(seconds: 1),
    Random? random,
  }) : _random = random ?? Random(),
       _pronunciation = pronunciationController,
       _playFeedback = feedbackPlayer,
       _feedbackDuration = minimumFeedbackDuration {
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
  PronunciationData get pronunciation =>
      _pronunciation.dataFor(_phrases[_counter].audioPath);

  Future<bool> Function()? get submit =>
      _state == PhraseBuildingState.guessing && _targetPool.isNotEmpty
      ? _submit
      : null;

  void Function(PhraseBuildingTile)? get move =>
      _state == PhraseBuildingState.guessing ? _move : null;

  Future<void> playAudio() => _pronunciation.play(_phrases[_counter].audioPath);

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

  Future<bool> _submit() async {
    final submittedWords = [for (final tile in _targetPool) tile.word];
    if (listEquals(_solutionWords, submittedWords)) {
      _state = PhraseBuildingState.successFeedback;
      notifyListeners();
      await Future.wait([
        _playFeedbackSafely('assets/audio/correct.mp3'),
        Future<void>.delayed(_feedbackDuration),
      ]);
      if (_disposed) return false;
      _state = PhraseBuildingState.guessing;
      notifyListeners();
      _next();
      return true;
    } else {
      _state = PhraseBuildingState.failureFeedback;
      notifyListeners();
      await Future.wait([
        _playFeedbackSafely('assets/audio/wrong.mp3'),
        Future<void>.delayed(_feedbackDuration),
      ]);
      if (_disposed) return false;
      _state = PhraseBuildingState.guessing;
      notifyListeners();
      return false;
    }
  }

  void _next() {
    _counter = (_counter + 1) % _phrases.length;
    _generateExercise();
  }

  Future<void> _playFeedbackSafely(String path) async {
    try {
      await _playFeedback(path);
    } catch (_) {
      // Audio feedback is optional; playback failure must not stop the exercise.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
