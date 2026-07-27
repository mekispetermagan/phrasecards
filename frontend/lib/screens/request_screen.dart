import "package:flutter/material.dart";

import "../models/view_data.dart";
import "../widgets/appbar.dart";

class RequestScreen extends StatelessWidget {
  final RequestSubmissionViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<String> onSourceChanged;
  final VoidCallback onSubmit;

  const RequestScreen({
    required this.viewData,
    required this.onBack,
    required this.onSourceChanged,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: "Request a phrase", onBack: onBack),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: viewData.source,
                  enabled: !viewData.isSubmitting,
                  autofocus: true,
                  maxLength: 255,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "Phrase",
                    hintText: "What would you like to learn?",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onSourceChanged,
                  onFieldSubmitted: (_) {
                    if (viewData.canSubmit) onSubmit();
                  },
                ),
                if (viewData.errorMessage case final message?)
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewData.canSubmit ? onSubmit : null,
        icon: viewData.isSubmitting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(viewData.isSubmitting ? "Submitting…" : "Submit"),
      ),
    );
  }
}
