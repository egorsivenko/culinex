import 'dart:convert';
import 'dart:io';

import 'package:culinex/core/auth/auth_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('check email accepts no-content response', () async {
    final AuthApiClient client = AuthApiClient(
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(
          request.url.toString(),
          'http://127.0.0.1:8080/api/auth/check-email',
        );
        expect(request.method, 'POST');

        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'ada@example.com');

        return http.Response('', 204);
      }),
    );

    await client.checkEmail(email: 'ada@example.com');
    client.close();
  });

  test('login decodes backend auth response', () async {
    final AuthApiClient client = AuthApiClient(
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(request.url.toString(), 'http://127.0.0.1:8080/api/auth/login');
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'ada@example.com');
        expect(body['password'], 'super-secret');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'user': <String, dynamic>{
              'id': 'user-1',
              'full_name': 'Ada Lovelace',
              'email': 'ada@example.com',
            },
            'access_token': 'access-token',
            'access_token_expires_at': HttpDate.format(
              DateTime.utc(2030, 1, 1, 12),
            ),
            'refresh_token': 'refresh-token',
            'refresh_token_expires_at': HttpDate.format(
              DateTime.utc(2030, 1, 31, 12),
            ),
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final session = await client.login(
      email: 'ada@example.com',
      password: 'super-secret',
    );

    expect(session.user.id, 'user-1');
    expect(session.user.fullName, 'Ada Lovelace');
    expect(session.user.email, 'ada@example.com');
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    client.close();
  });

  test('sign up maps validation errors', () async {
    final AuthApiClient client = AuthApiClient(
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'error': <String, dynamic>{
              'code': 'validation_failed',
              'message': 'full_name is required',
            },
          }),
          400,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    expect(
      () => client.signUp(
        fullName: '',
        email: 'ada@example.com',
        password: '12345678',
      ),
      throwsA(
        isA<AuthApiException>()
            .having(
              (error) => error.code,
              'code',
              AuthApiErrorCode.validationFailed,
            )
            .having(
              (error) => error.message,
              'message',
              'full_name is required',
            ),
      ),
    );
    client.close();
  });

  test('logout accepts no-content response', () async {
    final AuthApiClient client = AuthApiClient(
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(request.url.toString(), 'http://127.0.0.1:8080/api/auth/logout');
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['refresh_token'], 'refresh-token');
        return http.Response('', 204);
      }),
    );

    await client.logout(refreshToken: 'refresh-token');
    client.close();
  });

  test('delete account sends authorized delete request', () async {
    final AuthApiClient client = AuthApiClient(
      apiBaseUri: Uri.parse('http://127.0.0.1:8080/api/'),
      client: MockClient((http.Request request) async {
        expect(
          request.url.toString(),
          'http://127.0.0.1:8080/api/account',
        );
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(request.body, isEmpty);
        return http.Response('', 204);
      }),
    );

    await client.deleteAccount(accessToken: 'access-token');
    client.close();
  });
}
