import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../audio/asset_audio_player.dart';
import '../models/learn.dart';
import '../models/phrase.dart';
import '../models/phrase_request.dart';
import '../storage/phrase_view_store.dart';
import '../models/view_data.dart';
import 'learn_controller.dart';
import 'memory_controller.dart';
import 'pronunciation_controller.dart';
import 'quiz_controller.dart';
import 'accents_controller.dart';
import 'numbers_controller.dart';
import 'request_submission_controller.dart';
import 'resolution_controller.dart';

enum SessionStatus {
  loading,
  error,
  menu,
  learn,
  quiz,
  accents,
  memory,
  numbers,
  request,
  resolve,
  resolveForm,
}

enum SessionNotice { requestSubmitted }

class SessionController extends ChangeNotifier {
  LearnController? _learnController;
  QuizController? _quizController;
  MemoryController? _memoryController;
  AccentsController? _accentsController;
  late final NumbersController _numbersController;
  late final RequestSubmissionController _requestController;
  late final ResolutionController _resolutionController;
  final PronunciationController _pronunciationController;
  final AssetAudioPlayer _assetAudioPlayer;
  final PhraseViewStore _viewStore;

  final PhrasesApi _api;
  SessionStatus status = SessionStatus.loading;
  SessionNotice? _notice;
  String? errorMessage;
  bool _disposed = false;
  bool _isRefreshingPhrases = false;

  late final List<(String, VoidCallback)> menuItems = [
    ("Learn phrases", _onLearn),
    ("Play quiz", _onQuiz),
    ("Memory game", _onMemory),
    ("Fix the accents", _onAccents),
    ("Practice numbers", _onNumbers),
    ("Request a phrase", _onRequest),
    ("Resolve a request", _onResolve),
  ];

  SessionController({
    PhrasesApi? api,
    RequestsApi? requestsApi,
    PronunciationController? pronunciationController,
    AssetAudioPlayer? assetAudioPlayer,
    PhraseViewRepository? phraseViewRepository,
  }) : _api = api ?? PhrasesApi(),
       _pronunciationController =
           pronunciationController ?? PronunciationController(),
       _assetAudioPlayer = assetAudioPlayer ?? SoloudAssetAudioPlayer(),
       _viewStore = PhraseViewStore(
         phraseViewRepository ?? SharedPreferencesPhraseViewRepository(),
       ) {
    final requestApi = requestsApi ?? RequestsApi();
    _requestController = RequestSubmissionController(requestApi)
      ..addListener(_forwardNotification);
    _resolutionController = ResolutionController(requestApi)
      ..addListener(_forwardNotification);
    _numbersController = NumbersController(_assetAudioPlayer.play)
      ..addListener(_forwardNotification);
    _pronunciationController.addListener(_forwardNotification);
    unawaited(_load());
  }

  LearnController get _learn {
    return _learnController ??
        (throw StateError(
          'LearnController accessed before session initialization',
        ));
  }

  QuizController get _quiz {
    return _quizController ??
        (throw StateError(
          'QuizController accessed before session initialization',
        ));
  }

  MemoryController get _memory {
    return _memoryController ??
        (throw StateError(
          'MemoryController accessed before session initialization',
        ));
  }

  AccentsController get _accents {
    return _accentsController ??
        (throw StateError(
          'AccentsController accessed before session initialization',
        ));
  }

  NumbersController get _numbers => _numbersController;

  LearnViewData get learnViewData => LearnViewData(
    phrase: _learn.currentPhrase,
    isTurned: _learn.cardIsTurned,
    isNew: _learn.isCurrentPhraseNew,
    selectedGroups: _learn.selectedGroups,
    pronunciation: _learn.pronunciationData,
  );

  QuizViewData get quizViewData => QuizViewData(
    question: _quiz.currentQuestion,
    score: _quiz.score,
    maxScore: _quiz.counter,
    correctHighlightIndex: _quiz.correctHighlightIndex,
    wrongHighlightIndex: _quiz.wrongHighlightIndex,
    optionPronunciations: _quiz.optionPronunciations,
    showPronunciationButtons: _quiz.showPronunciationButtons,
  );

