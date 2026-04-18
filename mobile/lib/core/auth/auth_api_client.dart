import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_models.dart';

abstract interface class AuthClient {
  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> refresh({required String refreshToken});

  Future<void> logout({required String refreshToken});

  void close();
}

class AuthApiClient implements AuthClient {
  AuthApiClient({Uri? apiBaseUri, http.Client? client})
    : _apiBaseUri = apiBaseUri ?? AppConfig.apiBaseUri,
      _client = client ?? http.Client(),
      _ownsClient = client == null;

  final Uri _apiBaseUri;
  final http.Client _client;
  final bool _ownsClient;

  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _postAuth('auth/signup', <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> login({required String email, required String password}) {
    return _postAuth('auth/login', <String, dynamic>{
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> refresh({required String refreshToken}) {
    return _postAuth('auth/refresh', <String, dynamic>{
      'refresh_token': refreshToken,
    });
  }

  Future<void> logout({required String refreshToken}) async {
    await _postWithoutResponse('auth/logout', <String, dynamic>{
      'refresh_token': refreshToken,
    });
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<AuthSession> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final http.Response response = await _post(path, payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _mapError(response);
    }

    try {
      return AuthSession.fromJson(_decodeJson(response.body));
    } on FormatException {
      throw const AuthApiException(AuthApiErrorCode.unexpectedResponse);
    }
  }

  Future<void> _postWithoutResponse(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final http.Response response = await _post(path, payload);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _mapError(response);
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> payload) async {
    final Uri uri = _apiBaseUri.resolve(path);

    try {
      return await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const AuthApiException(AuthApiErrorCode.requestTimedOut);
    } on SocketException {
      throw const AuthApiException(AuthApiErrorCode.networkUnavailable);
    }
  }

  AuthApiException _mapError(http.Response response) {
    if (response.statusCode >= 500) {
      return const AuthApiException(AuthApiErrorCode.serverFailure);
    }

    final Map<String, dynamic> payload;
    try {
      payload = _decodeJson(response.body);
    } on AuthApiException {
      return const AuthApiException(AuthApiErrorCode.unexpectedResponse);
    }

    final AuthErrorResponse error = AuthErrorResponse.fromJson(payload);
    return AuthApiException(switch (error.code) {
      'validation_failed' => AuthApiErrorCode.validationFailed,
      'email_already_in_use' => AuthApiErrorCode.emailAlreadyInUse,
      'invalid_credentials' => AuthApiErrorCode.invalidCredentials,
      'session_expired' => AuthApiErrorCode.sessionExpired,
      _ => AuthApiErrorCode.serverFailure,
    }, message: error.message);
  }

  Map<String, dynamic> _decodeJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const AuthApiException(AuthApiErrorCode.unexpectedResponse);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AuthApiException(AuthApiErrorCode.unexpectedResponse);
    }
    return decoded;
  }
}

enum AuthApiErrorCode {
  validationFailed,
  emailAlreadyInUse,
  invalidCredentials,
  sessionExpired,
  requestTimedOut,
  networkUnavailable,
  serverFailure,
  unexpectedResponse,
}

class AuthApiException implements Exception {
  const AuthApiException(this.code, {this.message});

  final AuthApiErrorCode code;
  final String? message;

  @override
  String toString() => message == null ? code.name : '${code.name}: $message';
}
