import 'dart:math';

import 'phrase.dart';

class QuizOption {
  final String text;
  final String? audioPath;
  const QuizOption({required this.text, required this.audioPath});
}

class QuizQuestion {
  final String source;
  final List<QuizOption> options;
  final int correctIndex;

  QuizQuestion({
    required this.source,
    required List<QuizOption> options,
    required this.correctIndex,
  }) : options = List.unmodifiable(options) {
    RangeError.checkValidIndex(correctIndex, options, 'correctIndex');
  }

  factory QuizQuestion.fromPool({
    required Phrase phrase,
    required int numberOfOptions,
    required List<Phrase> distractorPool,
    Random? random,
  }) {
    if (numberOfOptions <= 0) {
      throw RangeError.value(
        numberOfOptions,
        'numberOfOptions',
        'Must be positive',
      );
    }

    final r = random ?? Random();
    final distractorsByTarget = <String, Phrase>{
      for (final candidate in distractorPool)
        if (candidate.target != phrase.target) candidate.target: candidate,
    };
    if (distractorsByTarget.length < numberOfOptions - 1) {
      throw StateError('Not enough distinct quiz distractors');
    }

    final distractors = distractorsByTarget.values.toList()..shuffle(r);
    final correctIndex = r.nextInt(numberOfOptions);
    final options = <QuizOption>[];
    var distractorIndex = 0;
    for (int i = 0; i < numberOfOptions; i++) {
      if (i == correctIndex) {
        options.add(
          QuizOption(text: phrase.target, audioPath: phrase.audioPath),
        );
      } else {
        final newDistractor = distractors[distractorIndex++];
        options.add(
          QuizOption(
            text: newDistractor.target,
            audioPath: newDistractor.audioPath,
          ),
        );
      }
    }
    return QuizQuestion(
      source: phrase.source,
      options: options,
      correctIndex: correctIndex,
    );
  }
}
