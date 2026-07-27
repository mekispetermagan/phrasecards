import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';

typedef CacheDirectoryProvider = Future<Directory> Function();

class PhraseAudioCache {
  final http.Client _client;
  final CacheDirectoryProvider _cacheDirectory;
  final int _downloadAttempts;
  final Map<String, Future<File>> _pending = {};

  PhraseAudioCache({
    http.Client? client,
    CacheDirectoryProvider? cacheDirectory,
    this._downloadAttempts = 2,
  }) : _client = client ?? http.Client(),
       _cacheDirectory = cacheDirectory ?? getApplicationCacheDirectory;

  Future<File> get(String audioPath) {
    return _pending.putIfAbsent(audioPath, () async {
      try {
        return await _getOrDownload(audioPath);
      } finally {
        _pending.remove(audioPath);
      }
    });
  }

  Future<File> _getOrDownload(String audioPath) async {
    final uri = Uri.parse(ApiConfig.resolveApiUrl(audioPath));
    final filename = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (filename.isEmpty || filename == '.' || filename == '..') {
      throw const FormatException('Invalid phrase audio path');
    }

    final root = await _cacheDirectory();
    final directory = Directory('${root.path}/phrasecards/audio');
    await directory.create(recursive: true);
    final destination = File('${directory.path}/$filename');
    if (await destination.exists() && await destination.length() > 0) {
      return destination;
    }

    Object? lastError;
    for (var attempt = 0; attempt < _downloadAttempts; attempt++) {
      final temporary = File('${destination.path}.download');
      try {
        final response = await _client.get(uri);
        if (response.statusCode != 200) {
          throw HttpException(
            'Audio download returned ${response.statusCode}',
            uri: uri,
          );
        }
        if (response.bodyBytes.isEmpty) {
          throw const FormatException('Downloaded phrase audio is empty');
        }
        await temporary.writeAsBytes(response.bodyBytes, flush: true);
        if (await destination.exists()) await destination.delete();
        return await temporary.rename(destination.path);
      } catch (error) {
        lastError = error;
        if (await temporary.exists()) await temporary.delete();
      }
    }
    throw lastError ?? StateError('Audio download failed');
  }
}
