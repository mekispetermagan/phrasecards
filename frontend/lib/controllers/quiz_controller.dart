import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/phrase.dart';
import '../models/quiz.dart';
import '../audio/audio.dart';
import '../models/pronunciation.dart';
import 'pronunciation_controller.dart';

enum QuizState { guessing, feedbackCorrect, feedbackWrong }

class QuizController extends ChangeNotifier {
  final int numberOfOptions = 4;
  final List<Phrase> phrases;
  int _counter = 0;
  int _score = 0;
  late QuizQuestion currentQuestion;
  int? correctHighlightIndex;
  int? wrongHighlightIndex;
  QuizState state = QuizState.guessing;
  bool showPronunciationButtons = false;
  Audio? _audio;
  final PronunciationController pronunciation;

  QuizController({required this.phrases, required this.pronunciation}) {
    _generateQuestion();
  }

  List<Phrase> get _questionPhrases =>
      phrases.where((phrase) => !phrase.isNew).toList();
  Phrase get currentPhrase =>
      _questionPhrases[_counter % _questionPhrases.length];
  int get counter => _counter;
  int get score => _score;
  List<PronunciationData> get optionPronunciations => [
    for (final option in currentQuestion.options)
      pronunciation.dataFor(option.audioPath),
  ];

  Future<void> playOptionAudio(int optionIndex) =>
      pronunciation.play(currentQuestion.options[optionIndex].audioPath);

  void setShowPronunciationButtons(bool value) {
    if (showPronunciationButtons == value) return;
    showPronunciationButtons = value;
    notifyListeners();
  }

  Future<void> submit(int guessIndex) async {
    if (guessIndex == currentQuestion.correctIndex) {
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
    currentQuestion = QuizQuestion.fromPool(
      phrase: currentPhrase,
      numberOfOptions: numberOfOptions,
      distractorPool: phrases,
    );
  }
}
