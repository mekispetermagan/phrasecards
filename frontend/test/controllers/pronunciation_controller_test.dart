import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';

class ControllablePronunciationPlayer implements PronunciationPlayer {
  final plays = <String>[];
  final completions = <Completer<void>>[];
  var stops = 0;

  @override
  Future<void> play(String audioPath) {
    plays.add(audioPath);
    final completion = Completer<void>();
    completions.add(completion);
    return completion.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

void main() {
  test('replaces current playback and ignores its stale completion', () async {
    final player = ControllablePronunciationPlayer();
    final controller = PronunciationController(player: player);
    addTearDown(controller.dispose);

    final first = controller.play('/audio/first.mp3');
    expect(controller.dataFor('/audio/first.mp3').isPlaying, isTrue);

    final second = controller.play('/audio/second.mp3');
    expect(controller.dataFor('/audio/first.mp3').isPlaying, isFalse);
    expect(controller.dataFor('/audio/second.mp3').isPlaying, isTrue);
    expect(player.plays, ['/audio/first.mp3', '/audio/second.mp3']);

    player.completions.first.complete();
    await first;
    expect(controller.dataFor('/audio/second.mp3').isPlaying, isTrue);

    player.completions.last.complete();
    await second;
    expect(controller.dataFor('/audio/second.mp3').isPlaying, isFalse);
  });

  test('associates playback errors with the requested path', () async {
    final controller = PronunciationController(
      player: _FailingPronunciationPlayer(),
    );
    addTearDown(controller.dispose);

    await controller.play('/audio/broken.mp3');

    expect(
      controller.dataFor('/audio/broken.mp3').error,
      'Could not play this phrase',
    );
    expect(controller.dataFor('/audio/other.mp3').error, isNull);
  });
}

class _FailingPronunciationPlayer implements PronunciationPlayer {
  @override
  Future<void> play(String audioPath) async {
    throw StateError('failed');
  }

  @override
  Future<void> stop() async {}
}
