class AppConfig {
  static const String baseUrl = 'https://beatify-api.satriakode.com/api';
  static const String _origin = 'https://beatify-api.satriakode.com';

  // Server sometimes returns localhost URLs in development — rewrite to production.
  static String fixUrl(String url) =>
      url.replaceFirst(RegExp(r'http://localhost:\d+'), _origin);
}
