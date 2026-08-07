import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import '../models/phrasebuilding_state.dart';
import '../models/phrasebuilding_tile.dart';

class PhraseBuildingCard extends StatelessWidget {
  final PhraseBuildingTile tile;
  final PhraseBuildingState state;
  final void Function(PhraseBuildingTile)? move;

  const PhraseBuildingCard({
    required this.tile,
    required this.state,
    required this.move,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme guessingScheme = Theme.of(context).colorScheme;
    // Harmonizing green for success feedback.
    final ColorScheme successScheme = ColorScheme.fromSeed(
      seedColor: Colors.green.harmonizeWith(guessingScheme.primary),
      brightness: guessingScheme.brightness,
    );
    // Harmonizing red for failure feedback.
    final ColorScheme failureScheme = ColorScheme.fromSeed(
      seedColor: Colors.red.harmonizeWith(guessingScheme.primary),
      brightness: guessingScheme.brightness,
    );
    final ColorScheme colorScheme = switch (state) {
      PhraseBuildingState.guessing => guessingScheme,
      PhraseBuildingState.successFeedback => successScheme,
      PhraseBuildingState.failureFeedback => failureScheme,
    };

    return Card(
      color: colorScheme.secondaryContainer,
      child: InkWell(
        onTap: move == null ? null : () => move!(tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            tile.word,
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
