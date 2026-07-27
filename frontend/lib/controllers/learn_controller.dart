import 'package:flutter/foundation.dart';
import '../models/phrase.dart';

class LearnController extends ChangeNotifier {
  int _counter = 0;
  bool _cardIsTurned = false;
  final List<Phrase> phrases;

  LearnController({required this.phrases});

  Phrase get currentPhrase => phrases[_counter % phrases.length];

  bool get cardIsTurned => _cardIsTurned;

  void turnCard() {
    _cardIsTurned = !_cardIsTurned;

    notifyListeners();
  }

  void next() {
    _counter++;
    _cardIsTurned = false;

    notifyListeners();
  }
}
