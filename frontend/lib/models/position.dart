import 'dart:math';

class PositionData {
  final double x;
  final double y;
  final double width;
  final double height;
  const PositionData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class MemoryBoardLayout {
  final double cardSize;
  final double gap;
  final double xPadding;
  final double yPadding;
  final int columnCount;

  const MemoryBoardLayout({
    required this.cardSize,
    required this.gap,
    required this.xPadding,
    required this.yPadding,
    required this.columnCount,
  });

  factory MemoryBoardLayout.calculate({
    required double availableWidth,
    required double availableHeight,
    required double minimumPadding,
    required double gap,
    required int columnCount,
    required int rowCount,
  }) {
    final double maximumWidth =
        (availableWidth - minimumPadding * 2 - gap * (columnCount - 1)) /
        columnCount;
    final double maximumHeight =
        (availableHeight - minimumPadding * 2 - gap * (rowCount - 1)) /
        rowCount;
    final double cardSize = min(maximumWidth, maximumHeight);
    final double boardWidth = columnCount * cardSize + (columnCount - 1) * gap;
    final double boardHeight = rowCount * cardSize + (rowCount - 1) * gap;

    return MemoryBoardLayout(
      cardSize: cardSize,
      gap: gap,
      xPadding: (availableWidth - boardWidth) / 2,
      yPadding: (availableHeight - boardHeight) / 2,
      columnCount: columnCount,
    );
  }

  PositionData positionFor(int index) {
    final int column = index % columnCount;
    final int row = index ~/ columnCount;

    return PositionData(
      x: xPadding + column * (cardSize + gap),
      y: yPadding + row * (cardSize + gap),
      width: cardSize,
      height: cardSize,
    );
  }
}
