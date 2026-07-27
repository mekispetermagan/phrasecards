class Phrase {
  final String source;
  final String target;
  final int rating;
  final bool isNew;
  const Phrase({
    required this.source,
    required this.target,
    required this.rating,
    required this.isNew,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      source: json['source'] as String,
      target: json['target'] as String,
      isNew: json['new'] as bool,
      rating: json['rating'] as int,
    );
  }
}
