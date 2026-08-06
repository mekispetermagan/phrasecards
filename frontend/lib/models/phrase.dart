class Phrase {
  final int id;
  final String source;
  final String target;
  final String? audioPath;

  const Phrase({
    required this.id,
    required this.source,
    required this.target,
    required this.audioPath,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      id: json['id'] as int,
      source: json['source'] as String,
      target: json['target'] as String,
      audioPath: json['audio_path'] as String?,
    );
  }
}
