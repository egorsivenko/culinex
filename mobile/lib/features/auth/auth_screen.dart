import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../../core/theme/culinex_theme.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../l10n/l10n.dart';
import '../home/culinex_header.dart';
import 'auth_controller.dart';

enum AuthFormMode { signIn, signUp }

enum _SignUpStep { details, password }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.controller,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.locale,
    required this.onSelectLocale,
    super.key,
  });

  final AuthController controller;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onSelectLocale;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  AuthFormMode _mode = AuthFormMode.signIn;
  _SignUpStep _signUpStep = _SignUpStep.details;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, _) {
        final AuthErrorState? error = widget.controller.error;
        final CulinexPalette colors = CulinexColors.of(context);
        final TextTheme textTheme = Theme.of(context).textTheme;
        final l10n = context.l10n;
        final bool isSignIn = _mode == AuthFormMode.signIn;
        final bool showsSignUpDetails =
            _mode == AuthFormMode.signUp && _signUpStep == _SignUpStep.details;
        final bool showsSignUpPassword =
            _mode == AuthFormMode.signUp && _signUpStep == _SignUpStep.password;

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[colors.canvas, colors.elevatedSurface],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CulinexHeader(
                      isDarkMode: widget.isDarkMode,
                      onToggleTheme: widget.onToggleTheme,
                      locale: widget.locale,
                      onSelectLocale: widget.onSelectLocale,
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: GlassPanel(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      isSignIn
                                          ? l10n.authModeSignIn
                                          : l10n.authModeSignUp,
                                      style: textTheme.headlineMedium?.copyWith(
                                        color: colors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (showsSignUpPassword) ...<Widget>[
                                      TextButton.icon(
                                        key: const ValueKey<String>(
                                          'auth-sign-up-back-button',
                                        ),
                                        onPressed: _goToSignUpDetails,
                                        icon: const Icon(
                                          Icons.arrow_back_rounded,
                                        ),
                                        label: Text(l10n.authBackToDetails),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: colors.mutedInk,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (error != null) ...<Widget>[
                                      _AuthErrorBanner(
                                        message: _errorMessageFor(error.code),
                                        onDismiss: widget.controller.clearError,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (showsSignUpDetails) ...<Widget>[
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'auth-full-name',
                                        ),
                                        controller: _fullNameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: l10n.authFullNameLabel,
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                          ),
                                        ),
                                        validator: (String? value) {
                                          if (!showsSignUpDetails) {
                                            return null;
                                          }
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return l10n.authEnterFullName;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (isSignIn ||
                                        showsSignUpDetails) ...<Widget>[
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'auth-email',
                                        ),
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const <String>[
                                          AutofillHints.email,
                                        ],
                                        textInputAction: isSignIn
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        onFieldSubmitted: isSignIn
                                            ? null
                                            : (_) => _submit(),
                                        decoration: InputDecoration(
                                          labelText: l10n.authEmailLabel,
                                          prefixIcon: const Icon(
                                            Icons.mail_outline,
                                          ),
                                        ),
                                        validator: (String? value) {
                                          if (!isSignIn &&
                                              !showsSignUpDetails) {
                                            return null;
                                          }
                                          final String email =
                                              value?.trim() ?? '';
                                          if (email.isEmpty) {
                                            return l10n.authEnterEmail;
                                          }
                                          if (!EmailValidator.validate(email)) {
                                            return l10n.authEnterValidEmail;
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    if (isSignIn ||
                                        showsSignUpPassword) ...<Widget>[
                                      if (isSignIn) const SizedBox(height: 16),
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'auth-password',
                                        ),
                                        controller: _passwordController,
                                        obscureText: _isPasswordObscured,
                                        autofillHints: const <String>[
                                          AutofillHints.password,
                                        ],
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _submit(),
                                        decoration: InputDecoration(
                                          labelText: l10n.authPasswordLabel,
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          suffixIcon:
                                              _buildPasswordVisibilityToggle(
                                                key: const ValueKey<String>(
                                                  'auth-password-visibility-toggle',
                                                ),
                                                isObscured: _isPasswordObscured,
                                                onPressed: () {
                                                  setState(() {
                                                    _isPasswordObscured =
                                                        !_isPasswordObscured;
                                                  });
                                                },
                                              ),
                                        ),
                                        validator: (String? value) {
                                          if (!isSignIn &&
                                              !showsSignUpPassword) {
                                            return null;
                                          }
                                          final String password = value ?? '';
                                          if (password.isEmpty) {
                                            return l10n.authEnterPassword;
                                          }
                                          if (password.length < 8) {
                                            return l10n.authPasswordMinLength;
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    if (showsSignUpPassword) ...<Widget>[
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        key: const ValueKey<String>(
                                          'auth-confirm-password',
                                        ),
                                        controller: _confirmPasswordController,
                                        obscureText: _isConfirmPasswordObscured,
                                        autofillHints: const <String>[
                                          AutofillHints.password,
                                        ],
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _submit(),
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.authConfirmPasswordLabel,
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          suffixIcon: _buildPasswordVisibilityToggle(
                                            key: const ValueKey<String>(
                                              'auth-confirm-password-visibility-toggle',
                                            ),
                                            isObscured:
                                                _isConfirmPasswordObscured,
                                            onPressed: () {
                                              setState(() {
                                                _isConfirmPasswordObscured =
                                                    !_isConfirmPasswordObscured;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (String? value) {
                                          if (!showsSignUpPassword) {
                                            return null;
                                          }
                                          final String confirmPassword =
                                              value ?? '';
                                          if (confirmPassword.isEmpty) {
                                            return l10n.authConfirmPassword;
                                          }
                                          if (confirmPassword !=
                                              _passwordController.text) {
                                            return l10n.authPasswordsDoNotMatch;
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    PrimaryActionButton(
                                      key: const ValueKey<String>(
                                        'auth-submit-button',
                                      ),
                                      label: widget.controller.isSubmitting
                                          ? l10n.authSubmitLoading
                                          : isSignIn
                                          ? l10n.authModeSignIn
                                          : showsSignUpDetails
                                          ? l10n.proceed
                                          : l10n.authModeSignUp,
                                      onPressed: widget.controller.isSubmitting
                                          ? null
                                          : _submit,
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Wrap(
                                        spacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        alignment: WrapAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            _mode == AuthFormMode.signIn
                                                ? l10n.authSwitchToSignUpPrompt
                                                : l10n.authSwitchToSignInPrompt,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colors.mutedInk,
                                                ),
                                          ),
                                          TextButton(
                                            key: const ValueKey<String>(
                                              'auth-switch-mode-button',
                                            ),
                                            onPressed:
                                                widget.controller.isSubmitting
                                                ? null
                                                : () => _setMode(
                                                    _mode == AuthFormMode.signIn
                                                        ? AuthFormMode.signUp
                                                        : AuthFormMode.signIn,
                                                  ),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 0,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              _mode == AuthFormMode.signIn
                                                  ? l10n.authModeSignUp
                                                  : l10n.authModeSignIn,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setMode(AuthFormMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _signUpStep = _SignUpStep.details;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _isPasswordObscured = true;
      _isConfirmPasswordObscured = true;
    });
    widget.controller.clearError();
  }

  void _goToSignUpDetails() {
    setState(() {
      _signUpStep = _SignUpStep.details;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _isPasswordObscured = true;
      _isConfirmPasswordObscured = true;
    });
    widget.controller.clearError();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_mode == AuthFormMode.signIn) {
      await widget.controller.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted && widget.controller.error != null) {
        _passwordController.clear();
      }
      return;
    }

    if (_signUpStep == _SignUpStep.details) {
      final bool isEmailAvailable = await widget.controller.checkEmailAvailable(
        email: _emailController.text.trim(),
      );
      if (!mounted || !isEmailAvailable) {
        return;
      }

      setState(() {
        _signUpStep = _SignUpStep.password;
      });
      return;
    }

    await widget.controller.signUp(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  String _errorMessageFor(AuthErrorCode code) {
    final l10n = context.l10n;

    return switch (code) {
      AuthErrorCode.validationFailed => l10n.authErrorValidationFailed,
      AuthErrorCode.emailAlreadyInUse => l10n.authErrorEmailAlreadyInUse,
      AuthErrorCode.invalidCredentials => l10n.authErrorInvalidCredentials,
      AuthErrorCode.sessionExpired => l10n.authErrorSessionExpired,
      AuthErrorCode.requestTimedOut => l10n.authErrorRequestTimedOut,
      AuthErrorCode.networkUnavailable => l10n.authErrorNetworkUnavailable,
      AuthErrorCode.serverFailure => l10n.authErrorServerFailure,
      AuthErrorCode.unexpectedResponse => l10n.authErrorUnexpectedResponse,
    };
  }

  Widget _buildPasswordVisibilityToggle({
    required Key key,
    required bool isObscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      key: key,
      onPressed: onPressed,
      icon: Icon(
        isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      tooltip: isObscured
          ? context.l10n.authShowPassword
          : context.l10n.authHidePassword,
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
              tooltip: l10n.authDismissError,
            ),
          ],
        ),
      ),
    );
  }
}
