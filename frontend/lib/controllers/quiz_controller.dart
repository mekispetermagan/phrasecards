import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/phrase.dart';
import '../models/pronunciation.dart';
import '../models/quiz.dart';
import '../storage/phrase_view_store.dart';
import 'pronunciation_controller.dart';

enum _QuizPhase { guessing, feedbackCorrect, feedbackWrong }

class QuizController extends ChangeNotifier {
  static const int _numberOfOptions = 4;

  final List<Phrase> _phrases;
  final PhraseViewStore _viewStore;
  final PronunciationController _pronunciation;
  final Future<void> Function(String assetPath) _playFeedback;
  final Duration _feedbackDuration;
  final Random _random;

  int _attemptCount = 0;
  int _score = 0;
  QuizQuestion? _currentQuestion;
  int? _correctHighlightIndex;
  int? _wrongHighlightIndex;
  _QuizPhase _phase = _QuizPhase.guessing;
  bool _showPronunciationButtons = false;
  bool _disposed = false;

  QuizController({
    required List<Phrase> phrases,
    required PhraseViewStore phraseViewStore,
    required PronunciationController pronunciationController,
    required Future<void> Function(String assetPath) feedbackPlayer,
    Duration minimumFeedbackDuration = const Duration(seconds: 1),
    Random? random,
  }) : _phrases = List.unmodifiable(phrases),
       _viewStore = phraseViewStore,
       _pronunciation = pronunciationController,
       _playFeedback = feedbackPlayer,
       _feedbackDuration = minimumFeedbackDuration,
       _random = random ?? Random() {
    _generateQuestion();
  }

  List<Phrase> get _questionPhrases =>
      _phrases.where((phrase) => _viewStore.viewsFor(phrase.id) > 3).toList();

  Phrase? get currentPhrase {
    final questionPhrases = _questionPhrases;
    if (questionPhrases.isEmpty) return null;
    return questionPhrases[_attemptCount % questionPhrases.length];
  }

  QuizQuestion? get currentQuestion => _currentQuestion;
  int get attemptCount => _attemptCount;
  int get score => _score;
  int? get correctHighlightIndex => _correctHighlightIndex;
  int? get wrongHighlightIndex => _wrongHighlightIndex;
  bool get showPronunciationButtons => _showPronunciationButtons;
  Future<void> Function(int)? get submit =>
      _phase == _QuizPhase.guessing && _currentQuestion != null
      ? _submit
      : null;

  List<PronunciationData> get optionPronunciations => [
    for (final option in _currentQuestion?.options ?? const <QuizOption>[])
      _pronunciation.dataFor(option.audioPath),
  ];

  Future<void> playOptionAudio(int optionIndex) {
    final question = _currentQuestion;
    if (question == null ||
        optionIndex < 0 ||
        optionIndex >= question.options.length) {
      return Future.value();
    }
    return _pronunciation.play(question.options[optionIndex].audioPath);
  }

  void open() {
    _attemptCount = 0;
    _score = 0;
    _correctHighlightIndex = null;
    _wrongHighlightIndex = null;
    _phase = _QuizPhase.guessing;
    _generateQuestion();
  }

  void setShowPronunciationButtons(bool value) {
    if (_showPronunciationButtons == value) return;
    _showPronunciationButtons = value;
    notifyListeners();
  }

  Future<void> _submit(int guessIndex) async {
    if (_phase != _QuizPhase.guessing) return;
    final question = _currentQuestion;
    if (question == null) return;
    RangeError.checkValidIndex(guessIndex, question.options, 'guessIndex');

    final String feedbackPath;
    if (guessIndex == question.correctIndex) {
      _phase = _QuizPhase.feedbackCorrect;
      _score++;
      _correctHighlightIndex = guessIndex;
      feedbackPath = 'assets/audio/correct.mp3';
    } else {
      _phase = _QuizPhase.feedbackWrong;
      _wrongHighlightIndex = guessIndex;
      feedbackPath = 'assets/audio/wrong.mp3';
    }
    notifyListeners();

    await Future.wait([
      _playFeedbackSafely(feedbackPath),
      Future<void>.delayed(_feedbackDuration),
    ]);
    if (_disposed) return;
    _phase = _QuizPhase.guessing;
    _correctHighlightIndex = null;
    _wrongHighlightIndex = null;
    _next();
  }

  Future<void> _playFeedbackSafely(String path) async {
    try {
      await _playFeedback(path);
    } catch (_) {
      // Audio feedback is optional; playback failure must not stop the quiz.
    }
  }

  void _next() {
    _attemptCount++;
    _generateQuestion();
    _phase = _QuizPhase.guessing;
    notifyListeners();
  }

  void _generateQuestion() {
    final phrase = currentPhrase;
    _currentQuestion = phrase == null
        ? null
        : QuizQuestion.fromPool(
            phrase: phrase,
            numberOfOptions: _numberOfOptions,
            distractorPool: _phrases,
            random: _random,
          );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
