import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../features/session/culinex_models.dart';
import '../config/app_config.dart';
import 'culinex_repository.dart';

class CulinexApiClient implements CulinexRepository {
  CulinexApiClient({Uri? apiBaseUri, http.Client? client})
    : _apiBaseUri = apiBaseUri ?? AppConfig.apiBaseUri,
      _client = client ?? http.Client(),
      _ownsClient = client == null;

  final Uri _apiBaseUri;
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
    request.headers['Accept-Language'] = locale.toLanguageTag();

    final http.Response response = await _sendMultipart(request);
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
    final Uri uri = _apiBaseUri.resolve('generate-recipe');
    final http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept-Language': locale.toLanguageTag(),
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const CulinexApiException(CulinexApiErrorCode.requestTimedOut);
    } on SocketException {
      throw const CulinexApiException(CulinexApiErrorCode.networkUnavailable);
    }

    _ensureSuccess(response);
    final Map<String, dynamic> payload = _decodeJson(response.body);
    return GeneratedRecipe.fromJson(payload);
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
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
    _ensureSuccess(response);
    return response;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw const CulinexApiException(CulinexApiErrorCode.serverFailure);
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
  serverFailure,
  unexpectedResponse,
}

class CulinexApiException implements Exception {
  const CulinexApiException(this.code);

  final CulinexApiErrorCode code;

  @override
  String toString() => code.name;
}
