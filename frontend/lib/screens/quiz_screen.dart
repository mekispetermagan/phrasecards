import 'package:flutter/material.dart';
import '../widgets/appbar.dart';
import '../models/view_data.dart';

class QuizScreen extends StatelessWidget {
  final QuizViewData viewData;
  // final String source;
  // final List<String> options;
  // final int score;
  // final int? correctHighlightIndex;
  // final int? wrongHighlightIndex;
  final VoidCallback onBack;
  final Future<void> Function(int) submit;

  const QuizScreen({
    required this.viewData,
    // required this.source,
    // required this.options,
    // required this.score,
    // required this.correctHighlightIndex,
    // required this.wrongHighlightIndex,
    required this.onBack,
    required this.submit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: "Play a quiz", onBack: onBack),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              viewData.question.source,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            ...[
              for (int i = 0; i < viewData.question.options.length; i++)
                FilledButton(
                  onPressed: () => submit(i),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      i == viewData.correctHighlightIndex
                          ? Colors.green
                          : i == viewData.wrongHighlightIndex
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      viewData.question.options[i],
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
