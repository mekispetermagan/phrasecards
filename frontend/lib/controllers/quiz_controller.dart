import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/phrase.dart';
import '../models/quiz.dart';
import '../audio/audio.dart';

enum QuizState { guessing, feedbackCorrect, feedbackWrong }

class QuizController extends ChangeNotifier {
  final int numberOfOptions = 4;
  final List<Phrase> phrases;
  int _counter = 0;
  int score = 0;
  late QuizQuestion currentQuestion;
  int? correctHighlightIndex;
  int? wrongHighlightIndex;
  QuizState state = QuizState.guessing;
  Audio? _audio;

  QuizController({required this.phrases}) {
    _generateQuestion();
  }

  Phrase get currentPhrase => phrases[_counter % phrases.length];
  List<String> get pool => [for (var phrase in phrases) phrase.target];

  Future<void> submit(int guessIndex) async {
    if (guessIndex == currentQuestion.correctIndex) {
      state = QuizState.feedbackCorrect;
      score++;
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
      source: currentPhrase.source,
      target: currentPhrase.target,
      numberOfOptions: numberOfOptions,
      distractorPool: pool,
    );
  }
}
