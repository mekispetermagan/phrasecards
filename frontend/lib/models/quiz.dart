import 'dart:math';

class QuizQuestion {
  final String source;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.source,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromPool({
    required String source,
    required String target,
    required int numberOfOptions,
    required List<String> distractorPool,
    Random? random,
  }) {
    final Random r = random ?? Random();
    int correctIndex = r.nextInt(numberOfOptions);
    List<String> options = [];
    for (int i = 0; i < numberOfOptions; i++) {
      if (i == correctIndex) {
        options.add(target);
      } else {
        List<String> remainingPool = [...distractorPool]
          ..removeWhere((x) => options.contains(x) || x == target);
        String newDistractor =
            remainingPool[Random().nextInt(remainingPool.length)];
        options.add(newDistractor);
      }
    }
    return QuizQuestion(
      source: source,
      options: options,
      correctIndex: correctIndex,
    );
  }
}
