import 'package:culinex/core/auth/auth_models.dart';
import 'package:culinex/core/auth/auth_session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth session encodes and decodes through storage', () async {
    final _InMemoryAuthSessionStore store = _InMemoryAuthSessionStore();
    final AuthSession session = AuthSession(
      user: const AuthUser(
        id: 'user-1',
        fullName: 'Ada Lovelace',
        email: 'ada@example.com',
      ),
      accessToken: 'access-token',
      accessTokenExpiresAt: DateTime.utc(2030, 1, 1, 12),
      refreshToken: 'refresh-token',
      refreshTokenExpiresAt: DateTime.utc(2030, 1, 31, 12),
    );

    await store.saveSession(session);
    final AuthSession? restored = await store.loadSession();

    expect(restored, isNotNull);
    expect(restored!.user.id, session.user.id);
    expect(restored.user.fullName, session.user.fullName);
    expect(restored.user.email, session.user.email);
    expect(restored.accessToken, session.accessToken);
    expect(restored.refreshToken, session.refreshToken);
    expect(restored.accessTokenExpiresAt, session.accessTokenExpiresAt);
    expect(restored.refreshTokenExpiresAt, session.refreshTokenExpiresAt);
  });

  test('auth session store clears stored session', () async {
    final _InMemoryAuthSessionStore store = _InMemoryAuthSessionStore();
    final AuthSession session = AuthSession(
      user: const AuthUser(
        id: 'user-1',
        fullName: 'Ada Lovelace',
        email: 'ada@example.com',
      ),
      accessToken: 'access-token',
      accessTokenExpiresAt: DateTime.utc(2030, 1, 1, 12),
      refreshToken: 'refresh-token',
      refreshTokenExpiresAt: DateTime.utc(2030, 1, 31, 12),
    );

    await store.saveSession(session);
    await store.clearSession();

    expect(await store.loadSession(), isNull);
  });
}

class _InMemoryAuthSessionStore implements AuthSessionStore {
  String? _encodedSession;

  @override
  Future<void> clearSession() async {
    _encodedSession = null;
  }

  @override
  Future<AuthSession?> loadSession() async {
    final String? encodedSession = _encodedSession;
    if (encodedSession == null) {
      return null;
    }

    return AuthSession.decode(encodedSession);
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    _encodedSession = session.encode();
  }
}
