import 'package:flutter/material.dart';
import 'buttons.dart';

class FeatureAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const FeatureAppBar({required this.title, required this.onBack, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: ExitButton(onPressed: onBack),
    );
  }
}
