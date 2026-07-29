import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/phrase.dart';
import '../models/pronunciation.dart';
import 'buttons.dart';

class PhraseCard extends StatelessWidget {
  final Phrase phrase;
  final bool isNewPhrase;
  final bool isTurned;
  final PronunciationData pronunciation;
  final VoidCallback onPressed;
  final VoidCallback playAudio;

  const PhraseCard({
    required this.phrase,
    required this.isNewPhrase,
    required this.isTurned,
    required this.pronunciation,
    required this.onPressed,
    required this.playAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(constraints.maxWidth * 0.8, 420),
            maxHeight: constraints.maxHeight * 0.6,
          ),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Card(
              color: isTurned ? cs.primary : cs.secondary,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Center(
                    // alignment: Alignment.center,
                    child: Text(
                      isTurned ? phrase.target : phrase.source,
                      style: TextStyle(
                        fontSize: 27,
                        color: isTurned ? cs.onPrimary : cs.onSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Positioned.fill(child: InkWell(onTap: onPressed)),
                  if (isTurned)
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: SpeakerButton(
                        pronunciation: pronunciation,
                        onPressed: playAudio,
                        color: cs.onPrimary,
                      ),
                    ),
                  if (phrase.isNew)
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      child: Padding(
                        padding: EdgeInsetsGeometry.all(24),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: cs.tertiaryContainer,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "New",
                            // style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
