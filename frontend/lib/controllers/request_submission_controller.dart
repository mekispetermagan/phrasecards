import 'package:flutter/foundation.dart';

import '../api/_api_support.dart';
import '../api/api.dart';
import '../models/view_data.dart';

class RequestSubmissionController extends ChangeNotifier {
  final RequestsApi _api;

  String _source = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  RequestSubmissionController(this._api);

  RequestSubmissionViewData get viewData => RequestSubmissionViewData(
    source: _source,
    isSubmitting: _isSubmitting,
    canSubmit:
        !_isSubmitting &&
        _source.trim().isNotEmpty &&
        _source.trim().length <= 255,
    errorMessage: _errorMessage,
  );

  void open() {
    _source = '';
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  void updateSource(String value) {
    _source = value;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (!viewData.canSubmit) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _api.submitRequest(_source.trim());
    _isSubmitting = false;

    if (result.request == null) {
      _errorMessage = _failureMessage(
        result.failure,
        result.message,
        conflictMessage: 'This phrase is already pending or resolved.',
      );
      notifyListeners();
      return false;
    }

    _source = '';
    notifyListeners();
    return true;
  }
}

String _failureMessage(
  Failure? failure,
  String? detail, {
  required String conflictMessage,
}) {
  if (detail != null && detail.isNotEmpty) return detail;
  return switch (failure) {
    Failure.conflict => conflictMessage,
    Failure.networkError => 'Could not reach the server.',
    Failure.invalidData => 'The server returned invalid data.',
    Failure.badRequest => 'Please check the submitted text.',
    _ => 'Something went wrong. Please try again.',
  };
}
