import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wordcards/api/_api_support.dart';
import 'package:wordcards/api/api.dart';

void main() {
  test('fetchPhrases sends GET and decodes phrases', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/phrases');

      return http.Response(
        '''
        [
          {
            "id": 1,
            "source": "Good morning!",
            "target": "Jó reggelt!",
            "new": false,
            "rating": 3,
            "audio_path": "/audio/phrase-1-hash.mp3"
          }
        ]
        ''',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await PhrasesApi(client: client).fetchPhrases();

    expect(result.failure, isNull);
    expect(result.phrases, hasLength(1));
    expect(result.phrases!.single.source, 'Good morning!');
    expect(result.phrases!.single.target, 'Jó reggelt!');
    expect(result.phrases!.single.isNew, isFalse);
    expect(result.phrases!.single.rating, 3);
    expect(result.phrases!.single.id, 1);
    expect(result.phrases!.single.audioPath, '/audio/phrase-1-hash.mp3');
  });

  test('fetchPhrases preserves an API error and detail', () async {
    final client = MockClient(
      (_) async => http.Response('{"detail":"Phrases unavailable"}', 503),
    );

    final result = await PhrasesApi(client: client).fetchPhrases();

    expect(result.phrases, isNull);
    expect(result.failure, Failure.serverError);
    expect(result.message, 'Phrases unavailable');
  });

  test('fetchPhrases reports invalid response data', () async {
    final client = MockClient(
      (_) async => http.Response('{"not":"a list"}', 200),
    );

    final result = await PhrasesApi(client: client).fetchPhrases();

    expect(result.phrases, isNull);
    expect(result.failure, Failure.invalidData);
  });

  test('fetchPhrases reports network errors', () async {
    final client = MockClient((_) async {
      throw const SocketException('offline');
    });

    final result = await PhrasesApi(client: client).fetchPhrases();

    expect(result.phrases, isNull);
    expect(result.failure, Failure.networkError);
  });

  test('markPhraseSeen patches the phrase progress endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/phrases/7/seen');
      return http.Response('', 204);
    });

    final marked = await PhrasesApi(client: client).markPhraseSeen(7);

    expect(marked, isTrue);
  });

  test('markPhraseSeen reports an unsuccessful response', () async {
    final client = MockClient((_) async => http.Response('not found', 404));

    final marked = await PhrasesApi(client: client).markPhraseSeen(7);

    expect(marked, isFalse);
  });

  test("fetchRequests returns ids and sources", () async {
    final client = MockClient((request) async {
      expect(request.method, "GET");
      expect(request.url.path, "/api/requests");
      return http.Response("""[{"id":7,"source":"Good afternon!"}]""", 200);
    });

    final result = await RequestsApi(client: client).fetchRequests();

    expect(result.requests, hasLength(1));
    expect(result.requests!.single.id, 7);
    expect(result.requests!.single.source, "Good afternon!");
  });

  test("submitRequest sends structured JSON", () async {
    final client = MockClient((request) async {
      expect(request.method, "POST");
      expect(request.url.path, "/api/requests");
      expect(request.headers["content-type"], "application/json");
      expect(request.body, """{"source":"Good afternoon!"}""");
      return http.Response("""{"id":3,"source":"Good afternoon!"}""", 201);
    });

    final result = await RequestsApi(
      client: client,
    ).submitRequest("Good afternoon!");

    expect(result.request!.id, 3);
    expect(result.request!.source, "Good afternoon!");
  });

  test("resolveRequest sends id and corrected strings", () async {
    final client = MockClient((request) async {
      expect(request.method, "POST");
      expect(request.url.path, "/api/requests/resolve");
      expect(
        request.body,
        """{"request_id":7,"source":"Good afternoon!","target":"Jó napot!"}""",
      );
      return http.Response(
        """{"id":8,"source":"Good afternoon!","target":"Jó napot!","new":true,"rating":3}""",
        201,
        headers: {"content-type": "application/json; charset=utf-8"},
      );
    });

    final result = await RequestsApi(client: client).resolveRequest(
      requestId: 7,
      source: "Good afternoon!",
      target: "Jó napot!",
    );

    expect(result.phrase!.source, "Good afternoon!");
    expect(result.phrase!.target, "Jó napot!");
    expect(result.phrase!.isNew, isTrue);
    expect(result.phrase!.rating, 3);
  });

  test("request API preserves conflict details", () async {
    final client = MockClient(
      (_) async =>
          http.Response("""{"detail":"Phrase request already exists"}""", 409),
    );

    final result = await RequestsApi(client: client).submitRequest("Duplicate");

    expect(result.failure, Failure.conflict);
    expect(result.message, "Phrase request already exists");
  });
}
