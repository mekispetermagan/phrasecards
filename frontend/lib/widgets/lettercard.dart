import 'package:flutter/material.dart';

import '../models/letter_data.dart';

class LetterCard extends StatelessWidget {
  final LetterData letter;
  final Color backgroundColor;
  final Color foregroundColor;

  const LetterCard({
    required this.letter,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Card(
        color: backgroundColor,
        child: Center(
          child: Text(
            letter.isRevealed ? letter.letter : '?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class DraggableLetterCard extends StatelessWidget {
  final LetterData letter;

  const DraggableLetterCard({required this.letter, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Draggable<LetterData>(
      data: letter,
      feedback: LetterCard(
        letter: letter,
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
      ),
      child: LetterCard(
        letter: letter,
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
      ),
    );
  }
}

class DragTargetLetterCard extends StatelessWidget {
  final LetterData letter;
  final void Function({
    required String dragTargetId,
    required String draggableLetter,
  })
  onDrop;

  const DragTargetLetterCard({
    required this.letter,
    required this.onDrop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<LetterData>(
      onWillAcceptWithDetails: (details) {
        return details.data.letter == letter.letter;
      },
      onAcceptWithDetails: (details) {
        onDrop(dragTargetId: letter.id, draggableLetter: details.data.letter);
      },
      builder: (context, candidateData, rejectedData) {
        return LetterCard(
          letter: letter,
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
        );
      },
    );
  }
}
