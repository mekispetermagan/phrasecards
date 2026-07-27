import 'package:flutter/material.dart';
import '../widgets/appbar.dart';
import '../widgets/buttons.dart';
import '../models/view_data.dart';

class LearnScreen extends StatelessWidget {
  final LearnViewData viewData;
  final VoidCallback onBack;
  final VoidCallback turn;
  final VoidCallback next;
  final Future<void> Function() playAudio;

  const LearnScreen({
    required this.viewData,
    required this.onBack,
    required this.turn,
    required this.next,
    required this.playAudio,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: "Learn phrases", onBack: onBack),
      body: Center(
        child: PhraseCard(
          primaryPhrase: viewData.phrase.source,
          secondaryPhrase: viewData.phrase.target,
          isTurned: viewData.isTurned,
          onPressed: turn,
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (viewData.isTurned && viewData.phrase.audioPath != null) ...[
            FloatingActionButton.small(
              heroTag: 'phrase-audio',
              tooltip: viewData.audioError ?? 'Play pronunciation',
              onPressed: viewData.isPlayingAudio ? null : playAudio,
              child: viewData.isPlayingAudio
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.volume_up,
                      color: viewData.audioError == null ? null : Colors.red,
                    ),
            ),
            const SizedBox(width: 12),
          ],
          FloatingActionButton(
            heroTag: 'learn-next',
            onPressed: next,
            child: const Icon(Icons.navigate_next),
          ),
        ],
      ),
    );
  }
}
