import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordcards/models/phrase_request.dart';
import 'package:wordcards/models/view_data.dart';
import 'package:wordcards/screens/request_screen.dart';
import 'package:wordcards/screens/resolution_form_screen.dart';
import 'package:wordcards/screens/resolve_screen.dart';

void main() {
  testWidgets('request screen forwards text and submission', (tester) async {
    String? changed;
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RequestScreen(
          viewData: const RequestSubmissionViewData(
            source: '',
            isSubmitting: false,
            canSubmit: true,
            errorMessage: null,
          ),
          onBack: () {},
          onSourceChanged: (value) => changed = value,
          onSubmit: () => submitted = true,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Good afternoon!');
    await tester.tap(find.text('Submit'));

    expect(changed, 'Good afternoon!');
    expect(submitted, isTrue);
  });

  testWidgets('resolution list displays and selects requests', (tester) async {
    PhraseRequest? selected;
    const request = PhraseRequest(id: 2, source: 'Good afternon!');

    await tester.pumpWidget(
      MaterialApp(
        home: ResolveScreen(
          viewData: const RequestListViewData(
            status: RequestListStatus.ready,
            requests: [request],
            errorMessage: null,
          ),
          onBack: () {},
          onRetry: () {},
          onSelect: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('Good afternon!'), findsOneWidget);

    await tester.tap(find.text('Good afternon!'));

    expect(selected?.id, 2);
  });

  testWidgets('resolution form edits source and target', (tester) async {
    String? source;
    String? target;
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ResolutionFormScreen(
          viewData: const ResolutionFormViewData(
            requestId: 2,
            source: 'Good afternon!',
            target: '',
            isSubmitting: false,
            canSubmit: true,
            errorMessage: null,
          ),
          onBack: () {},
          onSourceChanged: (value) => source = value,
          onTargetChanged: (value) => target = value,
          onSubmit: () => submitted = true,
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'Good afternoon!');
    await tester.enterText(fields.at(1), 'Jó napot!');
    await tester.tap(find.text('Resolve'));

    expect(source, 'Good afternoon!');
    expect(target, 'Jó napot!');
    expect(submitted, isTrue);
  });

  testWidgets('resolution list has an explicit empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResolveScreen(
          viewData: const RequestListViewData(
            status: RequestListStatus.ready,
            requests: [],
            errorMessage: null,
          ),
          onBack: () {},
          onRetry: () {},
          onSelect: (_) {},
        ),
      ),
    );

    expect(find.text('No pending requests'), findsOneWidget);
  });
}
