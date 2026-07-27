import 'package:flutter_soloud/flutter_soloud.dart';

class Audio {
  final SoLoud _soloud = SoLoud.instance;
  late final AudioSource _correct;
  late final AudioSource _wrong;
  late final Future<void> _ready;

  Audio() {
    _ready = _init();
  }

  Future<void> _init() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }

    _correct = await _soloud.loadAsset('assets/audio/correct.mp3');
    _wrong = await _soloud.loadAsset('assets/audio/wrong.mp3');
  }

  Future<void> playCorrect() async {
    await _ready;
    _soloud.play(_correct);
  }

  Future<void> playWrong() async {
    await _ready;
    _soloud.play(_wrong);
  }
}