  AccentedViewData get accentedViewData => AccentedViewData(
    accentedVowelData: _accents.accentedVowelData,
    currentLetterData: _accents.currentLetterData,
    pronunciation: _accents.pronunciationData,
    phase: _accents.phase,
  );

  MemoryViewData get memoryViewData => MemoryViewData(
    cards: _memory.cards,
    canPlay: _memory.canPlay,
    isComplete: _memory.isComplete,
  );

  NumbersViewData get numbersViewData => NumbersViewData(
    solution: _numbers.solution,
    options: _numbers.options,
    emoji: _numbers.emoji,
    score: _numbers.score,
    successHighlightIndex: _numbers.successHighlightIndex,
    failureHighlightIndex: _numbers.failureHighlightIndex,
  );

  void learnTurnCard() => _learn.turnCard();

  Future<void> learnNext() => _learn.next();

  Future<void> learnPlayAudio() => _learn.playAudio();

  void learnSetSelectedGroups(Set<PhraseGroup> groups) =>
      _learn.setSelectedGroups(groups);

  Future<void> quizSubmit(int guessIndex) => _quiz.submit(guessIndex);

  Future<void> quizPlayAudio(int optionIndex) =>
      _quiz.playOptionAudio(optionIndex);

  void quizSetShowPronunciationButtons(bool value) =>
      _quiz.setShowPronunciationButtons(value);

  void accentsNext() {
    if (_accents.next()) unawaited(_accents.playAudio());
  }

  void accentsOnDrop({
    required String dragTargetId,
    required String draggableLetter,
  }) => _accents.onDrop(
    dragTargetId: dragTargetId,
    draggableLetter: draggableLetter,
  );

  Future<void> accentsPlayAudio() => _accents.playAudio();

  Future<void> memorySelect(int cardId) => _memory.select(cardId);

  void memoryStartNewGame() => _memory.startNewGame();

  void Function(int)? get onNumbersSubmit => _numbers.submit;

  RequestSubmissionViewData get requestViewData => _requestController.viewData;

  void requestUpdateSource(String value) =>
      _requestController.updateSource(value);

  Future<void> requestSubmit() async {
    if (await _requestController.submit()) {
      _notice = SessionNotice.requestSubmitted;
      onMenu();
    }
  }

  SessionNotice? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  RequestListViewData get requestListViewData =>
      _resolutionController.listViewData;

  ResolutionFormViewData get resolutionFormViewData =>
      _resolutionController.formViewData;

  Future<void> resolutionRetry() => _resolutionController.load();

  void resolutionSelect(PhraseRequest request) {
    _resolutionController.select(request);
    status = SessionStatus.resolveForm;
    notifyListeners();
  }

  void resolutionUpdateSource(String value) =>
      _resolutionController.updateSource(value);

  void resolutionUpdateTarget(String value) =>
      _resolutionController.updateTarget(value);

  Future<void> resolutionSubmit() async {
    if (await _resolutionController.submit()) {
      status = SessionStatus.resolve;
      notifyListeners();
    }
  }

  void onResolutionList() {
    status = SessionStatus.resolve;
    notifyListeners();
  }

  Future<void> retry() async {
    errorMessage = null;
    status = SessionStatus.loading;
    notifyListeners();
    await _load();
  }

  Future<void> _load() async {
    final result = await _api.fetchPhrases();
    if (_disposed) return;

    final phrases = result.phrases;
    if (phrases == null) {
      errorMessage = result.message ?? 'Could not load phrases';
      status = SessionStatus.error;
      notifyListeners();
      return;
    }

    await _viewStore.load();
    if (_disposed) return;

    final validationError = _phraseValidationError(phrases);
    if (validationError != null) {
      errorMessage = validationError;
      status = SessionStatus.error;
      notifyListeners();
      return;
    }

    _initializeFeatures(phrases);
    status = SessionStatus.menu;
    notifyListeners();
  }

