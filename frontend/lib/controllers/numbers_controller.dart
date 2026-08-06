import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/number_quiz.dart';

const List<String> numberNames = [
  "egy",
  "kettő",
  "három",
  "négy",
  "öt",
  "hat",
  "hét",
  "nyolc",
  "kilenc",
  "tíz",
];

const List<String> emojis = [
  "🪻",
  "🌸",
  "🍎",
  "🍊",
  "🍇",
  "🐶",
  "🐱",
  "🐰",
  "❤️",
  "⭐",
  "🎁",
  "🌞",
];

enum NumbersState { guessing, feedback }

enum NumberFeedback {
  correct('c'),
  incorrect('w');

  final String assetSuffix;

  const NumberFeedback(this.assetSuffix);
}

class NumbersController extends ChangeNotifier {
  final Future<void> Function(String assetPath) _playFeedback;
  final Random _random;
  final int _upperLimit = numberNames.length;
  final int _numberOfOptions = 3;
  late NumberQuizQuestion _currentQuestion;
  late String _currentEmoji;
  int? _successHighlightIndex;
  int? _failureHighlightIndex;
  NumbersState _state = NumbersState.guessing;
  int _score = 0;

  NumbersController(this._playFeedback, {Random? random})
    : _random = random ?? Random() {
    _nextQuestion();
  }

  int get solution => _currentQuestion.solution;
  List<String> get options => [
    for (int number in _currentQuestion.options) numberNames[number - 1],
  ];
  String get emoji => _currentEmoji;
  int get score => _score;
  int? get successHighlightIndex => _successHighlightIndex;
  int? get failureHighlightIndex => _failureHighlightIndex;
  Future<void> Function(int)? get submit =>
      _state == NumbersState.guessing ? _submit : null;

  String audioPath(int number, NumberFeedback feedback) =>
      'assets/audio/numbers/$number${feedback.assetSuffix}.mp3';

  void _nextQuestion() {
    _state = NumbersState.guessing;
    _failureHighlightIndex = null;
    _successHighlightIndex = null;
    _currentQuestion = NumberQuizQuestion.generate(
      numberOfOptions: _numberOfOptions,
      upperLimit: _upperLimit,
      r: _random,
    );
    _currentEmoji = emojis[_random.nextInt(emojis.length)];
    notifyListeners();
  }

  Future<void> _submit(int guessIndex) async {
    if (_state != NumbersState.guessing) return;
    RangeError.checkValidIndex(
      guessIndex,
      _currentQuestion.options,
      'guessIndex',
    );
    _state = NumbersState.feedback;
    final isCorrect = guessIndex == _currentQuestion.correctIndex;
    if (isCorrect) {
      _score++;
    } else {
      _failureHighlightIndex = guessIndex;
    }
    _successHighlightIndex = _currentQuestion.correctIndex;
    notifyListeners();

    final guessedNumber = _currentQuestion.options[guessIndex];
    final feedback = isCorrect
        ? NumberFeedback.correct
        : NumberFeedback.incorrect;
    try {
      await _playFeedback(audioPath(guessedNumber, feedback));
    } catch (_) {
      // Audio feedback is optional; a missing asset must not stop the game.
    } finally {
      _nextQuestion();
    }
  }
}
