import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../auth/auth_api_client.dart';
import '../auth/auth_session_coordinator.dart';
import '../../features/session/culinex_models.dart';
import '../config/app_config.dart';
import 'culinex_repository.dart';

class CulinexApiClient implements CulinexRepository {
  CulinexApiClient({
    required AuthSessionCoordinator authSessionCoordinator,
    Uri? apiBaseUri,
    http.Client? client,
  }) : _apiBaseUri = apiBaseUri ?? AppConfig.apiBaseUri,
       _authSessionCoordinator = authSessionCoordinator,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final Uri _apiBaseUri;
  final AuthSessionCoordinator _authSessionCoordinator;
  final http.Client _client;
  final bool _ownsClient;

  static const Duration _requestTimeout = Duration(seconds: 65);

  @override
  Future<List<ExtractedIngredient>> extractIngredients(
    File imageFile, {
    required Locale locale,
  }) async {
    final String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    if (!mimeType.startsWith('image/')) {
      throw const CulinexApiException(CulinexApiErrorCode.invalidImageFile);
    }

    final http.Response response = await _sendAuthorizedMultipart(
      locale: locale,
      buildRequest: () async {
        final http.MultipartRequest request = http.MultipartRequest(
          'POST',
          _apiBaseUri.resolve('extract-ingredients'),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            filename: p.basename(imageFile.path),
            contentType: MediaType.parse(mimeType),
          ),
        );
        return request;
      },
    );
    final Map<String, dynamic> payload = _decodeJson(response.body);
    final List<dynamic> items = payload['ingredients'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) => ExtractedIngredient.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<GeneratedRecipe> generateRecipe(
    RecipeGenerationRequest request, {
    required Locale locale,
  }) async {
    final http.Response response = await _sendAuthorizedJson(
      path: 'generate-recipe',
      locale: locale,
      payload: request.toJson(),
    );
    final Map<String, dynamic> payload = _decodeJson(response.body);
    return GeneratedRecipe.fromJson(payload);
  }

