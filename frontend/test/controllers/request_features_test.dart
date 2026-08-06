import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phrasecards/api/api.dart';
import 'package:phrasecards/controllers/request_submission_controller.dart';
import 'package:phrasecards/controllers/resolution_controller.dart';
import 'package:phrasecards/models/phrase_request.dart';
import 'package:phrasecards/models/view_data.dart';

void main() {
  test('request submission validates and submits trimmed source', () async {
    final api = RequestsApi(
      client: MockClient((request) async {
        expect(request.body, '{"source":"Good afternoon!"}');
        return http.Response('{"id":1,"source":"Good afternoon!"}', 201);
      }),
    );
    final controller = RequestSubmissionController(api);
    addTearDown(controller.dispose);

    expect(controller.viewData.canSubmit, isFalse);

    controller.updateSource('  Good afternoon!  ');
    expect(controller.viewData.canSubmit, isTrue);

    expect(await controller.submit(), isTrue);
    expect(controller.viewData.source, isEmpty);
    expect(controller.viewData.isSubmitting, isFalse);
  });

  test('request submission exposes conflict detail', () async {
    final api = RequestsApi(
      client: MockClient(
        (_) async =>
            http.Response('{"detail":"Phrase request already exists"}', 409),
      ),
    );
    final controller = RequestSubmissionController(api);
    addTearDown(controller.dispose);

    controller.updateSource('Duplicate');

    expect(await controller.submit(), isFalse);
    expect(controller.viewData.errorMessage, 'Phrase request already exists');
  });

  test('opening a fresh request ignores a stale submission response', () async {
    final response = Completer<http.Response>();
    final api = RequestsApi(client: MockClient((_) => response.future));
    final controller = RequestSubmissionController(api);
    addTearDown(controller.dispose);

    controller.updateSource('Old request');
    final submission = controller.submit();
    expect(controller.viewData.isSubmitting, isTrue);

    controller.open();
    response.complete(http.Response('{"id":1,"source":"Old request"}', 201));

    expect(await submission, isFalse);
    expect(controller.viewData.source, isEmpty);
    expect(controller.viewData.isSubmitting, isFalse);
    expect(controller.viewData.errorMessage, isNull);
  });

  test('resolution loads, edits, submits, and refreshes requests', () async {
    var fetchCount = 0;
    final api = RequestsApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/requests' && request.method == 'GET') {
          fetchCount++;
          return http.Response(
            fetchCount == 1 ? '[{"id":4,"source":"Good afternon!"}]' : '[]',
            200,
          );
        }

        expect(request.url.path, '/api/requests/resolve');
        expect(
          request.body,
          '{"request_id":4,"source":"Good afternoon!","target":"Jó napot!"}',
        );
        return http.Response(
          '{"id":8,"source":"Good afternoon!","target":"Jó napot!",'
          '"new":true,"rating":3}',
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final controller = ResolutionController(api);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.listViewData.status, RequestListStatus.ready);
    expect(controller.listViewData.requests, hasLength(1));

    controller.select(const PhraseRequest(id: 4, source: 'Good afternon!'));
    expect(controller.formViewData.source, 'Good afternon!');
    expect(controller.formViewData.canSubmit, isFalse);

    controller.updateSource('Good afternoon!');
    controller.updateTarget('Jó napot!');
    expect(controller.formViewData.canSubmit, isTrue);

    expect(await controller.submit(), isTrue);
    expect(controller.listViewData.requests, isEmpty);
    expect(fetchCount, 2);
  });

  test('resolution exposes list loading failure', () async {
    final api = RequestsApi(
      client: MockClient(
        (_) async => http.Response('{"detail":"Unavailable"}', 503),
      ),
    );
    final controller = ResolutionController(api);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.listViewData.status, RequestListStatus.error);
    expect(controller.listViewData.errorMessage, 'Unavailable');
  });

  test('resolution ignores an older list response', () async {
    final firstResponse = Completer<http.Response>();
    final secondResponse = Completer<http.Response>();
    var requestCount = 0;
    final api = RequestsApi(
      client: MockClient((_) {
        requestCount++;
        return requestCount == 1 ? firstResponse.future : secondResponse.future;
      }),
    );
    final controller = ResolutionController(api);
    addTearDown(controller.dispose);

    final firstLoad = controller.load();
    final secondLoad = controller.load();

    secondResponse.complete(http.Response('[]', 200));
    await secondLoad;
    firstResponse.complete(http.Response('[{"id":9,"source":"Stale"}]', 200));
    await firstLoad;

    expect(controller.listViewData.status, RequestListStatus.ready);
    expect(controller.listViewData.requests, isEmpty);
  });
}
