import 'dart:math';

class NumberQuizQuestion {
  final List<int> options;
  final int correctIndex;

  NumberQuizQuestion({required List<int> options, required this.correctIndex})
    : options = List.unmodifiable(options) {
    if (correctIndex < 0 || options.length <= correctIndex) {
      throw RangeError("correctIndex is out of range.");
    }
  }

  int get solution => options[correctIndex];

  factory NumberQuizQuestion.generate({
    required int numberOfOptions,
    int upperLimit = 10,
    Random? r,
  }) {
    if (numberOfOptions <= 0) {
      throw RangeError("The number of options should be positive.");
    }
    if (upperLimit < numberOfOptions) {
      throw RangeError(
        "The upper limit cannot be smaller than the number of options.",
      );
    }
    r = r ?? Random();
    List<int> range = [for (int i = 0; i < upperLimit; i++) i + 1];
    List<int> options = [];
    for (int i = 0; i < numberOfOptions; i++) {
      int newOption = range[r.nextInt(range.length)];
      options.add(newOption);
      range.remove(newOption);
    }
    int correctIndex = r.nextInt(options.length);

    return NumberQuizQuestion(options: options, correctIndex: correctIndex);
  }
}
