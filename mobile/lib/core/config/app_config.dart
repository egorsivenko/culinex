import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get _apiBaseUrl {
    if (dotenv.isInitialized) {
      final String? envValue = dotenv.maybeGet('CULINEX_API_BASE_URL');
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }
    }

    return String.fromEnvironment('CULINEX_API_BASE_URL');
  }

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
