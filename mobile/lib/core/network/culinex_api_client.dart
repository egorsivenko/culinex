import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  Future<List<ExtractedIngredient>> extractIngredients(File imageFile) async {
    final String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    if (!mimeType.startsWith('image/')) {
      throw const CulinexApiException(
        'Only image files can be scanned for ingredients.',
      );
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
    List<RecipeIngredient> ingredients,
  ) async {
    final Uri uri = _apiBaseUri.resolve('generate-recipe');
    final http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ingredients': ingredients.map((item) => item.toJson()).toList(),
            }),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const CulinexApiException(
        'Recipe creation took too long. Please try again.',
      );
    } on SocketException {
      throw const CulinexApiException(
        'Could not reach the server. Check the backend URL and network.',
      );
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
      throw const CulinexApiException(
        'Ingredient recognition took too long. Please try again.',
      );
    } on SocketException {
      throw const CulinexApiException(
        'Could not reach the server. Check the backend URL and network.',
      );
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

    final String body = response.body.trim();
    if (body.isNotEmpty) {
      throw CulinexApiException(body);
    }

    throw CulinexApiException(
      'Server request failed with status ${response.statusCode}.',
    );
  }

  Map<String, dynamic> _decodeJson(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const CulinexApiException(
        'The server returned an unexpected response.',
      );
    }
    return decoded;
  }
}

class CulinexApiException implements Exception {
  const CulinexApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
