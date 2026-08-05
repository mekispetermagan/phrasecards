import 'package:flutter/material.dart';

import '../models/view_data.dart';
import '../widgets/appbar.dart';
import '../widgets/buttons.dart';

class QuizScreen extends StatelessWidget {
  final QuizViewData viewData;
  final VoidCallback onBack;
  final Future<void> Function(int) submit;
  final Future<void> Function(int) playAudio;
  final ValueChanged<bool> setShowPronunciationButtons;

  const QuizScreen({
    required this.viewData,
    required this.onBack,
    required this.submit,
    required this.playAudio,
    required this.setShowPronunciationButtons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final question = viewData.question;
    return Scaffold(
      appBar: FeatureAppBar(title: 'Play a quiz', onBack: onBack),
      body: question == null
          ? const Center(
              child: Text(
                'View a phrase at least four times to unlock it for quizzes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    title: const Text('Show pronunciation buttons'),
                    value: viewData.showPronunciationButtons,
                    onChanged: setShowPronunciationButtons,
                  ),
                  Text(
                    question.source,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  for (int i = 0; i < question.options.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
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
                                question.options[i].text,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        if (viewData.showPronunciationButtons)
                          SpeakerButton(
                            pronunciation: viewData.optionPronunciations[i],
                            onPressed: () => playAudio(i),
                          ),
                      ],
                    ),
                  Text(
                    'Score: ${viewData.score}/${viewData.maxScore}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
    );
  }
}
