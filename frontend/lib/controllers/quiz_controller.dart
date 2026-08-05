import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/audio.dart';
import '../models/phrase.dart';
import '../models/pronunciation.dart';
import '../models/quiz.dart';
import '../storage/phrase_view_store.dart';
import 'pronunciation_controller.dart';

enum QuizState { guessing, feedbackCorrect, feedbackWrong }

class QuizController extends ChangeNotifier {
  final int numberOfOptions = 4;
  final List<Phrase> phrases;
  final PhraseViewStore viewStore;
  final PronunciationController pronunciation;
  int _counter = 0;
  int _score = 0;
  QuizQuestion? currentQuestion;
  int? correctHighlightIndex;
  int? wrongHighlightIndex;
  QuizState state = QuizState.guessing;
  bool showPronunciationButtons = false;
  bool _disposed = false;
  Audio? _audio;

  QuizController({
    required this.phrases,
    required this.viewStore,
    required this.pronunciation,
  }) {
    _generateQuestion();
  }

  List<Phrase> get _questionPhrases =>
      phrases.where((phrase) => viewStore.viewsFor(phrase.id) > 3).toList();

  Phrase? get currentPhrase {
    final questionPhrases = _questionPhrases;
    if (questionPhrases.isEmpty) return null;
    return questionPhrases[_counter % questionPhrases.length];
  }

  int get counter => _counter;
  int get score => _score;
  List<PronunciationData> get optionPronunciations => [
    for (final option in currentQuestion?.options ?? const <QuizOption>[])
      pronunciation.dataFor(option.audioPath),
  ];

  Future<void> playOptionAudio(int optionIndex) {
    final question = currentQuestion;
    if (question == null || optionIndex >= question.options.length) {
      return Future.value();
    }
    return pronunciation.play(question.options[optionIndex].audioPath);
  }

  void open() {
    _counter = 0;
    _score = 0;
    correctHighlightIndex = null;
    wrongHighlightIndex = null;
    state = QuizState.guessing;
    _generateQuestion();
  }

  void setShowPronunciationButtons(bool value) {
    if (showPronunciationButtons == value) return;
    showPronunciationButtons = value;
    notifyListeners();
  }

  Future<void> submit(int guessIndex) async {
    final question = currentQuestion;
    if (question == null) return;
    if (guessIndex == question.correctIndex) {
      state = QuizState.feedbackCorrect;
      _score++;
      correctHighlightIndex = guessIndex;
      (_audio ??= Audio()).playCorrect();
    } else {
      state = QuizState.feedbackWrong;
      wrongHighlightIndex = guessIndex;
      (_audio ??= Audio()).playWrong();
    }
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    if (_disposed) return;
    state = QuizState.guessing;
    correctHighlightIndex = null;
    wrongHighlightIndex = null;
    _next();
  }

  void _next() {
    _counter++;
    _generateQuestion();
    state = QuizState.guessing;
    notifyListeners();
  }

  void _generateQuestion() {
    final phrase = currentPhrase;
    currentQuestion = phrase == null
        ? null
        : QuizQuestion.fromPool(
            phrase: phrase,
            numberOfOptions: numberOfOptions,
            distractorPool: phrases,
          );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
