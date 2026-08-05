import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PhraseViewRepository {
  Future<Map<int, int>> load();
  Future<void> save(Map<int, int> viewCounts);
}

class SharedPreferencesPhraseViewRepository implements PhraseViewRepository {
  static const _storageKey = 'phrase_view_counts_v1';

  @override
  Future<Map<int, int>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_storageKey);
      if (encoded == null) return {};
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      return {
        for (final entry in data.entries)
          if (entry.value is int) int.parse(entry.key): entry.value as int,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> save(Map<int, int> viewCounts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        for (final entry in viewCounts.entries)
          entry.key.toString(): entry.value,
      }),
    );
  }
}

class PhraseViewStore {
  final PhraseViewRepository _repository;
  Map<int, int> _viewCounts = {};

  PhraseViewStore(this._repository);

  Future<void> load() async {
    try {
      _viewCounts = await _repository.load();
    } catch (_) {
      _viewCounts = {};
    }
  }

  int viewsFor(int phraseId) => _viewCounts[phraseId] ?? 0;

  Future<int> increment(int phraseId) async {
    final nextCount = viewsFor(phraseId) + 1;
    _viewCounts[phraseId] = nextCount;
    try {
      await _repository.save(Map.unmodifiable(_viewCounts));
    } catch (_) {
      // Persistence failure must not block an offline-first game.
    }
    return nextCount;
  }
}
