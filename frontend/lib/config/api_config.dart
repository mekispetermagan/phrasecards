class ApiConfig {
  // normal dev: local hosting
  static const String debugBaseUrl = 'http://127.0.0.1:8000';
  // demo: hosting from server
  // static const String debugBaseUrl = 'https://phrasecards.mekis.dev';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: debugBaseUrl,
  );
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static String resolveApiUrl(String value) {
    final uri = Uri.parse(value);
    if (uri.hasScheme || uri.hasAuthority) return value;

    final relativePath = value.startsWith("/") ? value.substring(1) : value;
    return Uri.parse(baseUrl).resolveUri(Uri(path: relativePath)).toString();
  }
}
