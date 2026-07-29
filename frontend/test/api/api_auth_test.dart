import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wordcards/api/api.dart';

void main() {
  test('API clients attach the configured app key', () async {
    final seenPaths = <String>[];
    final client = MockClient((request) async {
      expect(request.headers['x-phrasecards-key'], 'test-key');
      seenPaths.add(request.url.path);
      if (request.url.path == '/api/phrases') {
        return http.Response('[]', 200);
      }
      return http.Response('[]', 200);
    });

    await PhrasesApi(client: client, apiKey: 'test-key').fetchPhrases();
    await RequestsApi(client: client, apiKey: 'test-key').fetchRequests();

    expect(seenPaths, ['/api/phrases', '/api/requests']);
  });
}
