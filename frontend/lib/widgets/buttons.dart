import 'package:flutter/material.dart';

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

class PhraseCard extends StatelessWidget {
  final String primaryPhrase;
  final String secondaryPhrase;
  final bool isTurned;
  final VoidCallback onPressed;

  const PhraseCard({
    required this.primaryPhrase,
    required this.secondaryPhrase,
    required this.isTurned,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.5,
      heightFactor: 0.5,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isTurned
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
        child: Text(
          isTurned ? secondaryPhrase : primaryPhrase,
          style: TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
