import 'package:flutter/material.dart';
import '../widgets/appbar.dart';
import '../widgets/phrasecard.dart';
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
          phrase: viewData.phrase,
          isNewPhrase: viewData.isNew,
          isTurned: viewData.isTurned,
          pronunciation: viewData.pronunciation,
          onPressed: turn,
          playAudio: playAudio,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'learn-next',
        onPressed: next,
        child: const Icon(Icons.navigate_next),
      ),
    );
  }
}
