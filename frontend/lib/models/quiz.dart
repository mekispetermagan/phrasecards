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

  const QuizQuestion({
    required this.source,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromPool({
    required Phrase phrase,
    required int numberOfOptions,
    required List<Phrase> distractorPool,
    Random? random,
  }) {
    final Random r = random ?? Random();
    int correctIndex = r.nextInt(numberOfOptions);
    List<QuizOption> options = [];
    for (int i = 0; i < numberOfOptions; i++) {
      if (i == correctIndex) {
        options.add(
          QuizOption(text: phrase.target, audioPath: phrase.audioPath),
        );
      } else {
        List<Phrase> remainingPool = [...distractorPool]
          ..removeWhere(
            (x) => options.any((y) => y.text == x.target) || x == phrase,
          );
        Phrase newDistractor =
            remainingPool[Random().nextInt(remainingPool.length)];
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
