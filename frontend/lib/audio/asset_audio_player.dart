import 'package:flutter_soloud/flutter_soloud.dart';

import 'soloud_engine.dart';

abstract interface class AssetAudioPlayer {
  Future<void> play(String assetPath);
  Future<void> stop();
}

class SoloudAssetAudioPlayer implements AssetAudioPlayer {
  SoLoud get _soloud => SoLoud.instance;

  SoundHandle? _handle;
  int _operation = 0;

  @override
  Future<void> play(String assetPath) async {
    await stop();
    final operation = ++_operation;

    await ensureSoloudInitialized();
    final source = await _soloud.loadAsset(assetPath, autoDispose: true);

    if (operation != _operation) {
      await _soloud.disposeSource(source);
      return;
    }

    final finished = source.allInstancesFinished.first;
    _handle = _soloud.play(source);
    await finished;

    if (operation == _operation) _handle = null;
  }

  @override
  Future<void> stop() async {
    _operation++;
    final handle = _handle;
    _handle = null;
    if (handle != null && _soloud.isInitialized) {
      await _soloud.stop(handle);
    }
  }
}
