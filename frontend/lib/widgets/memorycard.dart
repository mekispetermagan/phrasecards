import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/memory.dart';

class MemoryCard extends StatelessWidget {
  static const Duration _flipDuration = Duration(milliseconds: 450);
  static const Duration _hideDuration = Duration(milliseconds: 350);

  final MemoryCardData data;
  final Offset expandedOffset;
  final VoidCallback onPressed;

  const MemoryCard({
    required this.data,
    required this.expandedOffset,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: data.isFaceUp,
      child: AnimatedOpacity(
        opacity: data.isMatched ? 0 : 1,
        duration: _hideDuration,
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: data.isFaceUp ? expandedOffset : Offset.zero,
          duration: _flipDuration,
          curve: Curves.easeInOutCubic,
          child: AnimatedScale(
            scale: data.isFaceUp ? 2 : 1,
            duration: _flipDuration,
            curve: Curves.easeInOutCubic,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: data.isFaceUp ? 1 : 0),
              duration: _flipDuration,
              curve: Curves.easeInOutCubic,
              builder: (context, turn, child) {
                final bool showFace = turn >= 0.5;
                final Matrix4 rotation = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(math.pi * turn);

                return Transform(
                  alignment: Alignment.center,
                  transform: rotation,
                  child: showFace
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: _CardFace(data: data, onPressed: onPressed),
                        )
                      : _CardBack(data: data, onPressed: onPressed),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final MemoryCardData data;
  final VoidCallback onPressed;

  const _CardBack({required this.data, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isSource = data.side == MemoryCardSide.source;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSource ? colors.primaryContainer : colors.tertiaryContainer,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: isSource
                  ? colors.onPrimaryContainer
                  : colors.onTertiaryContainer,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final MemoryCardData data;
  final VoidCallback onPressed;

  const _CardFace({required this.data, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isSource = data.side == MemoryCardSide.source;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSource ? colors.primary : colors.tertiary,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSource ? colors.onPrimary : colors.onTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
