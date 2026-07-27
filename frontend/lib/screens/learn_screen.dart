import 'package:flutter/material.dart';
import '../widgets/appbar.dart';
import '../widgets/buttons.dart';
import '../models/view_data.dart';

class LearnScreen extends StatelessWidget {
  final LearnViewData viewData;
  final VoidCallback onBack;
  final VoidCallback turn;
  final VoidCallback next;

  const LearnScreen({
    required this.viewData,
    required this.onBack,
    required this.turn,
    required this.next,
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
      floatingActionButton: FloatingActionButton(
        onPressed: next,
        child: Icon(Icons.navigate_next),
      ),
    );
  }
}
