import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/number_quiz.dart';

void main() {
  group('NumberQuizQuestion', () {
    test('exposes the option at correctIndex as its solution', () {
      final question = NumberQuizQuestion(options: [2, 7, 4], correctIndex: 1);

      expect(question.solution, 7);
    });

    test('takes an immutable defensive copy of options', () {
      final original = [1, 2, 3];
      final question = NumberQuizQuestion(options: original, correctIndex: 0);

      original[0] = 10;

      expect(question.options, [1, 2, 3]);
      expect(() => question.options.add(4), throwsUnsupportedError);
    });

    test('rejects an invalid correctIndex', () {
      expect(
        () => NumberQuizQuestion(options: [1, 2, 3], correctIndex: -1),
        throwsRangeError,
      );
      expect(
        () => NumberQuizQuestion(options: [1, 2, 3], correctIndex: 3),
        throwsRangeError,
      );
      expect(
        () => NumberQuizQuestion(options: [], correctIndex: 0),
        throwsRangeError,
      );
    });
  });

  group('NumberQuizQuestion.generate', () {
    test('generates distinct in-range options and a valid solution', () {
      final random = Random(42);

      for (var iteration = 0; iteration < 100; iteration++) {
        final question = NumberQuizQuestion.generate(
          numberOfOptions: 3,
          upperLimit: 10,
          r: random,
        );

        expect(question.options, hasLength(3));
        expect(question.options.toSet(), hasLength(3));
        expect(question.options, everyElement(inInclusiveRange(1, 10)));
        expect(question.correctIndex, inInclusiveRange(0, 2));
        expect(question.options, contains(question.solution));
      }
    });

    test('rejects a non-positive option count', () {
      expect(
        () => NumberQuizQuestion.generate(numberOfOptions: 0),
        throwsRangeError,
      );
      expect(
        () => NumberQuizQuestion.generate(numberOfOptions: -1),
        throwsRangeError,
      );
    });

    test('rejects an upper limit smaller than the option count', () {
      expect(
        () => NumberQuizQuestion.generate(numberOfOptions: 4, upperLimit: 3),
        throwsRangeError,
      );
    });

    test('supports selecting the complete available range', () {
      final question = NumberQuizQuestion.generate(
        numberOfOptions: 3,
        upperLimit: 3,
        r: Random(7),
      );

      expect(question.options.toSet(), {1, 2, 3});
    });
  });
}
