class Phrase {
  final int id;
  final String source;
  final String target;
  final int rating;
  final bool isNew;
  final String? audioPath;
  const Phrase({
    required this.id,
    required this.source,
    required this.target,
    required this.rating,
    required this.isNew,
    required this.audioPath,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      id: json['id'] as int,
      source: json['source'] as String,
      target: json['target'] as String,
      isNew: json['new'] as bool,
      rating: json['rating'] as int,
      audioPath: json['audio_path'] as String?,
    );
  }

  Phrase copyWith({bool? isNew}) => Phrase(
    id: id,
    source: source,
    target: target,
    rating: rating,
    isNew: isNew ?? this.isNew,
    audioPath: audioPath,
  );
}
