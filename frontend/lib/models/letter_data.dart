class LetterData {
  final String id;
  final String letter;
  bool isRevealed;

  LetterData({
    required this.id,
    required this.letter,
    required this.isRevealed,
  });

  void reveal() {
    isRevealed = true;
  }
}
