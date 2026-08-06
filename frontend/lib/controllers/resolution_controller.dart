import 'package:flutter/foundation.dart';

import '../api/_api_support.dart';
import '../api/api.dart';
import '../models/phrase_request.dart';
import '../models/view_data.dart';

class ResolutionController extends ChangeNotifier {
  final RequestsApi _api;

  RequestListStatus _status = RequestListStatus.loading;
  List<PhraseRequest> _requests = const [];
  PhraseRequest? _selected;
  String _source = '';
  String _target = '';
  bool _isSubmitting = false;
  String? _errorMessage;
  int _operation = 0;
  bool _disposed = false;

  ResolutionController(this._api);

  RequestListViewData get listViewData => RequestListViewData(
    status: _status,
    requests: List.unmodifiable(_requests),
    errorMessage: _errorMessage,
  );

  ResolutionFormViewData get formViewData {
    final selected =
        _selected ??
        (throw StateError('Resolution form accessed without a request'));

    return ResolutionFormViewData(
      requestId: selected.id,
      source: _source,
      target: _target,
      isSubmitting: _isSubmitting,
      canSubmit:
          !_isSubmitting &&
          _source.trim().isNotEmpty &&
          _source.trim().length <= 255 &&
          _target.trim().isNotEmpty &&
          _target.trim().length <= 255,
      errorMessage: _errorMessage,
    );
  }

  Future<void> load() async {
    final operation = ++_operation;
    _status = RequestListStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _api.fetchRequests();
    if (_disposed || operation != _operation) return;
    if (result.requests == null) {
      _status = RequestListStatus.error;
      _errorMessage = _failureMessage(result.failure, result.message);
      notifyListeners();
      return;
    }

    _requests = result.requests!;
    _status = RequestListStatus.ready;
    notifyListeners();
  }

  void select(PhraseRequest request) {
    _operation++;
    _selected = request;
    _source = request.source;
    _target = '';
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  void updateSource(String value) {
    _source = value;
    _errorMessage = null;
    notifyListeners();
  }

  void updateTarget(String value) {
    _target = value;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (!formViewData.canSubmit) return false;

    final operation = ++_operation;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final selected = _selected!;
    final result = await _api.resolveRequest(
      requestId: selected.id,
      source: _source.trim(),
      target: _target.trim(),
    );
    if (_disposed || operation != _operation) return false;

    if (result.phrase == null) {
      _isSubmitting = false;
      _errorMessage = _failureMessage(result.failure, result.message);
      notifyListeners();
      return false;
    }

    _isSubmitting = false;
    await load();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    super.dispose();
  }
}

String _failureMessage(Failure? failure, String? detail) {
  if (detail != null && detail.isNotEmpty) return detail;
  return switch (failure) {
    Failure.notFound => 'This request no longer exists.',
    Failure.conflict => 'A phrase with this source already exists.',
    Failure.networkError => 'Could not reach the server.',
    Failure.invalidData => 'The server returned invalid data.',
    Failure.badRequest => 'Please check the submitted text.',
    _ => 'Something went wrong. Please try again.',
  };
}
