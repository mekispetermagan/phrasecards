import 'package:flutter/foundation.dart';

import '../audio/audio.dart';
import '../audio/phrase_audio_player.dart';
import '../models/phrase.dart';

class LearnController extends ChangeNotifier {
  int _counter = 0;
  bool _cardIsTurned = false;
  bool _isPlayingAudio = false;
  String? _audioError;
  bool _disposed = false;
  final List<Phrase> phrases;
  PhraseAudioPlayer? _audio;

  LearnController({required this.phrases, this._audio});

  Phrase get currentPhrase => phrases[_counter % phrases.length];

  bool get cardIsTurned => _cardIsTurned;
  bool get isPlayingAudio => _isPlayingAudio;
  String? get audioError => _audioError;

  void turnCard() {
    _cardIsTurned = !_cardIsTurned;
    if (cardIsTurned) {
      playAudio();
    }
    _audioError = null;
    notifyListeners();
  }

  void next() {
    _counter++;
    _cardIsTurned = false;
    _audioError = null;
    notifyListeners();
  }

  Future<void> playAudio() async {
    final audioPath = currentPhrase.audioPath;
    if (audioPath == null || _isPlayingAudio) return;

    _isPlayingAudio = true;
    _audioError = null;
    notifyListeners();
    try {
      await (_audio ??= Audio()).playPhrase(audioPath);
    } catch (_) {
      if (!_disposed) _audioError = 'Could not play this phrase';
    } finally {
      if (!_disposed) {
        _isPlayingAudio = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
