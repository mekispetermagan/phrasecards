import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phrasecards/audio/phrase_audio_cache.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'phrasecards-audio-test-',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('downloads once and then reuses the application cache file', () async {
    var requests = 0;
    final cache = PhraseAudioCache(
      client: MockClient((request) async {
        requests++;
        expect(request.url.path, '/audio/phrase-7-hash.mp3');
        return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
      }),
      cacheDirectory: () async => temporaryDirectory,
    );

    final first = await cache.get('/audio/phrase-7-hash.mp3');
    final second = await cache.get('/audio/phrase-7-hash.mp3');

    expect(first.path, second.path);
    expect(await first.readAsBytes(), [1, 2, 3]);
    expect(requests, 1);
    expect(first.path, contains('/phrasecards/audio/'));
  });

  test('retries a failed download without leaving a partial file', () async {
    var requests = 0;
    final cache = PhraseAudioCache(
      client: MockClient((_) async {
        requests++;
        if (requests == 1) return http.Response('try again', 503);
        return http.Response.bytes(Uint8List.fromList([4, 5]), 200);
      }),
      cacheDirectory: () async => temporaryDirectory,
    );

    final file = await cache.get('/audio/phrase-8-hash.mp3');

    expect(requests, 2);
    expect(await file.readAsBytes(), [4, 5]);
    expect(
      Directory(file.parent.path).listSync().whereType<File>().where(
        (candidate) => candidate.path.endsWith('.download'),
      ),
      isEmpty,
    );
  });
}
