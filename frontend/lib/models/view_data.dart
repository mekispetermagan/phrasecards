import 'accents.dart';
import 'letter_data.dart';
import 'learn.dart';
import 'memory.dart';
import 'phrase.dart';
import 'phrase_request.dart';
import 'pronunciation.dart';
import 'quiz.dart';

enum RequestListStatus { loading, ready, error }

class LearnViewData {
  final Phrase? phrase;
  final bool isTurned;
  final bool isNew;
  final Set<PhraseGroup> selectedGroups;
  final PronunciationData? pronunciation;

  const LearnViewData({
    required this.phrase,
    required this.isTurned,
    required this.isNew,
    required this.selectedGroups,
    required this.pronunciation,
  });
}

class QuizViewData {
  final QuizQuestion? question;
  final int score;
  final int attemptCount;
  final int? correctHighlightIndex;
  final int? wrongHighlightIndex;
  final List<PronunciationData> optionPronunciations;
  final bool showPronunciationButtons;

  const QuizViewData({
    required this.question,
    required this.score,
    required this.attemptCount,
    required this.correctHighlightIndex,
    required this.wrongHighlightIndex,
    required this.optionPronunciations,
    required this.showPronunciationButtons,
  });
}

class AccentsViewData {
  final List<List<LetterData>>? currentLetterData;
  final List<LetterData> accentedVowelData;
  final PronunciationData? pronunciation;
  final AccentsPhase phase;

  const AccentsViewData({
    required this.accentedVowelData,
    required this.currentLetterData,
    required this.pronunciation,
    required this.phase,
  });
}

class MemoryViewData {
  final List<MemoryCardData> cards;
  final bool canPlay;
  final bool isComplete;

  const MemoryViewData({
    required this.cards,
    required this.canPlay,
    required this.isComplete,
  });
}

class NumberQuizViewData {
  final int solution;
  final List<String> options;
  final String emoji;
  final int score;
  final int? successHighlightIndex;
  final int? failureHighlightIndex;
  const NumberQuizViewData({
    required this.solution,
    required this.options,
    required this.emoji,
    required this.score,
    this.successHighlightIndex,
    this.failureHighlightIndex,
  });
}

class RequestSubmissionViewData {
  final String source;
  final bool isSubmitting;
  final bool canSubmit;
  final String? errorMessage;

  const RequestSubmissionViewData({
    required this.source,
    required this.isSubmitting,
    required this.canSubmit,
    required this.errorMessage,
  });
}

class RequestListViewData {
  final RequestListStatus status;
  final List<PhraseRequest> requests;
  final String? errorMessage;

  const RequestListViewData({
    required this.status,
    required this.requests,
    required this.errorMessage,
  });
}

class ResolutionFormViewData {
  final int requestId;
  final String source;
  final String target;
  final bool isSubmitting;
  final bool canSubmit;
  final String? errorMessage;

  const ResolutionFormViewData({
    required this.requestId,
    required this.source,
    required this.target,
    required this.isSubmitting,
    required this.canSubmit,
    required this.errorMessage,
  });
}
