import 'package:flutter/material.dart';

import '../models/phrasebuilding_tile.dart';
import '../models/view_data.dart';
import '../widgets/appbar.dart';
import '../widgets/phrasebuildingcard.dart';

class PhraseBuildingScreen extends StatelessWidget {
  final PhraseBuildingViewData viewData;
  final VoidCallback onBack;
  final void Function(PhraseBuildingTile)? move;
  final VoidCallback? submit;

  const PhraseBuildingScreen({
    required this.viewData,
    required this.onBack,
    required this.move,
    required this.submit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: FeatureAppBar(title: "Build phrases", onBack: onBack),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(
                    alignment: WrapAlignment.start,
                    children: <Widget>[
                      for (final tile in viewData.targetPool)
                        PhraseBuildingCard(
                          tile: tile,
                          move: move,
                          state: viewData.state,
                        ),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.start,
                    children: <Widget>[
                      for (final tile in viewData.sourcePool)
                        PhraseBuildingCard(
                          tile: tile,
                          move: move,
                          state: viewData.state,
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FilledButton(
                        onPressed: submit,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text("Submit", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
