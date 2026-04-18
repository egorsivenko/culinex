import 'package:culinex/core/auth/auth_api_client.dart';
import 'package:culinex/core/auth/auth_models.dart';
import 'package:culinex/core/auth/auth_session_store.dart';
import 'package:culinex/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restoreSession authenticates with a stored valid session', () async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final _MemorySessionStore sessionStore = _MemorySessionStore(
      initialSession: _session(),
    );
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: sessionStore,
    );

    await controller.restoreSession();

    expect(controller.stage, AuthStage.authenticated);
    expect(controller.user?.email, 'ada@example.com');
    expect(controller.error, isNull);
    controller.dispose();
  });

  test('restoreSession clears expired refresh sessions', () async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final _MemorySessionStore sessionStore = _MemorySessionStore(
      initialSession: _session(
        refreshTokenExpiresAt: DateTime.now().toUtc().subtract(
          const Duration(minutes: 1),
        ),
      ),
    );
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: sessionStore,
    );

    await controller.restoreSession();

    expect(controller.stage, AuthStage.signedOut);
    expect(await sessionStore.loadSession(), isNull);
    controller.dispose();
  });

  test('signIn persists the returned session', () async {
    final _FakeAuthClient authClient = _FakeAuthClient(loginResult: _session());
    final _MemorySessionStore sessionStore = _MemorySessionStore();
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: sessionStore,
    );

    await controller.signIn(email: 'ada@example.com', password: 'super-secret');

    expect(controller.stage, AuthStage.authenticated);
    expect((await sessionStore.loadSession())?.accessToken, 'access-token');
    expect(authClient.closed, isFalse);
    controller.dispose();
    expect(authClient.closed, isTrue);
  });

  test(
    'signOut clears the local session even when remote logout fails',
    () async {
      final _FakeAuthClient authClient = _FakeAuthClient(
        logoutError: const AuthApiException(
          AuthApiErrorCode.networkUnavailable,
        ),
      );
      final _MemorySessionStore sessionStore = _MemorySessionStore(
        initialSession: _session(),
      );
      final AuthController controller = AuthController(
        authClient: authClient,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();
      await controller.signOut();

      expect(controller.stage, AuthStage.signedOut);
      expect(await sessionStore.loadSession(), isNull);
      expect(controller.error, isNull);
      controller.dispose();
    },
  );

  test(
    'getValidAccessToken refreshes and persists a new session when needed',
    () async {
      final _FakeAuthClient authClient = _FakeAuthClient(
        refreshResult: _session(
          accessTokenExpiresAt: DateTime.now().toUtc().add(
            const Duration(minutes: 15),
          ),
        ).copyWith(accessToken: 'fresh-access-token'),
      );
      final _MemorySessionStore sessionStore = _MemorySessionStore(
        initialSession: _session(
          accessTokenExpiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ),
        ),
      );
      final AuthController controller = AuthController(
        authClient: authClient,
        sessionStore: sessionStore,
      );

      await controller.restoreSession();
      final String accessToken = await controller.getValidAccessToken();

      expect(accessToken, 'fresh-access-token');
      expect(
        (await sessionStore.loadSession())?.accessToken,
        'fresh-access-token',
      );
      controller.dispose();
    },
  );

  test('handleUnauthorized clears the local session and signs out', () async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final _MemorySessionStore sessionStore = _MemorySessionStore(
      initialSession: _session(),
    );
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: sessionStore,
    );

    await controller.restoreSession();
    await controller.handleUnauthorized();

    expect(controller.stage, AuthStage.signedOut);
    expect(await sessionStore.loadSession(), isNull);
    controller.dispose();
  });
}

class _FakeAuthClient implements AuthClient {
  _FakeAuthClient({
    this.loginResult,
    this.signUpResult,
    this.refreshResult,
    this.loginError,
    this.signUpError,
    this.refreshError,
    this.logoutError,
  });

  final AuthSession? loginResult;
  final AuthSession? signUpResult;
  final AuthSession? refreshResult;
  final AuthApiException? loginError;
  final AuthApiException? signUpError;
  final AuthApiException? refreshError;
  final AuthApiException? logoutError;

  bool closed = false;

  @override
  void close() {
    closed = true;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) {
      throw loginError!;
    }
    return loginResult ?? _session();
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshResult ?? _session();
  }

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (signUpError != null) {
      throw signUpError!;
    }
    return signUpResult ?? _session();
  }
}

class _MemorySessionStore implements AuthSessionStore {
  _MemorySessionStore({AuthSession? initialSession})
    : _session = initialSession;

  AuthSession? _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<AuthSession?> loadSession() async {
    return _session;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }
}

AuthSession _session({
  DateTime? accessTokenExpiresAt,
  DateTime? refreshTokenExpiresAt,
}) {
  return AuthSession(
    user: const AuthUser(
      id: 'user-1',
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
    ),
    accessToken: 'access-token',
    accessTokenExpiresAt:
        accessTokenExpiresAt ??
        DateTime.now().toUtc().add(const Duration(minutes: 15)),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt:
        refreshTokenExpiresAt ??
        DateTime.now().toUtc().add(const Duration(days: 30)),
  );
}
