import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:characters/characters.dart';
import '../models/accents.dart';
import '../models/phrase.dart';
import '../models/letter_data.dart';
import '../models/pronunciation.dart';
import '../utils/string_utils.dart';
import 'pronunciation_controller.dart';

class AccentsController extends ChangeNotifier {
  final PronunciationController pronunciation;
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
    required this.pronunciation,
  }) : _phrasesWithAccent = [
         for (Phrase x in phrases)
           if (hasAccents(x.target)) x,
       ].shuffled() {
    _generateExercise();
  }

  List<List<LetterData>>? get currentLetterData => _currentLetterData;
  List<LetterData> get accentedVowelData => _accentedVowelData;

  PronunciationData? get pronunciationData {
    final Phrase? cP = _currentPhrase;
    return cP == null ? null : pronunciation.dataFor(cP.audioPath);
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
    List<List<LetterData>>? cLD = _currentLetterData;
    List<LetterData>? flatLetterData = cLD == null
        ? null
        : [for (List<LetterData> x in cLD) ...x];
    LetterData? dragTargetData = flatLetterData?.firstWhereOrNull(
      (x) => x.id == dragTargetId,
    );
    if (dragTargetData == null ||
        dragTargetData.isRevealed ||
        dragTargetData.letter != draggableLetter) {
      return;
    }
    dragTargetData.reveal();
    notifyListeners();
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

  Future<void> playAudio() => pronunciation.play(_currentPhrase?.audioPath);
}
