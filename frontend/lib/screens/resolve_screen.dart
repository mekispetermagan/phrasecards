import 'package:flutter/material.dart';

import '../models/phrase_request.dart';
import '../models/view_data.dart';
import '../widgets/appbar.dart';

class ResolveScreen extends StatelessWidget {
  final RequestListViewData viewData;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final ValueChanged<PhraseRequest> onSelect;

  const ResolveScreen({
    required this.viewData,
    required this.onBack,
    required this.onRetry,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: "Resolve a request", onBack: onBack),
      body: switch (viewData.status) {
        RequestListStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        RequestListStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewData.errorMessage ?? "Could not load requests.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
        RequestListStatus.ready when viewData.requests.isEmpty => const Center(
          child: Text("No pending requests"),
        ),
        RequestListStatus.ready => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: viewData.requests.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (_, index) {
            final request = viewData.requests[index];
            return ListTile(
              title: Text(request.source),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelect(request),
            );
          },
        ),
      },
    );
  }
}
