import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phrasecards/api/api.dart';
import 'package:phrasecards/audio/asset_audio_player.dart';
import 'package:phrasecards/audio/pronunciation_player.dart';
import 'package:phrasecards/controllers/number_quiz_controller.dart';
import 'package:phrasecards/controllers/pronunciation_controller.dart';
import 'package:phrasecards/controllers/session_controller.dart';
import 'package:phrasecards/models/accents.dart';
import 'package:phrasecards/models/learn.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fourPhrases = '''
[
  {"id":1,"source":"One","target":"Egy","new":false,"rating":3},
  {"id":2,"source":"Two","target":"Kettő","new":false,"rating":3},
  {"id":3,"source":"Three","target":"Három","new":false,"rating":3},
  {"id":4,"source":"Four","target":"Négy","new":false,"rating":3}
]
''';

const _refreshedPhrases = '''
[
  {"id":5,"source":"Fresh one","target":"Friss egy","new":false,"rating":3},
  {"id":6,"source":"Fresh two","target":"Friss kettő","new":false,"rating":3},
  {"id":7,"source":"Fresh three","target":"Friss három","new":false,"rating":3},
  {"id":8,"source":"Fresh four","target":"Friss négy","new":false,"rating":3}
]
''';

const _phrasesWithAudio = '''
[
  {"id":1,"source":"One","target":"Egy","new":false,"rating":3,"audio_path":"/audio/one.mp3"},
  {"id":2,"source":"Two","target":"Kettő","new":false,"rating":3,"audio_path":"/audio/two.mp3"},
  {"id":3,"source":"Three","target":"Három","new":false,"rating":3,"audio_path":"/audio/three.mp3"},
  {"id":4,"source":"Four","target":"Négy","new":false,"rating":3,"audio_path":"/audio/four.mp3"}
]
''';

class _RecordingPronunciationPlayer implements PronunciationPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String audioPath) async {
    playedPaths.add(audioPath);
  }

  @override
  Future<void> stop() async {}
}

class _ControllableAssetAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];
  final playback = Completer<void>();
  int stopCount = 0;

  @override
  Future<void> play(String assetPath) {
    playedPaths.add(assetPath);
    return playback.future;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    if (!playback.isCompleted) playback.complete();
  }
}

class _ImmediateAssetAudioPlayer implements AssetAudioPlayer {
  @override
  Future<void> play(String assetPath) async {}

  @override
  Future<void> stop() async {}
}

Future<void> _waitForStatus(
  SessionController controller,
  SessionStatus expected,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (controller.status == expected) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Session did not reach $expected; current state: ${controller.status}; error: ${controller.errorMessage}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'phrase_view_counts_v1':
          '{"1":4,"2":4,"3":4,"4":4,"5":4,"6":4,"7":4,"8":4}',
    });
  });

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

    expect(
      controller.learnViewData.phrase!.source,
      isIn({'One', 'Two', 'Three', 'Four'}),
    );
    expect(controller.learnViewData.isTurned, isFalse);
    expect(controller.quizViewData.question!.options, hasLength(4));
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

  test('accents audio follows session entry and advancement only', () async {
    final player = _RecordingPronunciationPlayer();
    final pronunciation = PronunciationController(player: player);
    final api = PhrasesApi(
      client: MockClient(
        (_) async => http.Response(
          _phrasesWithAudio,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final controller = SessionController(
      api: api,
      pronunciationController: pronunciation,
    );
    addTearDown(controller.dispose);
    await _waitForStatus(controller, SessionStatus.menu);

    expect(player.playedPaths, isEmpty);

    controller.menuItems
        .singleWhere((item) => item.$1 == 'Fix the accents')
        .$2();

    expect(controller.status, SessionStatus.accents);
    expect(player.playedPaths, hasLength(1));

    controller.accentsNext();
    expect(controller.accentsViewData.phase, AccentsPhase.solving);
    expect(player.playedPaths, hasLength(1));

    final hiddenLetter = controller.accentsViewData.currentLetterData!
        .expand((word) => word)
        .firstWhere((letter) => !letter.isRevealed);
    controller.accentsOnDrop(
      dragTargetId: hiddenLetter.id,
      draggableLetter: hiddenLetter.letter,
    );
    expect(player.playedPaths, hasLength(1));

    controller.accentsNext();

    expect(player.playedPaths, hasLength(2));
    expect(player.playedPaths.toSet(), hasLength(2));
  });

  test('accents automatic playback tolerates missing audio', () async {
    final player = _RecordingPronunciationPlayer();
    final pronunciation = PronunciationController(player: player);
    final api = PhrasesApi(
      client: MockClient(
        (_) async => http.Response(
          _fourPhrases,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final controller = SessionController(
      api: api,
      pronunciationController: pronunciation,
    );
    addTearDown(controller.dispose);
    await _waitForStatus(controller, SessionStatus.menu);

    controller.menuItems
        .singleWhere((item) => item.$1 == 'Fix the accents')
        .$2();
    controller.accentsNext();

    expect(player.playedPaths, isEmpty);
  });

  test(
    'phrase building pronounces on entry and successful advancement',
    () async {
      final player = _RecordingPronunciationPlayer();
      final pronunciation = PronunciationController(player: player);
      final api = PhrasesApi(
        client: MockClient(
          (_) async => http.Response(
            _phrasesWithAudio,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final controller = SessionController(
        api: api,
        pronunciationController: pronunciation,
        assetAudioPlayer: _ImmediateAssetAudioPlayer(),
      );
      addTearDown(controller.dispose);
      await _waitForStatus(controller, SessionStatus.menu);

      expect(player.playedPaths, isEmpty);
      controller.menuItems
          .singleWhere((item) => item.$1 == 'Build phrases')
          .$2();
      expect(player.playedPaths, hasLength(1));

      final currentPath = player.playedPaths.single;
      final targetByPath = {
        '/audio/one.mp3': 'EGY',
        '/audio/two.mp3': 'KETTŐ',
        '/audio/three.mp3': 'HÁROM',
        '/audio/four.mp3': 'NÉGY',
      };
      final solution = targetByPath[currentPath]!;
      final tile = controller.phraseBuildingViewData.sourcePool.firstWhere(
        (tile) => tile.word == solution,
      );
      controller.phraseBuildingMove!(tile);
      await controller.phraseBuildingSubmit!();

      expect(player.playedPaths, hasLength(2));
      expect(player.playedPaths.last, isNot(currentPath));
    },
  );

  test('returning from quiz stops asset feedback playback', () async {
    final player = _ControllableAssetAudioPlayer();
    final api = PhrasesApi(
      client: MockClient(
        (_) async => http.Response(
          _fourPhrases,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final controller = SessionController(api: api, assetAudioPlayer: player);
    addTearDown(controller.dispose);
    await _waitForStatus(controller, SessionStatus.menu);

    controller.menuItems.singleWhere((item) => item.$1 == 'Play quiz').$2();
    final correctIndex = controller.quizViewData.question!.correctIndex;
    final submission = controller.quizSubmit!(correctIndex);
    await Future<void>.delayed(Duration.zero);

    expect(player.playedPaths, ['assets/audio/correct.mp3']);
    expect(controller.quizSubmit, isNull);

    controller.onMenu();
    await submission;

    expect(controller.status, SessionStatus.menu);
    expect(player.stopCount, 1);
  });

  test(
    'numbers entry exposes its view and returning to menu stops audio',
    () async {
      final player = _ControllableAssetAudioPlayer();
      final api = PhrasesApi(
        client: MockClient(
          (_) async => http.Response(
            _fourPhrases,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final controller = SessionController(api: api, assetAudioPlayer: player);
      addTearDown(controller.dispose);
      await _waitForStatus(controller, SessionStatus.menu);

      controller.menuItems
          .singleWhere((item) => item.$1 == 'Practice numbers')
          .$2();

      expect(controller.status, SessionStatus.numberQuiz);
      expect(controller.numberQuizViewData.options, hasLength(3));
      expect(controller.numberQuizViewData.solution, inInclusiveRange(1, 10));
      expect(controller.numberQuizSubmit, isNotNull);

      final solutionName =
          hungarianNumberNames[controller.numberQuizViewData.solution - 1];
      final correctIndex = controller.numberQuizViewData.options.indexOf(
        solutionName,
      );
      final submission = controller.numberQuizSubmit!(correctIndex);
      await Future<void>.delayed(Duration.zero);

      expect(player.playedPaths.single, endsWith('c.mp3'));
      expect(controller.numberQuizViewData.score, 1);
      expect(controller.numberQuizSubmit, isNull);

      controller.onMenu();
      await submission;

      expect(controller.status, SessionStatus.menu);
      expect(player.stopCount, 1);
    },
  );

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

  test(
    'returning to menu refreshes phrases without blocking the menu',
    () async {
      var fetches = 0;
      final refreshResponse = Completer<http.Response>();
      final api = PhrasesApi(
        client: MockClient((_) {
          fetches++;
          if (fetches == 1) {
            return Future.value(
              http.Response(
                _fourPhrases,
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            );
          }
          return refreshResponse.future;
        }),
      );
      final controller = SessionController(api: api);
      addTearDown(controller.dispose);
      await _waitForStatus(controller, SessionStatus.menu);

      controller.learnSetSelectedGroups({
        PhraseGroup.learning,
        PhraseGroup.practiced,
      });

      expect(controller.status, SessionStatus.menu);
      expect(
        controller.learnViewData.phrase!.source,
        isIn({'One', 'Two', 'Three', 'Four'}),
      );

      await Future<void>.delayed(Duration.zero);
      controller.onMenu();
      await Future<void>.delayed(Duration.zero);
      expect(fetches, 2);

      refreshResponse.complete(
        http.Response(
          _refreshedPhrases,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      for (var attempt = 0; attempt < 20; attempt++) {
        if (controller.learnViewData.phrase!.source.startsWith('Fresh ')) break;
        await Future<void>.delayed(Duration.zero);
      }

      expect(controller.learnViewData.selectedGroups, {
        PhraseGroup.learning,
        PhraseGroup.practiced,
      });
    },
  );

  test('failed menu refresh keeps the existing phrase data', () async {
    var fetches = 0;
    final api = PhrasesApi(
      client: MockClient((_) async {
        fetches++;
        return fetches == 1
            ? http.Response(
                _fourPhrases,
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )
            : http.Response('{"detail":"Offline"}', 503);
      }),
    );
    final controller = SessionController(api: api);
    addTearDown(controller.dispose);
    await _waitForStatus(controller, SessionStatus.menu);

    controller.menuItems.first.$2();
    controller.onMenu();
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, SessionStatus.menu);
    expect(
      controller.learnViewData.phrase!.source,
      isIn({'One', 'Two', 'Three', 'Four'}),
    );
    expect(fetches, 2);
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

    controller.menuItems
        .singleWhere((item) => item.$1 == 'Request a phrase')
        .$2();
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

    controller.menuItems
        .singleWhere((item) => item.$1 == 'Resolve a request')
        .$2();
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
