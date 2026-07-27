class PhraseRequest {
  final int id;
  final String source;

  const PhraseRequest({required this.id, required this.source});

  factory PhraseRequest.fromJson(Map<String, dynamic> json) {
    return PhraseRequest(
      id: json['id'] as int,
      source: json['source'] as String,
    );
  }
}
