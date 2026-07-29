import 'package:flutter/foundation.dart';

import '../models/phrase.dart';
import '../models/pronunciation.dart';
import 'pronunciation_controller.dart';

class LearnController extends ChangeNotifier {
  int _counter = 0;
  bool _cardIsTurned = false;
  final List<Phrase> phrases;
  final PronunciationController pronunciation;

  LearnController({required this.phrases, required this.pronunciation});

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

  void next() {
    _counter++;
    _cardIsTurned = false;
    notifyListeners();
  }

  Future<void> playAudio() => pronunciation.play(currentPhrase.audioPath);
}
