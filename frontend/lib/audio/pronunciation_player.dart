import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'phrase_audio_cache.dart';
import 'soloud_engine.dart';

abstract interface class PronunciationPlayer {
  Future<void> play(String audioPath);
  Future<void> stop();
}

class SoloudPronunciationPlayer implements PronunciationPlayer {
  SoLoud get _soloud => SoLoud.instance;
  late final PhraseAudioCache _phraseCache;
  final http.Client _client;
  SoundHandle? _handle;
  int _operation = 0;

  SoloudPronunciationPlayer({
    http.Client? client,
    PhraseAudioCache? phraseCache,
  }) : _client = client ?? http.Client() {
    _phraseCache = phraseCache ?? PhraseAudioCache(client: _client);
  }

  Future<void> _initialize() async {
    await ensureSoloudInitialized();
  }

  @override
  Future<void> play(String audioPath) async {
    await stop();
    final operation = ++_operation;
    await _initialize();

    final source = kIsWeb
        ? await _loadForWeb(audioPath)
        : await _soloud.loadFile(
            (await _phraseCache.get(audioPath)).path,
            autoDispose: true,
          );

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

  Future<AudioSource> _loadForWeb(String audioPath) async {
    final uri = Uri.parse(ApiConfig.resolveApiUrl(audioPath));
    final response = await _client.get(uri);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError('Could not download phrase audio');
    }
    return _soloud.loadMem(
      uri.toString(),
      response.bodyBytes,
      autoDispose: true,
    );
  }
}