  @override
  Future<List<RecipeSummary>> listRecipes() async {
    final http.Response response = await _sendAuthorizedGet(path: 'recipes');
    final Map<String, dynamic> payload = _decodeJson(response.body);
    final List<dynamic> items = payload['recipes'] as List<dynamic>? ?? [];

    return items
        .map((item) => RecipeSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<GeneratedRecipe> getRecipe(String id) async {
    final http.Response response = await _sendAuthorizedGet(
      path: 'recipes/$id',
    );
    final Map<String, dynamic> payload = _decodeJson(response.body);
    return GeneratedRecipe.fromJson(payload);
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _sendAuthorizedDelete(path: 'recipes/$id');
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<http.Response> _sendAuthorizedJson({
    required String path,
    required Locale locale,
    required Map<String, dynamic> payload,
  }) {
    return _sendAuthorized(
      send: (String accessToken) async {
        final Uri uri = _apiBaseUri.resolve(path);

        try {
          return await _client
              .post(
                uri,
                headers: <String, String>{
                  'Content-Type': 'application/json',
                  'Accept-Language': locale.toLanguageTag(),
                  'Authorization': 'Bearer $accessToken',
                },
                body: jsonEncode(payload),
              )
              .timeout(_requestTimeout);
        } on TimeoutException {
          throw const CulinexApiException(CulinexApiErrorCode.requestTimedOut);
        } on SocketException {
          throw const CulinexApiException(
            CulinexApiErrorCode.networkUnavailable,
          );
        }
      },
    );
  }

  Future<http.Response> _sendAuthorizedGet({required String path}) {
    return _sendAuthorized(
      send: (String accessToken) async {
        final Uri uri = _apiBaseUri.resolve(path);

        try {
          return await _client
              .get(
                uri,
                headers: <String, String>{
                  'Authorization': 'Bearer $accessToken',
                },
              )
              .timeout(_requestTimeout);
        } on TimeoutException {
          throw const CulinexApiException(CulinexApiErrorCode.requestTimedOut);
        } on SocketException {
          throw const CulinexApiException(
            CulinexApiErrorCode.networkUnavailable,
          );
        }
      },
    );
  }

  Future<http.Response> _sendAuthorizedDelete({required String path}) {
    return _sendAuthorized(
      send: (String accessToken) async {
        final Uri uri = _apiBaseUri.resolve(path);

        try {
          return await _client
              .delete(
                uri,
                headers: <String, String>{
                  'Authorization': 'Bearer $accessToken',
                },
              )
              .timeout(_requestTimeout);
        } on TimeoutException {
          throw const CulinexApiException(CulinexApiErrorCode.requestTimedOut);
        } on SocketException {
          throw const CulinexApiException(
            CulinexApiErrorCode.networkUnavailable,
          );
        }
      },
    );
  }

  Future<http.Response> _sendAuthorizedMultipart({
    required Locale locale,
    required Future<http.MultipartRequest> Function() buildRequest,
  }) {
    return _sendAuthorized(
      send: (String accessToken) async {
        final http.MultipartRequest request = await buildRequest();
        request.headers['Accept-Language'] = locale.toLanguageTag();
        request.headers['Authorization'] = 'Bearer $accessToken';
        return _sendMultipart(request);
      },
    );
  }

  Future<http.Response> _sendAuthorized({
    required Future<http.Response> Function(String accessToken) send,
  }) async {
    try {
      final String accessToken = await _authSessionCoordinator
          .getValidAccessToken();
      http.Response response = await send(accessToken);
      if (response.statusCode != HttpStatus.unauthorized) {
        _ensureSuccess(response);
        return response;
      }

      final String refreshedAccessToken = await _authSessionCoordinator
          .refreshAccessToken();
      response = await send(refreshedAccessToken);
      if (response.statusCode == HttpStatus.unauthorized) {
        await _authSessionCoordinator.handleUnauthorized();
        throw const CulinexApiException(CulinexApiErrorCode.unauthorized);
      }

      _ensureSuccess(response);
      return response;
    } on AuthApiException catch (error) {
      throw _mapAuthException(error);
    }
  }

  Future<http.Response> _sendMultipart(http.MultipartRequest request) async {
    final http.StreamedResponse streamedResponse;

    try {
      streamedResponse = await _client.send(request).timeout(_requestTimeout);
    } on TimeoutException {
      throw const CulinexApiException(CulinexApiErrorCode.requestTimedOut);
    } on SocketException {
      throw const CulinexApiException(CulinexApiErrorCode.networkUnavailable);
    }

    final http.Response response = await http.Response.fromStream(
      streamedResponse,
    );
    return response;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == HttpStatus.unauthorized) {
      throw const CulinexApiException(CulinexApiErrorCode.unauthorized);
    }
    throw const CulinexApiException(CulinexApiErrorCode.serverFailure);
  }

  CulinexApiException _mapAuthException(AuthApiException error) {
    return CulinexApiException(switch (error.code) {
      AuthApiErrorCode.requestTimedOut => CulinexApiErrorCode.requestTimedOut,
      AuthApiErrorCode.networkUnavailable =>
        CulinexApiErrorCode.networkUnavailable,
      AuthApiErrorCode.unexpectedResponse =>
        CulinexApiErrorCode.unexpectedResponse,
      AuthApiErrorCode.sessionExpired => CulinexApiErrorCode.unauthorized,
      AuthApiErrorCode.serverFailure => CulinexApiErrorCode.serverFailure,
      AuthApiErrorCode.validationFailed => CulinexApiErrorCode.serverFailure,
      AuthApiErrorCode.emailAlreadyInUse => CulinexApiErrorCode.serverFailure,
      AuthApiErrorCode.invalidCredentials => CulinexApiErrorCode.serverFailure,
    });
  }

  Map<String, dynamic> _decodeJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const CulinexApiException(CulinexApiErrorCode.unexpectedResponse);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CulinexApiException(CulinexApiErrorCode.unexpectedResponse);
    }
    return decoded;
  }
}

enum CulinexApiErrorCode {
  invalidImageFile,
  requestTimedOut,
  networkUnavailable,
  unauthorized,
  serverFailure,
  unexpectedResponse,
}

class CulinexApiException implements Exception {
  const CulinexApiException(this.code);

  final CulinexApiErrorCode code;

  @override
  String toString() => code.name;
}
