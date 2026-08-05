import 'package:flutter/material.dart';
import 'package:phrasecards/widgets/buttons.dart';

import '../models/accents.dart';
import '../models/view_data.dart';
import '../utils/string_utils.dart';
import '../widgets/appbar.dart';
import '../widgets/lettercard.dart';

class AccentsScreen extends StatelessWidget {
  final AccentedViewData viewData;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Future<void> Function() playAudio;
  final void Function({
    required String dragTargetId,
    required String draggableLetter,
  })
  onDrop;

  const AccentsScreen({
    required this.viewData,
    required this.onBack,
    required this.onNext,
    required this.onDrop,
    required this.playAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Accents game', onBack: onBack),
      body: switch (viewData.phase) {
        AccentsPhase.unavailable => const Center(
          child: Text(
            'No suitable accent exercises found.',
            style: TextStyle(fontSize: 18),
          ),
        ),
        AccentsPhase.completed => const Center(
          child: Text(
            'You completed all accent exercises.',
            style: TextStyle(fontSize: 18),
          ),
        ),
        AccentsPhase.solving || AccentsPhase.solved => _buildExercise(context),
      },
    );
  }

  Widget _buildExercise(BuildContext context) {
    final currentLetterData = viewData.currentLetterData!;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                children: [
                  for (final wordData in currentLetterData)
                    Wrap(
                      children: <Widget>[
                        for (final letter in wordData)
                          !letter.isRevealed
                              ? DragTargetLetterCard(
                                  letter: letter,
                                  onDrop: onDrop,
                                )
                              : alphabetHU.contains(letter.letter)
                              ? LetterCard(
                                  letter: letter,
                                  backgroundColor: colorScheme.primaryContainer,
                                  foregroundColor:
                                      colorScheme.onPrimaryContainer,
                                )
                              : LetterCard(
                                  letter: letter,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: colorScheme.onSurface,
                                ),
                      ],
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    for (final letter in viewData.accentedVowelData)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: DraggableLetterCard(letter: letter),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    viewData.pronunciation == null
                        ? const SizedBox.shrink()
                        : SpeakerButton(
                            pronunciation: viewData.pronunciation!,
                            onPressed: playAudio,
                          ),
                    FilledButton(
                      onPressed: viewData.phase == AccentsPhase.solved
                          ? onNext
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Next', style: TextStyle(fontSize: 21)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
