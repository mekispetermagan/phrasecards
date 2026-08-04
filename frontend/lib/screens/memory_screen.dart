import 'package:flutter/material.dart';

import '../models/memory.dart';
import '../models/position.dart';
import '../models/view_data.dart';
import '../widgets/appbar.dart';
import '../widgets/memorycard.dart';

class MemoryScreen extends StatelessWidget {
  static const double _gap = 12;
  static const double _minimumPadding = 24;
  static const int _columnCount = 3;
  static const int _rowCount = 6;

  final MemoryViewData viewData;
  final VoidCallback onBack;
  final Future<void> Function(int cardId) onSelect;
  final VoidCallback onNewGame;

  const MemoryScreen({
    required this.viewData,
    required this.onBack,
    required this.onSelect,
    required this.onNewGame,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FeatureAppBar(title: 'Memory game', onBack: onBack),
      body: SafeArea(
        child: viewData.canPlay ? _buildBoard() : _buildEmptyState(context),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final MemoryBoardLayout board = MemoryBoardLayout.calculate(
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
          minimumPadding: _minimumPadding,
          gap: _gap,
          columnCount: _columnCount,
          rowCount: _rowCount,
        );
        final indexedCards = viewData.cards.indexed.toList();
        final faceUpCards =
            indexedCards.where((entry) => entry.$2.isFaceUp).toList()..sort(
              (first, second) =>
                  first.$2.revealOrder.compareTo(second.$2.revealOrder),
            );
        final orderedCards = [
          ...indexedCards.where((entry) => !entry.$2.isFaceUp),
          ...faceUpCards,
        ];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final entry in orderedCards)
              _buildCard(board, entry.$1, entry.$2),
            if (viewData.isComplete)
              Positioned.fill(
                child: Center(
                  child: FilledButton.icon(
                    onPressed: onNewGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Play again'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCard(MemoryBoardLayout board, int index, MemoryCardData card) {
    final PositionData position = board.positionFor(index);
    return Positioned(
      key: ValueKey(card.cardId),
      left: position.x,
      top: position.y,
      width: position.width,
      height: position.height,
      child: MemoryCard(
        data: card,
        expandedOffset: _expandedOffsetFor(index),
        onPressed: () => onSelect(card.cardId),
      ),
    );
  }

  Offset _expandedOffsetFor(int index) {
    final int column = index % _columnCount;
    final int row = index ~/ _columnCount;
    final double dx = column == 0
        ? 0.5
        : column == _columnCount - 1
        ? -0.5
        : 0;
    final double dy = row < _rowCount / 2 ? 0.5 : -0.5;
    return Offset(dx, dy);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Not enough distinct phrase pairs.\nAdd phrases with different translations to play the memory game.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
