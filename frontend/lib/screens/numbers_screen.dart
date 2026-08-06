import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../widgets/appbar.dart';
import '../models/view_data.dart';

class NumbersScreen extends StatelessWidget {
  final NumbersViewData viewData;
  final VoidCallback onBack;
  final void Function(int)? onSubmit;

  const NumbersScreen({
    required this.viewData,
    required this.onBack,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // We need a harmonizing green for success feedback.
    final ColorScheme successScheme = ColorScheme.fromSeed(
      seedColor: Colors.green.harmonizeWith(colorScheme.primary),
      brightness: colorScheme.brightness,
    );
    Color buttonBgColor(int i) => viewData.successHighlightIndex == i
        ? successScheme.primaryContainer
        : viewData.failureHighlightIndex == i
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    Color buttonFgColor(int i) => viewData.successHighlightIndex == i
        ? successScheme.onPrimaryContainer
        : viewData.failureHighlightIndex == i
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Scaffold(
      appBar: FeatureAppBar(title: "Practice numbers", onBack: onBack),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < viewData.solution; i++)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          viewData.emoji,
                          style: TextStyle(fontSize: 42),
                        ),
                      ),
                  ],
                ),
                for (int i = 0; i < viewData.options.length; i++)
                  FilledButton(
                    onPressed: onSubmit == null ? null : () => onSubmit!(i),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(buttonBgColor(i)),
                      foregroundColor: WidgetStatePropertyAll(buttonFgColor(i)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        viewData.options[i],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                Text(
                  "Score: ${viewData.score}",
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
