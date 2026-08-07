import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/controllers/phrasebuilding_controller.dart';
import 'package:phrasecards/models/phrase.dart';
import 'package:phrasecards/models/phrasebuilding_state.dart';

Phrase _phrase(int id, String target) =>
    Phrase(id: id, source: 'Source $id', target: target, audioPath: null);

List<Phrase> get _phrases => [
  _phrase(1, 'one'),
  _phrase(2, 'two'),
  _phrase(3, 'three'),
  _phrase(4, 'four'),
];

void main() {
  test('supports a distractor pool smaller than the requested count', () {
    for (var seed = 0; seed < 20; seed++) {
      final controller = PhraseBuildingController(
        phrases: _phrases,
        random: Random(seed),
      );

      expect(controller.sourcePool, isNotEmpty);
      controller.dispose();
    }
  });

  test('moves tiles between the source and target pools', () {
    final controller = PhraseBuildingController(
      phrases: _phrases,
      random: Random(1),
    );
    addTearDown(controller.dispose);
    final tile = controller.sourcePool.first;

    controller.move!(tile);
    expect(controller.sourcePool, isNot(contains(tile)));
    expect(controller.targetPool, contains(tile));

    controller.move!(tile);
    expect(controller.sourcePool, contains(tile));
    expect(controller.targetPool, isNot(contains(tile)));
  });

  test('exposes pools as unmodifiable views', () {
    final controller = PhraseBuildingController(
      phrases: _phrases,
      random: Random(1),
    );
    addTearDown(controller.dispose);

    expect(() => controller.sourcePool.clear(), throwsUnsupportedError);
    expect(() => controller.targetPool.clear(), throwsUnsupportedError);
  });

  test('shows failure feedback and then accepts corrections', () async {
    final controller = PhraseBuildingController(
      phrases: _phrases,
      random: Random(1),
    );
    addTearDown(controller.dispose);

    controller.move!(controller.sourcePool.first);
    controller.move!(controller.sourcePool.first);
    final submission = controller.submit!();

    expect(controller.state, PhraseBuildingState.failureFeedback);
    expect(controller.move, isNull);
    expect(controller.submit, isNull);

    await submission;
    expect(controller.state, PhraseBuildingState.guessing);
    expect(controller.move, isNotNull);
  });

  test('does not notify or advance after disposal during feedback', () async {
    final controller = PhraseBuildingController(
      phrases: _phrases,
      random: Random(1),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.move!(controller.sourcePool.first);

    final submission = controller.submit!();
    final notificationsBeforeDisposal = notifications;
    controller.dispose();
    await submission;

    expect(notifications, notificationsBeforeDisposal);
  });
}
