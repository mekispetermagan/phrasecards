import 'package:flutter/material.dart';

import '../models/pronunciation.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MenuButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ExitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ExitButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onPressed, icon: Icon(Icons.arrow_back));
  }
}

class SpeakerButton extends StatelessWidget {
  final PronunciationData pronunciation;
  final VoidCallback onPressed;
  final Color? color;

  const SpeakerButton({
    required this.pronunciation,
    required this.onPressed,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (pronunciation.path == null) return const SizedBox.shrink();

    return IconButton(
      tooltip: pronunciation.error ?? 'Play pronunciation',
      padding: const EdgeInsets.all(24),
      onPressed: onPressed,
      icon: pronunciation.isPlaying
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.volume_up),
      iconSize: 36,
      color: pronunciation.error == null
          ? color
          : Theme.of(context).colorScheme.error,
    );
  }
}
