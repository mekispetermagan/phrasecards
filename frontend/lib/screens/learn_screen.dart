import 'package:flutter/material.dart';

import '../models/learn.dart';
import '../models/view_data.dart';
import '../widgets/appbar.dart';
import '../widgets/phrasecard.dart';

class LearnScreen extends StatelessWidget {
  final LearnViewData viewData;
  final VoidCallback onBack;
  final VoidCallback turn;
  final Future<void> Function() next;
  final Future<void> Function() playAudio;
  final ValueChanged<Set<PhraseGroup>> setSelectedGroups;

  const LearnScreen({
    required this.viewData,
    required this.onBack,
    required this.turn,
    required this.next,
    required this.playAudio,
    required this.setSelectedGroups,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final phrase = viewData.phrase;
    return Scaffold(
      appBar: FeatureAppBar(title: 'Learn phrases', onBack: onBack),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<PhraseGroup>(
              segments: [
                for (final group in PhraseGroup.values)
                  ButtonSegment(value: group, label: Text(group.label)),
              ],
              selected: viewData.selectedGroups,
              multiSelectionEnabled: true,
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              onSelectionChanged: setSelectedGroups,
            ),
          ),
          Expanded(
            child: phrase == null
                ? const Center(
                    child: Text(
                      'No phrases in the selected groups.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : Center(
                    child: PhraseCard(
                      phrase: phrase,
                      isNewPhrase: viewData.isNew,
                      isTurned: viewData.isTurned,
                      pronunciation: viewData.pronunciation!,
                      onPressed: turn,
                      playAudio: playAudio,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'learn-next',
        onPressed: phrase == null ? null : next,
        child: const Icon(Icons.navigate_next),
      ),
    );
  }
}
