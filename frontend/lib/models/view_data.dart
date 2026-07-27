import 'phrase.dart';
import 'phrase_request.dart';
import 'quiz.dart';

enum RequestListStatus { loading, ready, error }

class LearnViewData {
  final Phrase phrase;
  final bool isTurned;

  const LearnViewData({required this.phrase, required this.isTurned});
}

class QuizViewData {
  final QuizQuestion question;
  final int score;
  final int? correctHighlightIndex;
  final int? wrongHighlightIndex;

  const QuizViewData({
    required this.question,
    required this.score,
    required this.correctHighlightIndex,
    required this.wrongHighlightIndex,
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
