import 'dart:io';

class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment(
    'CULINEX_API_BASE_URL',
  );

  static Uri get apiBaseUri {
    if (_apiBaseUrl.isNotEmpty) {
      return Uri.parse(_apiBaseUrl);
    }

    if (Platform.isAndroid) {
      return Uri.parse('http://10.0.2.2:8080/api/');
    }

    return Uri.parse('http://127.0.0.1:8080/api/');
  }
}
