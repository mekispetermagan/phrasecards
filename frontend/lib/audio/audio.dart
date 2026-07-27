import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'phrase_audio_cache.dart';
import 'phrase_audio_player.dart';

class Audio implements PhraseAudioPlayer {
  final SoLoud _soloud = SoLoud.instance;
  late final AudioSource _correct;
  late final AudioSource _wrong;
  late final Future<void> _ready;
  late final PhraseAudioCache _phraseCache;
  final http.Client _client;

  Audio({http.Client? client, PhraseAudioCache? phraseCache})
    : _client = client ?? http.Client() {
    _phraseCache = phraseCache ?? PhraseAudioCache(client: _client);
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

  @override
  Future<void> playPhrase(String audioPath) async {
    await _ready;
    final source = kIsWeb
        ? await _loadPhraseForWeb(audioPath)
        : await _soloud.loadFile(
            (await _phraseCache.get(audioPath)).path,
            autoDispose: true,
          );
    _soloud.play(source);
  }

  Future<AudioSource> _loadPhraseForWeb(String audioPath) async {
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
