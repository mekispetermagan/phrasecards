import 'package:flutter/material.dart';

import '../models/view_data.dart';
import '../widgets/appbar.dart';

class ResolutionFormScreen extends StatelessWidget {
  final ResolutionFormViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSubmit;

  const ResolutionFormScreen({
    required this.viewData,
    required this.onBack,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Resolve request', onBack: onBack),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: viewData.source,
                  enabled: !viewData.isSubmitting,
                  autofocus: true,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Corrected phrase',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onSourceChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: viewData.target,
                  enabled: !viewData.isSubmitting,
                  maxLength: 255,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Translation',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onTargetChanged,
                  onFieldSubmitted: (_) {
                    if (viewData.canSubmit) onSubmit();
                  },
                ),
                if (viewData.errorMessage case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
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
            : const Icon(Icons.check),
        label: Text(viewData.isSubmitting ? 'Saving…' : 'Resolve'),
      ),
    );
  }
}
