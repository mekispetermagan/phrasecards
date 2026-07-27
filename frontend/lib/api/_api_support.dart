import 'dart:convert';

enum Failure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

bool isInvalidApiData(Object error) {
  return error is FormatException || error is TypeError;
}

Failure failureFromStatusCode(int statusCode) {
  return switch (statusCode) {
    400 || 422 => Failure.badRequest,
    401 => Failure.unauthorized,
    403 => Failure.forbidden,
    404 => Failure.notFound,
    409 => Failure.conflict,
    _ => Failure.serverError,
  };
}

String? apiDetail(Object? data) {
  if (data is Map<String, dynamic>) return data['detail']?.toString();
  return null;
}

Object? decodeJsonBody(String body) {
  if (body.trim().isEmpty) return null;
  return jsonDecode(body);
}
