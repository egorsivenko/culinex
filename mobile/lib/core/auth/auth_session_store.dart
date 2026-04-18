import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_models.dart';

abstract interface class AuthSessionStore {
  Future<AuthSession?> loadSession();

  Future<void> saveSession(AuthSession session);

  Future<void> clearSession();
}

class SecureStorageAuthSessionStore implements AuthSessionStore {
  SecureStorageAuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'auth.session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> loadSession() async {
    final String? encodedSession = await _storage.read(key: _sessionKey);
    if (encodedSession == null || encodedSession.isEmpty) {
      return null;
    }

    return AuthSession.decode(encodedSession);
  }

  @override
  Future<void> saveSession(AuthSession session) {
    return _storage.write(key: _sessionKey, value: session.encode());
  }

  @override
  Future<void> clearSession() {
    return _storage.delete(key: _sessionKey);
  }
}
