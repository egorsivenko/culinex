import 'package:culinex/core/auth/auth_api_client.dart';
import 'package:culinex/core/auth/auth_models.dart';
import 'package:culinex/core/auth/auth_session_store.dart';
import 'package:culinex/features/auth/auth_controller.dart';
import 'package:culinex/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

AuthScreen _buildAuthScreen(AuthController controller) {
  return AuthScreen(
    controller: controller,
    isDarkMode: false,
    onToggleTheme: () {},
    locale: const Locale('en'),
    onSelectLocale: (_) {},
  );
}

Future<void> _tapModeSwitch(WidgetTester tester) async {
  final Finder switchModeButton = find.byKey(
    const ValueKey<String>('auth-switch-mode-button'),
  );
  await tester.ensureVisible(switchModeButton);
  await tester.pumpAndSettle();
  await tester.tap(switchModeButton);
  await tester.pumpAndSettle();
}

Future<void> _continueSignUpToPasswordStep(
  WidgetTester tester, {
  required String fullName,
  required String email,
}) async {
  await _tapModeSwitch(tester);
  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-full-name')),
    fullName,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('auth-email')),
    email,
  );
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('auth-submit-button')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('auth screen starts in sign-in mode and switches to sign-up', (
    WidgetTester tester,
  ) async {
    final AuthController controller = AuthController(
      authClient: _FakeAuthClient(),
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-full-name')), findsNothing);

    await _tapModeSwitch(tester);

    expect(find.text('Sign up'), findsWidgets);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('auth-full-name')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('auth-email')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-password')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('auth-confirm-password')),
      findsNothing,
    );
    expect(find.text('Proceed'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('auth screen clears only password when switching modes', (
    WidgetTester tester,
  ) async {
    final AuthController controller = AuthController(
      authClient: _FakeAuthClient(),
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await _continueSignUpToPasswordStep(
      tester,
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      'super-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-confirm-password')),
      'super-secret',
    );

    await _tapModeSwitch(tester);

    await _tapModeSwitch(tester);

    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey<String>('auth-email')),
          )
          .controller
          ?.text,
      'ada@example.com',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey<String>('auth-full-name')),
          )
          .controller
          ?.text,
      'Ada Lovelace',
    );
    expect(find.byKey(const ValueKey<String>('auth-password')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('auth-confirm-password')),
      findsNothing,
    );
    expect(find.text('Proceed'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('auth screen validates fields before submitting', (
    WidgetTester tester,
  ) async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(authClient.loginCalls, 0);

    controller.dispose();
  });

  testWidgets('sign-up details step checks email before advancing', (
    WidgetTester tester,
  ) async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await _continueSignUpToPasswordStep(
      tester,
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
    );

    expect(authClient.checkEmailCalls, 1);
    expect(find.byKey(const ValueKey<String>('auth-password')), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('sign-up details step stays put when email is already used', (
    WidgetTester tester,
  ) async {
    final _FakeAuthClient authClient = _FakeAuthClient(
      checkEmailError: const AuthApiException(
        AuthApiErrorCode.emailAlreadyInUse,
      ),
    );
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await _tapModeSwitch(tester);
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-full-name')),
      'Ada Lovelace',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'ada@example.com',
    );
    await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(authClient.checkEmailCalls, 1);
    expect(find.byKey(const ValueKey<String>('auth-password')), findsNothing);
    expect(find.text('This email is already in use.'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('auth screen blocks sign-up when passwords do not match', (
    WidgetTester tester,
  ) async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await _continueSignUpToPasswordStep(
      tester,
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      'super-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-confirm-password')),
      'wrong-secret',
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('auth-submit-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(authClient.signUpCalls, 0);

    controller.dispose();
  });

  testWidgets('auth screen submits sign-in through the controller', (
    WidgetTester tester,
  ) async {
    final _FakeAuthClient authClient = _FakeAuthClient();
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      'super-secret',
    );
    await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(authClient.loginCalls, 1);
    expect(controller.stage, AuthStage.authenticated);
    controller.dispose();
  });

  testWidgets('auth screen toggles only the password field visibility', (
    WidgetTester tester,
  ) async {
    final AuthController controller = AuthController(
      authClient: _FakeAuthClient(),
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    EditableText passwordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('auth-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(
      find.byKey(const ValueKey<String>('auth-password-visibility-toggle')),
    );
    await tester.pumpAndSettle();

    passwordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('auth-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordField.obscureText, isFalse);

    controller.dispose();
  });

  testWidgets(
    'auth screen toggles only the confirm-password field visibility',
    (WidgetTester tester) async {
      final AuthController controller = AuthController(
        authClient: _FakeAuthClient(),
        sessionStore: _MemorySessionStore(),
      );

      await tester.pumpWidget(
        buildLocalizedApp(home: _buildAuthScreen(controller)),
      );

      await _continueSignUpToPasswordStep(
        tester,
        fullName: 'Ada Lovelace',
        email: 'ada@example.com',
      );

      EditableText passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('auth-password')),
          matching: find.byType(EditableText),
        ),
      );
      EditableText confirmPasswordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('auth-confirm-password')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);
      expect(confirmPasswordField.obscureText, isTrue);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('auth-confirm-password-visibility-toggle'),
        ),
      );
      await tester.pumpAndSettle();

      passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('auth-password')),
          matching: find.byType(EditableText),
        ),
      );
      confirmPasswordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('auth-confirm-password')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isTrue);
      expect(confirmPasswordField.obscureText, isFalse);

      controller.dispose();
    },
  );

  testWidgets('auth screen clears password after unsuccessful sign-in', (
    WidgetTester tester,
  ) async {
    final _FakeAuthClient authClient = _FakeAuthClient(
      loginError: const AuthApiException(AuthApiErrorCode.invalidCredentials),
    );
    final AuthController controller = AuthController(
      authClient: authClient,
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(home: _buildAuthScreen(controller)),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'ada@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
    await tester.pumpAndSettle();

    final TextFormField passwordField = tester.widget<TextFormField>(
      find.byKey(const ValueKey<String>('auth-password')),
    );
    expect(authClient.loginCalls, 1);
    expect(controller.stage, AuthStage.signedOut);
    expect(passwordField.controller?.text, '');

    controller.dispose();
  });

  testWidgets('auth screen shows Ukrainian copy when locale is uk', (
    WidgetTester tester,
  ) async {
    final AuthController controller = AuthController(
      authClient: _FakeAuthClient(),
      sessionStore: _MemorySessionStore(),
    );

    await tester.pumpWidget(
      buildLocalizedApp(
        home: _buildAuthScreen(controller),
        locale: const Locale('uk'),
      ),
    );

    expect(find.text('Увійти'), findsWidgets);
    expect(find.text('Ще не маєте акаунта?'), findsOneWidget);
    expect(find.text('Зареєструватися'), findsOneWidget);

    await _tapModeSwitch(tester);

    expect(find.text('Зареєструватися'), findsOneWidget);
    expect(find.text('Продовжити'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('auth-password')), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('auth-confirm-password')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-full-name')),
      'Ада Лавлейс',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email')),
      'ada@example.com',
    );
    await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Зареєструватися'), findsWidgets);
    expect(find.text('Вже маєте акаунт?'), findsOneWidget);
    expect(find.text('Підтвердження пароля'), findsOneWidget);
    expect(find.text('Назад'), findsOneWidget);

    controller.dispose();
  });
}

class _FakeAuthClient implements AuthClient {
  _FakeAuthClient({this.loginError, this.checkEmailError});

  int checkEmailCalls = 0;
  int loginCalls = 0;
  int signUpCalls = 0;
  final AuthApiException? loginError;
  final AuthApiException? checkEmailError;

  @override
  void close() {}

  @override
  Future<void> checkEmail({required String email}) async {
    checkEmailCalls += 1;
    if (checkEmailError != null) {
      throw checkEmailError!;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls += 1;
    if (loginError != null) {
      throw loginError!;
    }
    return _session();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<void> deleteAccount({required String accessToken}) async {}

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    return _session();
  }

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    return _session();
  }
}

class _MemorySessionStore implements AuthSessionStore {
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

AuthSession _session() {
  return AuthSession(
    user: const AuthUser(
      id: 'user-1',
      fullName: 'Ada Lovelace',
      email: 'ada@example.com',
    ),
    accessToken: 'access-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(
      const Duration(minutes: 15),
    ),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
  );
}
