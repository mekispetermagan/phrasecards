import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';
import '_api_support.dart';

class ResolveResult {
  final Phrase? phrase;
  final Failure? failure;
  final String? message;

  const ResolveResult.success({required this.phrase})
    : failure = null,
      message = null;

  const ResolveResult.failure({required this.failure, this.message})
    : phrase = null;
}

class PhraseListResult {
  final List<Phrase>? phrases;
  final Failure? failure;
  final String? message;

  const PhraseListResult.success({required this.phrases})
    : failure = null,
      message = null;

  const PhraseListResult.failure({required this.failure, this.message})
    : phrases = null;
}

class PhraseRequestResult {
  final PhraseRequest? request;
  final Failure? failure;
  final String? message;

  const PhraseRequestResult.success({required this.request})
    : failure = null,
      message = null;

  const PhraseRequestResult.failure({required this.failure, this.message})
    : request = null;
}

class PhraseRequestListResult {
  final List<PhraseRequest>? requests;
  final Failure? failure;
  final String? message;

  const PhraseRequestListResult.success({required this.requests})
    : failure = null,
      message = null;

  const PhraseRequestListResult.failure({required this.failure, this.message})
    : requests = null;
}

class PhrasesApi {
  final http.Client _client;
  final Map<String, String> _headers;

  PhrasesApi({http.Client? client, String apiKey = ApiConfig.apiKey})
    : _client = client ?? http.Client(),
      _headers = _apiHeaders(apiKey);

  Future<PhraseListResult> fetchPhrases() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/phrases');

    try {
      final response = await _client.get(uri, headers: _headers);

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final phrases = (data as List<dynamic>)
            .map((item) => Phrase.fromJson(item as Map<String, dynamic>))
            .toList();

        return PhraseListResult.success(phrases: phrases);
      }

      return PhraseListResult.failure(
        failure: failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const PhraseListResult.failure(failure: Failure.invalidData);
      }
      return const PhraseListResult.failure(failure: Failure.networkError);
    }
  }
}

class RequestsApi {
  final http.Client _client;
  final Map<String, String> _headers;

  RequestsApi({http.Client? client, String apiKey = ApiConfig.apiKey})
    : _client = client ?? http.Client(),
      _headers = _apiHeaders(apiKey);

  Future<PhraseRequestListResult> fetchRequests() async {
    final uri = Uri.parse(ApiConfig.baseUrl).resolve("/api/requests");

    try {
      final response = await _client.get(uri, headers: _headers);
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final requests = (data as List<dynamic>)
            .map((item) => PhraseRequest.fromJson(item as Map<String, dynamic>))
            .toList();
        return PhraseRequestListResult.success(requests: requests);
      }

      return PhraseRequestListResult.failure(
        failure: failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const PhraseRequestListResult.failure(
          failure: Failure.invalidData,
        );
      }
      return const PhraseRequestListResult.failure(
        failure: Failure.networkError,
      );
    }
  }

  Future<PhraseRequestResult> submitRequest(String source) async {
    final uri = Uri.parse(ApiConfig.baseUrl).resolve("/api/requests");

    try {
      final response = await _client.post(
        uri,
        headers: {..._headers, "content-type": "application/json"},
        body: jsonEncode({"source": source}),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 201) {
        return PhraseRequestResult.success(
          request: PhraseRequest.fromJson(data as Map<String, dynamic>),
        );
      }

      return PhraseRequestResult.failure(
        failure: failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const PhraseRequestResult.failure(failure: Failure.invalidData);
      }
      return const PhraseRequestResult.failure(failure: Failure.networkError);
    }
  }

  Future<ResolveResult> resolveRequest({
    required int requestId,
    required String source,
    required String target,
  }) async {
    final uri = Uri.parse(ApiConfig.baseUrl).resolve("/api/requests/resolve");

    try {
      final response = await _client.post(
        uri,
        headers: {..._headers, "content-type": "application/json"},
        body: jsonEncode({
          "request_id": requestId,
          "source": source,
          "target": target,
        }),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 201) {
        return ResolveResult.success(
          phrase: Phrase.fromJson(data as Map<String, dynamic>),
        );
      }

      return ResolveResult.failure(
        failure: failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const ResolveResult.failure(failure: Failure.invalidData);
      }
      return const ResolveResult.failure(failure: Failure.networkError);
    }
  }
}

Map<String, String> _apiHeaders(String apiKey) {
  if (apiKey.isEmpty) return const {};
  return {"X-PhraseCards-Key": apiKey};
}
