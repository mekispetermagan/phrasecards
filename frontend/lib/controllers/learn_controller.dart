import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/learn.dart';
import '../models/phrase.dart';
import '../models/pronunciation.dart';
import '../storage/phrase_view_store.dart';
import 'pronunciation_controller.dart';

class LearnController extends ChangeNotifier {
  final List<Phrase> _phrases;
  final PronunciationController _pronunciation;
  final PhraseViewStore _viewStore;
  final Random _random;

  final Set<PhraseGroup> _selectedGroups;
  List<Phrase> _queue = [];
  bool _cardIsTurned = false;
  bool _isAdvancing = false;
  bool _disposed = false;

  LearnController({
    required List<Phrase> phrases,
    required PronunciationController pronunciationController,
    required PhraseViewStore phraseViewStore,
    Set<PhraseGroup>? selectedGroups,
    Random? random,
  }) : _phrases = List.unmodifiable(phrases),
       _pronunciation = pronunciationController,
       _viewStore = phraseViewStore,
       _selectedGroups = Set.of(selectedGroups ?? PhraseGroup.values),
       _random = random ?? Random() {
    _reshuffle();
  }

  Phrase? get currentPhrase => _queue.firstOrNull;
  bool get cardIsTurned => _cardIsTurned;
  bool get isCurrentPhraseNew {
    final phrase = currentPhrase;
    return phrase != null && isLocallyNew(_viewStore.viewsFor(phrase.id));
  }

  Set<PhraseGroup> get selectedGroups => Set.unmodifiable(_selectedGroups);

  PronunciationData? get pronunciationData {
    final phrase = currentPhrase;
    return phrase == null ? null : _pronunciation.dataFor(phrase.audioPath);
  }

  void setSelectedGroups(Set<PhraseGroup> groups) {
    if (groups.isEmpty || setEquals(groups, _selectedGroups)) return;
    _selectedGroups
      ..clear()
      ..addAll(groups);
    _cardIsTurned = false;
    _reshuffle();
    notifyListeners();
  }

  void turnCard() {
    if (currentPhrase == null) return;
    _cardIsTurned = !_cardIsTurned;
    if (_cardIsTurned) playAudio();
    notifyListeners();
  }

  Future<void> next() async {
    if (_isAdvancing) return;
    final phrase = currentPhrase;
    if (phrase == null) return;

    _isAdvancing = true;
    await _viewStore.increment(phrase.id);
    _isAdvancing = false;
    if (_disposed) return;

    _queue.removeAt(0);
    if (_queue.isEmpty) _reshuffle();
    _cardIsTurned = false;
    notifyListeners();
  }

  Future<void> playAudio() => _pronunciation.play(currentPhrase?.audioPath);

  void _reshuffle() {
    final eligible = [
      for (final phrase in _phrases)
        if (_selectedGroups.any(
          (group) => group.includes(_viewStore.viewsFor(phrase.id)),
        ))
          phrase,
    ];
    final newPhrases = [
      for (final phrase in eligible)
        if (isLocallyNew(_viewStore.viewsFor(phrase.id))) phrase,
    ]..shuffle(_random);
    final remaining = [
      for (final phrase in eligible)
        if (!isLocallyNew(_viewStore.viewsFor(phrase.id))) phrase,
    ]..shuffle(_random);
    _queue = [...newPhrases, ...remaining];
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
