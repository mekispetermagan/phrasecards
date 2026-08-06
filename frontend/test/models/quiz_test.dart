import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/phrase.dart';
import 'package:phrasecards/models/quiz.dart';

Phrase _phrase(int id, String target) => Phrase(
  id: id,
  source: 'Source $id',
  target: target,
  audioPath: '/audio/$id.mp3',
);

void main() {
  test('excludes duplicate translations of the correct answer', () {
    final correct = _phrase(1, 'Azonos');
    final question = QuizQuestion.fromPool(
      phrase: correct,
      numberOfOptions: 4,
      distractorPool: [
        correct,
        _phrase(2, 'Azonos'),
        _phrase(3, 'Egy'),
        _phrase(4, 'Kettő'),
        _phrase(5, 'Három'),
      ],
      random: Random(1),
    );

    expect(
      question.options.where((option) => option.text == 'Azonos'),
      hasLength(1),
    );
    expect(question.options.map((option) => option.text).toSet(), hasLength(4));
  });

  test('uses the injected random source deterministically', () {
    final pool = [
      _phrase(1, 'Egy'),
      _phrase(2, 'Kettő'),
      _phrase(3, 'Három'),
      _phrase(4, 'Négy'),
      _phrase(5, 'Öt'),
    ];

    final first = QuizQuestion.fromPool(
      phrase: pool.first,
      numberOfOptions: 4,
      distractorPool: pool,
      random: Random(42),
    );
    final second = QuizQuestion.fromPool(
      phrase: pool.first,
      numberOfOptions: 4,
      distractorPool: pool,
      random: Random(42),
    );

    expect(first.correctIndex, second.correctIndex);
    expect(
      first.options.map((option) => option.text),
      second.options.map((option) => option.text),
    );
  });

  test('rejects invalid option counts and insufficient distractors', () {
    final phrase = _phrase(1, 'Egy');

    expect(
      () => QuizQuestion.fromPool(
        phrase: phrase,
        numberOfOptions: 0,
        distractorPool: [phrase],
      ),
      throwsRangeError,
    );
    expect(
      () => QuizQuestion.fromPool(
        phrase: phrase,
        numberOfOptions: 4,
        distractorPool: [phrase, _phrase(2, 'Kettő')],
      ),
      throwsStateError,
    );
  });

  test('stores options as an immutable defensive copy', () {
    final options = [
      const QuizOption(text: 'Egy', audioPath: null),
      const QuizOption(text: 'Kettő', audioPath: null),
    ];
    final question = QuizQuestion(
      source: 'One',
      options: options,
      correctIndex: 0,
    );

    options.clear();

    expect(question.options, hasLength(2));
    expect(
      () => question.options.add(
        const QuizOption(text: 'Három', audioPath: null),
      ),
      throwsUnsupportedError,
    );
  });
}
