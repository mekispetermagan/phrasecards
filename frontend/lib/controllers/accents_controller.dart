import 'package:flutter/foundation.dart';
import 'package:characters/characters.dart';
import 'package:collection/collection.dart';
import '../models/accents.dart';
import '../models/phrase.dart';
import '../models/letter_data.dart';
import '../models/pronunciation.dart';
import '../utils/string_utils.dart';
import 'pronunciation_controller.dart';

class AccentsController extends ChangeNotifier {
  final PronunciationController _pronunciation;
  final List<Phrase> _phrasesWithAccent;
  List<List<LetterData>>? _currentLetterData;
  final List<LetterData> _accentedVowelData = [
    for (int i = 0; i < accentedHUUpper.length; i++)
      LetterData(
        id: "accented$i",
        letter: accentedHUUpper[i],
        isRevealed: true,
      ),
  ];
  int _counter = 0;
  Phrase? _currentPhrase;

  AccentsController({
    required List<Phrase> phrases,
    required PronunciationController pronunciationController,
  }) : _pronunciation = pronunciationController,
       _phrasesWithAccent = [
         for (Phrase x in phrases)
           if (hasAccents(x.target)) x,
       ].shuffled() {
    _generateExercise();
  }

  List<List<LetterData>>? get currentLetterData {
    final data = _currentLetterData;
    return data == null
        ? null
        : List<List<LetterData>>.unmodifiable([
            for (final word in data) List<LetterData>.unmodifiable(word),
          ]);
  }

  List<LetterData> get accentedVowelData =>
      List.unmodifiable(_accentedVowelData);

  PronunciationData? get pronunciationData {
    final Phrase? cP = _currentPhrase;
    return cP == null ? null : _pronunciation.dataFor(cP.audioPath);
  }

  bool get _allLettersRevealed {
    final currentLetterData = _currentLetterData;
    if (currentLetterData == null) return false;
    return currentLetterData.every(
      (word) => word.every((letter) => letter.isRevealed),
    );
  }

  AccentsPhase get phase {
    if (_phrasesWithAccent.isEmpty) return AccentsPhase.unavailable;
    if (_currentPhrase == null) return AccentsPhase.completed;
    return _allLettersRevealed ? AccentsPhase.solved : AccentsPhase.solving;
  }

  void onDrop({required String dragTargetId, required String draggableLetter}) {
    final data = _currentLetterData;
    if (data == null) return;

    for (var wordIndex = 0; wordIndex < data.length; wordIndex++) {
      final letterIndex = data[wordIndex].indexWhere(
        (letter) => letter.id == dragTargetId,
      );
      if (letterIndex == -1) continue;

      final target = data[wordIndex][letterIndex];
      if (target.isRevealed || target.letter != draggableLetter) return;

      data[wordIndex][letterIndex] = target.copyWith(isRevealed: true);
      notifyListeners();
      return;
    }
  }

  bool next() {
    if (phase != AccentsPhase.solved) return false;

    _counter++;
    _generateExercise();
    notifyListeners();
    return true;
  }

  void _generateExercise() {
    _currentPhrase = _counter < _phrasesWithAccent.length
        ? _phrasesWithAccent[_counter]
        : null;

    final Phrase? cP = _currentPhrase;
    if (cP == null) {
      _currentLetterData = null;
      return;
    }
    final currentWords = toWordsWithPunctuation(cP.target);
    _currentLetterData = [
      for (int j = 0; j < currentWords.length; j++)
        [
          for (final (i, character) in currentWords[j].characters.indexed)
            LetterData(
              id: "letter $j-$i",
              letter: character.toUpperCase(),
              isRevealed: !accentedHU.contains(character),
            ),
        ],
    ];
  }

  Future<void> playAudio() => _pronunciation.play(_currentPhrase?.audioPath);
}
