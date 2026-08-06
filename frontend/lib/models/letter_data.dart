class LetterData {
  final String id;
  final String letter;
  final bool isRevealed;

  const LetterData({
    required this.id,
    required this.letter,
    required this.isRevealed,
  });

  LetterData copyWith({bool? isRevealed}) => LetterData(
    id: id,
    letter: letter,
    isRevealed: isRevealed ?? this.isRevealed,
  );
}
