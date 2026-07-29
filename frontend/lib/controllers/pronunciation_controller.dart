import 'package:flutter/foundation.dart';

import '../audio/pronunciation_player.dart';
import '../models/pronunciation.dart';

class PronunciationController extends ChangeNotifier {
  final PronunciationPlayer _player;
  String? _playingPath;
  String? _errorPath;
  String? _error;
  int _operation = 0;
  bool _disposed = false;

  PronunciationController({PronunciationPlayer? player})
    : _player = player ?? SoloudPronunciationPlayer();

  PronunciationData dataFor(String? path) => PronunciationData(
    path: path,
    isPlaying: path != null && path == _playingPath,
    error: path != null && path == _errorPath ? _error : null,
  );

  Future<void> play(String? path) async {
    if (path == null) return;

    final operation = ++_operation;
    _playingPath = path;
    _errorPath = null;
    _error = null;
    notifyListeners();

    try {
      await _player.play(path);
    } catch (_) {
      if (!_disposed && operation == _operation) {
        _errorPath = path;
        _error = 'Could not play this phrase';
      }
    } finally {
      if (!_disposed && operation == _operation) {
        _playingPath = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    _player.stop();
    super.dispose();
  }
}
