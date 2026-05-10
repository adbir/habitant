import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import 'login_view_model.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(authService: widget.authService);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    _viewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AdaptiveLayout(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(tagline: l10n.appTagline),
                    const SizedBox(height: 48),
                    _EmailField(
                      controller: _emailController,
                      label: l10n.emailLabel,
                      passwordFocusNode: _passwordFocusNode,
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      controller: _passwordController,
                      label: l10n.passwordLabel,
                      focusNode: _passwordFocusNode,
                      onSubmitted: _submit,
                    ),
                    if (_viewModel.error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorMessage(
                        message: _errorText(l10n, _viewModel.error!),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SubmitButton(
                      label: l10n.loginButton,
                      isLoading: _viewModel.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    _SignupLink(l10n: l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  String _errorText(AppLocalizations l10n, LoginError error) =>
      switch (error) {
        LoginError.emptyFields => l10n.errorEmptyFields,
        LoginError.invalidCredentials => l10n.errorInvalidCredentials,
        LoginError.generic => l10n.errorGeneric,
      };
}

class _Header extends StatelessWidget {
  final String tagline;

  const _Header({required this.tagline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habitant',
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tagline,
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode passwordFocusNode;

  const _EmailField({
    required this.controller,
    required this.label,
    required this.passwordFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      onSubmitted: (_) => passwordFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 13,
      ),
    );
  }
}

class _SignupLink extends StatelessWidget {
  final AppLocalizations l10n;

  const _SignupLink({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => context.push('/signup'),
        child: Text(l10n.createAccountLink),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}
