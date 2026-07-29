import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phrasecards/api/api.dart';
import 'package:phrasecards/controllers/session_controller.dart';
import 'package:phrasecards/models/view_data.dart';

const _fourPhrases = '''
[
  {"id":1,"source":"One","target":"Egy","new":false,"rating":3},
  {"id":2,"source":"Two","target":"Kettő","new":false,"rating":3},
  {"id":3,"source":"Three","target":"Három","new":false,"rating":3},
  {"id":4,"source":"Four","target":"Négy","new":false,"rating":3}
]
''';

Future<void> _waitForStatus(
  SessionController controller,
  SessionStatus expected,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (controller.status == expected) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Session did not reach $expected; current state: ${controller.status}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts in loading while the request is pending', () {
    final response = Completer<http.Response>();
    final api = PhrasesApi(client: MockClient((_) => response.future));
    final controller = SessionController(api: api);
    addTearDown(controller.dispose);

    expect(controller.status, SessionStatus.loading);

    response.complete(http.Response('Server error', 500));
  });

  test('successful loading initializes features and opens the menu', () async {
    final api = PhrasesApi(
      client: MockClient(
        (_) async => http.Response(
          _fourPhrases,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final controller = SessionController(api: api);
    addTearDown(controller.dispose);

    await _waitForStatus(controller, SessionStatus.menu);

    expect(controller.learnViewData.phrase.source, 'One');
    expect(controller.learnViewData.isTurned, isFalse);
    expect(controller.quizViewData.question.options, hasLength(4));
    expect(controller.quizViewData.showPronunciationButtons, isFalse);

    controller.quizSetShowPronunciationButtons(false);
    expect(controller.quizViewData.showPronunciationButtons, isFalse);

    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.menuItems.first.$2();
    expect(controller.status, SessionStatus.learn);

    controller.learnTurnCard();
    expect(controller.learnViewData.isTurned, isTrue);
    expect(notifications, 2);
  });

  test('failed loading exposes an error state and message', () async {
    final api = PhrasesApi(
      client: MockClient(
        (_) async => http.Response('{"detail":"Service unavailable"}', 503),
      ),
    );
    final controller = SessionController(api: api);
    addTearDown(controller.dispose);

    await _waitForStatus(controller, SessionStatus.error);

    expect(controller.errorMessage, 'Service unavailable');
  });

  test('rejects phrase sets without four distinct translations', () async {
    final api = PhrasesApi(
      client: MockClient(
        (_) async => http.Response('''
          [
            {"id":1,"source":"One","target":"Same","new":false,"rating":3},
            {"id":2,"source":"Two","target":"Same","new":false,"rating":3},
            {"id":3,"source":"Three","target":"Same","new":false,"rating":3},
            {"id":4,"source":"Four","target":"Same","new":false,"rating":3}
          ]
          ''', 200),
      ),
    );
    final controller = SessionController(api: api);
    addTearDown(controller.dispose);

    await _waitForStatus(controller, SessionStatus.error);

    expect(controller.errorMessage, contains('four phrases'));
  });

  test('retry returns to loading and can recover', () async {
    var requestCount = 0;
    final secondResponse = Completer<http.Response>();
    final api = PhrasesApi(
      client: MockClient((_) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('{"detail":"Temporary failure"}', 503);
        }
        return secondResponse.future;
      }),
    );
    final controller = SessionController(api: api);
    addTearDown(controller.dispose);

    await _waitForStatus(controller, SessionStatus.error);

    final retry = controller.retry();
    expect(controller.status, SessionStatus.loading);

    secondResponse.complete(
      http.Response(
        _fourPhrases,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await retry;

    expect(controller.status, SessionStatus.menu);
    expect(controller.errorMessage, isNull);
  });

  test("request submission returns the session to menu", () async {
    final phraseApi = PhrasesApi(
      client: MockClient(
        (_) async => http.Response(
          _fourPhrases,
          200,
          headers: {"content-type": "application/json; charset=utf-8"},
        ),
      ),
    );
    final requestApi = RequestsApi(
      client: MockClient(
        (_) async =>
            http.Response("""{"id":9,"source":"Good afternoon!"}""", 201),
      ),
    );
    final controller = SessionController(
      api: phraseApi,
      requestsApi: requestApi,
    );
    addTearDown(controller.dispose);
    await _waitForStatus(controller, SessionStatus.menu);

    controller.menuItems[2].$2();
    expect(controller.status, SessionStatus.request);

    controller.requestUpdateSource("Good afternoon!");
    await controller.requestSubmit();

    expect(controller.status, SessionStatus.menu);
    expect(controller.takeNotice(), SessionNotice.requestSubmitted);
    expect(controller.takeNotice(), isNull);
  });

  test("resolution moves from list to form and back to refreshed list", () async {
    final phraseApi = PhrasesApi(
      client: MockClient(
        (_) async => http.Response(
          _fourPhrases,
          200,
          headers: {"content-type": "application/json; charset=utf-8"},
        ),
      ),
    );
    var listFetches = 0;
    final requestApi = RequestsApi(
      client: MockClient((request) async {
        if (request.url.path == "/api/requests" && request.method == "GET") {
          listFetches++;
          return http.Response(
            listFetches == 1
                ? """[{"id":2,"source":"Good afternon!"}]"""
                : "[]",
            200,
          );
        }
        return http.Response(
          """{"id":9,"source":"Good afternoon!","target":"Jó napot!","new":true,"rating":3}""",
          201,
          headers: {"content-type": "application/json; charset=utf-8"},
        );
      }),
    );
    final controller = SessionController(
      api: phraseApi,
      requestsApi: requestApi,
    );
    addTearDown(controller.dispose);
    await _waitForStatus(controller, SessionStatus.menu);

    controller.menuItems[3].$2();
    for (var attempt = 0; attempt < 20; attempt++) {
      if (controller.requestListViewData.status == RequestListStatus.ready) {
        break;
      }
      await Future<void>.delayed(Duration.zero);
    }
    final request = controller.requestListViewData.requests.single;
    controller.resolutionSelect(request);
    expect(controller.status, SessionStatus.resolveForm);

    controller.resolutionUpdateSource("Good afternoon!");
    controller.resolutionUpdateTarget("Jó napot!");
    await controller.resolutionSubmit();

    expect(controller.status, SessionStatus.resolve);
    expect(controller.requestListViewData.requests, isEmpty);
  });
}
