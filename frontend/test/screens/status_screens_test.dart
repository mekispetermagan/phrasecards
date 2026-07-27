import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordcards/screens/error_screen.dart';
import 'package:wordcards/screens/loading_screen.dart';

void main() {
  testWidgets('loading screen displays a progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error screen displays the server error message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorScreen()));

    expect(find.text('Server error'), findsOneWidget);
  });
}
