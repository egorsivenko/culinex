import 'package:flutter/foundation.dart';

import '../../core/auth/auth_api_client.dart';
import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_session_coordinator.dart';
import '../../core/auth/auth_session_store.dart';

enum AuthStage { loading, signedOut, authenticated }

enum AuthErrorCode {
  validationFailed,
  emailAlreadyInUse,
  invalidCredentials,
  sessionExpired,
  requestTimedOut,
  networkUnavailable,
  serverFailure,
  unexpectedResponse,
}

class AuthErrorState {
  const AuthErrorState({required this.code});

  final AuthErrorCode code;
}

class AuthController extends ChangeNotifier implements AuthSessionCoordinator {
  AuthController({
    required AuthClient authClient,
    required AuthSessionStore sessionStore,
  }) : _authClient = authClient,
       _sessionStore = sessionStore;

  final AuthClient _authClient;
  final AuthSessionStore _sessionStore;

  AuthStage _stage = AuthStage.loading;
  AuthSession? _session;
  AuthErrorState? _error;
  bool _isSubmitting = false;
  bool _isDisposed = false;
  Future<AuthSession>? _refreshFuture;

  AuthStage get stage => _stage;
  AuthSession? get session => _session;
  AuthUser? get user => _session?.user;
  AuthErrorState? get error => _error;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _stage == AuthStage.authenticated;

  @override
  Future<String> getValidAccessToken() async {
    final AuthSession? currentSession = _session;
    if (currentSession == null) {
      throw const AuthApiException(AuthApiErrorCode.sessionExpired);
    }
    if (!currentSession.isAccessTokenExpired) {
      return currentSession.accessToken;
    }

    final AuthSession refreshedSession = await _refreshSession();
    return refreshedSession.accessToken;
  }

  @override
  Future<String> refreshAccessToken() async {
    final AuthSession refreshedSession = await _refreshSession(force: true);
    return refreshedSession.accessToken;
  }

  @override
  Future<void> handleUnauthorized() async {
    await _clearLocalSession();
  }

  Future<void> restoreSession() async {
    _stage = AuthStage.loading;
    _error = null;
    _notifySafely();

    try {
      final AuthSession? storedSession = await _sessionStore.loadSession();
      if (storedSession == null || storedSession.isRefreshTokenExpired) {
        if (storedSession != null) {
          await _sessionStore.clearSession();
        }
        _session = null;
        _stage = AuthStage.signedOut;
        _notifySafely();
        return;
      }

      _session = storedSession;
      _stage = AuthStage.authenticated;
      _notifySafely();
    } catch (_) {
      _session = null;
      _stage = AuthStage.signedOut;
      _error = const AuthErrorState(code: AuthErrorCode.unexpectedResponse);
      _notifySafely();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _submit(
      () => _authClient.signUp(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _submit(() => _authClient.login(email: email, password: password));
  }

  Future<bool> checkEmailAvailable({required String email}) async {
    _isSubmitting = true;
    _error = null;
    if (_stage != AuthStage.authenticated) {
      _stage = AuthStage.signedOut;
    }
    _notifySafely();

    try {
      await _authClient.checkEmail(email: email);
      _isSubmitting = false;
      _notifySafely();
      return true;
    } on AuthApiException catch (error) {
      _isSubmitting = false;
      _error = AuthErrorState(code: _mapErrorCode(error.code));
      _notifySafely();
      return false;
    }
  }

  Future<void> signOut() async {
    final AuthSession? currentSession = _session;
    _isSubmitting = true;
    _error = null;
    _notifySafely();

    try {
      if (currentSession != null && !currentSession.isRefreshTokenExpired) {
        await _authClient.logout(refreshToken: currentSession.refreshToken);
      }
    } on AuthApiException {
      // Local sign-out should succeed even if remote logout fails.
    } finally {
      _isSubmitting = false;
      await _clearLocalSession();
    }
  }

  Future<void> deleteAccount() async {
    _isSubmitting = true;
    _error = null;
    _notifySafely();

    try {
      final String accessToken = await getValidAccessToken();
      await _authClient.deleteAccount(accessToken: accessToken);
      _isSubmitting = false;
      await _clearLocalSession();
    } on AuthApiException catch (error) {
      _isSubmitting = false;
      if (error.code == AuthApiErrorCode.sessionExpired) {
        await _clearLocalSession();
        return;
      }

      _error = AuthErrorState(code: _mapErrorCode(error.code));
      _notifySafely();
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    _notifySafely();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authClient.close();
    super.dispose();
  }

  Future<void> _submit(Future<AuthSession> Function() action) async {
    _isSubmitting = true;
    _error = null;
    if (_stage != AuthStage.authenticated) {
      _stage = AuthStage.signedOut;
    }
    _notifySafely();

    try {
      final AuthSession session = await action();
      await _sessionStore.saveSession(session);

      _session = session;
      _stage = AuthStage.authenticated;
      _isSubmitting = false;
      _notifySafely();
    } on AuthApiException catch (error) {
      _session = null;
      _stage = AuthStage.signedOut;
      _isSubmitting = false;
      _error = AuthErrorState(code: _mapErrorCode(error.code));
      _notifySafely();
    }
  }

  Future<AuthSession> _refreshSession({bool force = false}) async {
    final Future<AuthSession>? inFlightRefresh = _refreshFuture;
    if (inFlightRefresh != null) {
      return inFlightRefresh;
    }

    final Future<AuthSession> refreshFuture = _performRefresh(force: force);
    _refreshFuture = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<AuthSession> _performRefresh({required bool force}) async {
    final AuthSession? currentSession = _session;
    if (currentSession == null) {
      throw const AuthApiException(AuthApiErrorCode.sessionExpired);
    }

    if (!force && !currentSession.isAccessTokenExpired) {
      return currentSession;
    }

    if (currentSession.isRefreshTokenExpired) {
      await _clearLocalSession();
      throw const AuthApiException(AuthApiErrorCode.sessionExpired);
    }

    try {
      final AuthSession refreshedSession = await _authClient.refresh(
        refreshToken: currentSession.refreshToken,
      );
      await _sessionStore.saveSession(refreshedSession);

      _session = refreshedSession;
      _stage = AuthStage.authenticated;
      _error = null;
      _notifySafely();
      return refreshedSession;
    } on AuthApiException catch (error) {
      if (error.code == AuthApiErrorCode.sessionExpired) {
        await _clearLocalSession();
      }
      rethrow;
    }
  }

  AuthErrorCode _mapErrorCode(AuthApiErrorCode code) {
    return switch (code) {
      AuthApiErrorCode.validationFailed => AuthErrorCode.validationFailed,
      AuthApiErrorCode.emailAlreadyInUse => AuthErrorCode.emailAlreadyInUse,
      AuthApiErrorCode.invalidCredentials => AuthErrorCode.invalidCredentials,
      AuthApiErrorCode.sessionExpired => AuthErrorCode.sessionExpired,
      AuthApiErrorCode.requestTimedOut => AuthErrorCode.requestTimedOut,
      AuthApiErrorCode.networkUnavailable => AuthErrorCode.networkUnavailable,
      AuthApiErrorCode.serverFailure => AuthErrorCode.serverFailure,
      AuthApiErrorCode.unexpectedResponse => AuthErrorCode.unexpectedResponse,
    };
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    await _sessionStore.clearSession();
    _session = null;
    _stage = AuthStage.signedOut;
    _error = null;
    _notifySafely();
  }
}
