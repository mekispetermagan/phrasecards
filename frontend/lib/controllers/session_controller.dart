import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/phrase.dart';
import '../models/phrase_request.dart';
import '../models/view_data.dart';
import 'learn_controller.dart';
import 'pronunciation_controller.dart';
import 'quiz_controller.dart';
import 'request_submission_controller.dart';
import 'resolution_controller.dart';

enum SessionStatus {
  loading,
  error,
  menu,
  learn,
  quiz,
  request,
  resolve,
  resolveForm,
}

enum SessionNotice { requestSubmitted }

class SessionController extends ChangeNotifier {
  LearnController? _learnController;
  QuizController? _quizController;
  late final RequestSubmissionController _requestController;
  late final ResolutionController _resolutionController;
  final PronunciationController _pronunciationController;

  final PhrasesApi _api;
  SessionStatus status = SessionStatus.loading;
  SessionNotice? _notice;
  String? errorMessage;
  bool _disposed = false;

  late final List<(String, VoidCallback)> menuItems = [
    ("Learn phrases", _onLearn),
    ("Play quiz", _onQuiz),
    ("Request a phrase", _onRequest),
    ("Resolve a request", _onResolve),
  ];

  SessionController({
    PhrasesApi? api,
    RequestsApi? requestsApi,
    PronunciationController? pronunciationController,
  }) : _api = api ?? PhrasesApi(),
       _pronunciationController =
           pronunciationController ?? PronunciationController() {
    final requestApi = requestsApi ?? RequestsApi();
    _requestController = RequestSubmissionController(requestApi)
      ..addListener(_forwardNotification);
    _resolutionController = ResolutionController(requestApi)
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

  LearnViewData get learnViewData => LearnViewData(
    phrase: _learn.currentPhrase,
    isTurned: _learn.cardIsTurned,
    isNew: _learn.currentPhrase.isNew,
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

  void learnTurnCard() => _learn.turnCard();

  Future<void> learnNext() => _learn.next();

  Future<void> learnPlayAudio() => _learn.playAudio();

  Future<void> quizSubmit(int guessIndex) => _quiz.submit(guessIndex);

  Future<void> quizPlayAudio(int optionIndex) =>
      _quiz.playOptionAudio(optionIndex);

  void quizSetShowPronunciationButtons(bool value) =>
      _quiz.setShowPronunciationButtons(value);

  RequestSubmissionViewData get requestViewData => _requestController.viewData;

  void requestUpdateSource(String value) =>
      _requestController.updateSource(value);

  Future<void> requestSubmit() async {
    if (await _requestController.submit()) {
      _notice = SessionNotice.requestSubmitted;
      status = SessionStatus.menu;
      notifyListeners();
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

    if (phrases.map((phrase) => phrase.target).toSet().length < 4) {
      errorMessage =
          'At least four phrases with distinct translations '
          'are required';
      status = SessionStatus.error;
      notifyListeners();
      return;
    }

    if (!phrases.any((phrase) => !phrase.isNew)) {
      errorMessage = 'At least one learned phrase is required for the quiz';
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
    _learnController = LearnController(
      phrases: phrases,
      pronunciation: _pronunciationController,
      progressApi: _api,
    )..addListener(_forwardNotification);

    _quizController = QuizController(
      phrases: phrases,
      pronunciation: _pronunciationController,
    )..addListener(_forwardNotification);
  }

  @override
  void dispose() {
    _disposed = true;
    _learnController?.removeListener(_forwardNotification);
    _quizController?.removeListener(_forwardNotification);
    _requestController.removeListener(_forwardNotification);
    _resolutionController.removeListener(_forwardNotification);
    _pronunciationController.removeListener(_forwardNotification);

    _learnController?.dispose();
    _quizController?.dispose();
    _requestController.dispose();
    _resolutionController.dispose();
    _pronunciationController.dispose();

    super.dispose();
  }

  void onMenu() {
    status = SessionStatus.menu;
    notifyListeners();
  }

  void _onLearn() {
    status = SessionStatus.learn;
    notifyListeners();
  }

  void _onQuiz() {
    status = SessionStatus.quiz;
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
