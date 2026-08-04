import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phrasecards/models/view_data.dart';
import 'package:phrasecards/screens/memory_screen.dart';

void main() {
  testWidgets('shows guidance when there are not enough distinct pairs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoryScreen(
          viewData: const MemoryViewData(
            cards: [],
            canPlay: false,
            isComplete: false,
          ),
          onBack: () {},
          onSelect: (_) async {},
          onNewGame: () {},
        ),
      ),
    );

    expect(find.textContaining('Not enough distinct phrase pairs'), findsOne);
    expect(find.textContaining('different translations'), findsOne);
  });
}
