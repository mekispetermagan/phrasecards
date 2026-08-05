enum MemoryCardSide { source, target }

enum MemoryCardState { hidden, revealed, matched }

class MemoryCardData {
  final int cardId;
  final int pairId;
  final String text;
  final String? audioPath;
  final MemoryCardSide side;
  final MemoryCardState state;
  final int revealOrder;

  const MemoryCardData({
    required this.cardId,
    required this.pairId,
    required this.text,
    required this.audioPath,
    required this.side,
    this.state = MemoryCardState.hidden,
    this.revealOrder = 0,
  });

  bool get isFaceUp => state != MemoryCardState.hidden;
  bool get isMatched => state == MemoryCardState.matched;

  MemoryCardData copyWith({MemoryCardState? state, int? revealOrder}) =>
      MemoryCardData(
        cardId: cardId,
        pairId: pairId,
        text: text,
        audioPath: audioPath,
        side: side,
        state: state ?? this.state,
        revealOrder: revealOrder ?? this.revealOrder,
      );
}
