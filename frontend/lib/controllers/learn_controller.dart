import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/phrase.dart';
import '../models/pronunciation.dart';
import 'pronunciation_controller.dart';

class LearnController extends ChangeNotifier {
  int _counter = 0;
  bool _cardIsTurned = false;
  bool _isAdvancing = false;
  bool _disposed = false;
  final List<Phrase> phrases;
  final PronunciationController pronunciation;
  final PhraseProgressApi progressApi;

  LearnController({
    required this.phrases,
    required this.pronunciation,
    required this.progressApi,
  });

  Phrase get currentPhrase => phrases[_counter % phrases.length];

  bool get cardIsTurned => _cardIsTurned;
  PronunciationData get pronunciationData =>
      pronunciation.dataFor(currentPhrase.audioPath);

  void turnCard() {
    _cardIsTurned = !_cardIsTurned;
    if (cardIsTurned) {
      playAudio();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_isAdvancing) return;

    final phraseIndex = _counter % phrases.length;
    final phrase = phrases[phraseIndex];
    if (phrase.isNew) {
      _isAdvancing = true;
      final markedSeen = await progressApi.markPhraseSeen(phrase.id);
      _isAdvancing = false;
      if (_disposed) return;
      if (markedSeen) phrases[phraseIndex] = phrase.copyWith(isNew: false);
    }

    _counter++;
    _cardIsTurned = false;
    notifyListeners();
  }

  Future<void> playAudio() => pronunciation.play(currentPhrase.audioPath);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
