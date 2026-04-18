import 'dart:convert';
import 'dart:io';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'full_name': fullName, 'email': email};
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final AuthUser user;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      accessToken: json['access_token'] as String? ?? '',
      accessTokenExpiresAt: _parseHttpTime(json['access_token_expires_at']),
      refreshToken: json['refresh_token'] as String? ?? '',
      refreshTokenExpiresAt: _parseHttpTime(json['refresh_token_expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user': user.toJson(),
      'access_token': accessToken,
      'access_token_expires_at': HttpDate.format(accessTokenExpiresAt.toUtc()),
      'refresh_token': refreshToken,
      'refresh_token_expires_at': HttpDate.format(
        refreshTokenExpiresAt.toUtc(),
      ),
    };
  }

  String encode() => jsonEncode(toJson());

  static AuthSession decode(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected auth session JSON object');
    }
    return AuthSession.fromJson(decoded);
  }

  bool get isAccessTokenExpired =>
      !accessTokenExpiresAt.toUtc().isAfter(DateTime.now().toUtc());

  bool get isRefreshTokenExpired =>
      !refreshTokenExpiresAt.toUtc().isAfter(DateTime.now().toUtc());

  AuthSession copyWith({
    AuthUser? user,
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    DateTime? refreshTokenExpiresAt,
  }) {
    return AuthSession(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
    );
  }

  static DateTime _parseHttpTime(Object? value) {
    final String source = value as String? ?? '';
    if (source.isEmpty) {
      throw const FormatException('Missing auth token expiry timestamp');
    }
    return HttpDate.parse(source).toUtc();
  }
}

class AuthErrorResponse {
  const AuthErrorResponse({required this.code, required this.message});

  final String code;
  final String message;

  factory AuthErrorResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> error =
        json['error'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return AuthErrorResponse(
      code: error['code'] as String? ?? 'server_error',
      message: error['message'] as String? ?? 'Unknown error',
    );
  }
}