  // _notifyListeners itself gets registered as a listener to be disposed
  // before the listened child controller, hence it gets named
  void _forwardNotification() {
    notifyListeners();
  }

  void _initializeFeatures(List<Phrase> phrases) {
    final selectedLearnGroups = _learnController?.selectedGroups;
    _learnController?.removeListener(_forwardNotification);
    _quizController?.removeListener(_forwardNotification);
    _memoryController?.removeListener(_forwardNotification);
    _accentsController?.removeListener(_forwardNotification);
    _learnController?.dispose();
    _quizController?.dispose();
    _memoryController?.dispose();
    _accentsController?.dispose();

    _learnController = LearnController(
      phrases: phrases,
      pronunciation: _pronunciationController,
      viewStore: _viewStore,
      selectedGroups: selectedLearnGroups,
    )..addListener(_forwardNotification);

    _quizController = QuizController(
      phrases: phrases,
      viewStore: _viewStore,
      pronunciation: _pronunciationController,
    )..addListener(_forwardNotification);

    _memoryController = MemoryController(
      phrases: phrases,
      playPronunciation: _pronunciationController.play,
    )..addListener(_forwardNotification);

    _accentsController = AccentsController(
      phrases: phrases,
      pronunciation: _pronunciationController,
    )..addListener(_forwardNotification);
  }

  String? _phraseValidationError(List<Phrase> phrases) {
    if (phrases.map((phrase) => phrase.target).toSet().length < 4) {
      return 'At least four phrases with distinct translations are required';
    }
    return null;
  }

  Future<void> _refreshPhrases() async {
    if (_isRefreshingPhrases) return;
    _isRefreshingPhrases = true;
    try {
      final result = await _api.fetchPhrases();
      if (_disposed || status != SessionStatus.menu) return;

      final phrases = result.phrases;
      if (phrases == null || _phraseValidationError(phrases) != null) return;

      _initializeFeatures(phrases);
      notifyListeners();
    } finally {
      _isRefreshingPhrases = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_assetAudioPlayer.stop());
    _learnController?.removeListener(_forwardNotification);
    _quizController?.removeListener(_forwardNotification);
    _memoryController?.removeListener(_forwardNotification);
    _accentsController?.removeListener(_forwardNotification);
    _numbersController.removeListener(_forwardNotification);
    _requestController.removeListener(_forwardNotification);
    _resolutionController.removeListener(_forwardNotification);
    _pronunciationController.removeListener(_forwardNotification);

    _learnController?.dispose();
    _quizController?.dispose();
    _memoryController?.dispose();
    _accentsController?.dispose();
    _numbersController.dispose();
    _requestController.dispose();
    _resolutionController.dispose();
    _pronunciationController.dispose();

    super.dispose();
  }

  void onMenu() {
    if (status == SessionStatus.numbers) unawaited(_assetAudioPlayer.stop());
    status = SessionStatus.menu;
    notifyListeners();
    unawaited(_refreshPhrases());
  }

  void _onLearn() {
    status = SessionStatus.learn;
    notifyListeners();
  }

  void _onQuiz() {
    _quiz.open();
    status = SessionStatus.quiz;
    notifyListeners();
  }

  void _onMemory() {
    status = SessionStatus.memory;
    notifyListeners();
  }

  void _onAccents() {
    status = SessionStatus.accents;
    notifyListeners();
    unawaited(_accents.playAudio());
  }

  void _onNumbers() {
    status = SessionStatus.numbers;
    notifyListeners();
  }

  void _onRequest() {
    _requestController.open();
    status = SessionStatus.request;
    notifyListeners();
  }

  void _onResolve() {
    status = SessionStatus.resolve;
    notifyListeners();
    unawaited(_resolutionController.load());
  }
}
