import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/storage/phrase_view_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'phrase_view_counts_v1': '{"7":3,"9":25}',
    });
  });

  test('loads and persists view counts in shared preferences', () async {
    final repository = SharedPreferencesPhraseViewRepository();
    final store = PhraseViewStore(repository);

    await store.load();

    expect(store.viewsFor(7), 3);
    expect(store.viewsFor(8), 0);
    expect(store.viewsFor(9), 25);

    await store.increment(7);

    final reloaded = PhraseViewStore(repository);
    await reloaded.load();
    expect(reloaded.viewsFor(7), 4);
  });
}
