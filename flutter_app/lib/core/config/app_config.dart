class AppConfig {
  static const String baseUrl = 'https://beatify-api.satriakode.com/api';
  static const String _origin = 'https://beatify-api.satriakode.com';

  // Defensive fallback: the API returns absolute URLs via PUBLIC_BASE_URL, but
  // rewrite any leftover localhost origin (e.g. dev/misconfigured server) to prod.
  static String fixUrl(String url) =>
      url.replaceFirst(RegExp(r'http://localhost:\d+'), _origin);
}
