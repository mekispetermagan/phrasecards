class PronunciationData {
  final String? path;
  final bool isPlaying;
  final String? error;

  const PronunciationData({
    required this.path,
    this.isPlaying = false,
    this.error,
  });
}
