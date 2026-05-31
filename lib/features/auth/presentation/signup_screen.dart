import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../l10n/app_localizations.dart';
import 'signup_view_model.dart';

class SignupScreen extends StatefulWidget {
  final AuthService authService;
  final String? verifyEmail;

  const SignupScreen({
    super.key,
    required this.authService,
    this.verifyEmail,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final SignupViewModel _viewModel;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = SignupViewModel(
      authService: widget.authService,
      verifyEmail: widget.verifyEmail,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: AdaptiveLayout(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildStep(context, l10n),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    return switch (_viewModel.step) {
      SignupStep.credentials => _CredentialsStep(
          emailController: _emailController,
          passwordController: _passwordController,
          confirmController: _confirmController,
          phoneController: _phoneController,
          passwordFocusNode: _passwordFocusNode,
          confirmFocusNode: _confirmFocusNode,
          phoneFocusNode: _phoneFocusNode,
          isLoading: _viewModel.isLoading,
          error: _viewModel.error,
          l10n: l10n,
          onSubmit: () => _viewModel.submitCredentials(
            _emailController.text.trim(),
            _passwordController.text,
            _confirmController.text,
            phoneNumber: _phoneController.text.trim(),
          ),
        ),
      SignupStep.verification => _VerificationStep(
          email: _viewModel.email,
          isLoading: _viewModel.isLoading,
          error: _viewModel.error,
          l10n: l10n,
          onSubmit: _viewModel.submitCode,
          onResend: _viewModel.resendCode,
        ),
    };
  }
}

// ---- Step 1: Credentials ----------------------------------------------------

class _CredentialsStep extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController phoneController;
  final FocusNode passwordFocusNode;
  final FocusNode confirmFocusNode;
  final FocusNode phoneFocusNode;
  final bool isLoading;
  final SignupError? error;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;

  const _CredentialsStep({
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.phoneController,
    required this.passwordFocusNode,
    required this.confirmFocusNode,
    required this.phoneFocusNode,
    required this.isLoading,
    required this.error,
    required this.l10n,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.signupTitle,
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appTagline,
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          onSubmitted: (_) => passwordFocusNode.requestFocus(),
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => confirmFocusNode.requestFocus(),
          decoration: InputDecoration(
            labelText: l10n.passwordLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmController,
          focusNode: confirmFocusNode,
          obscureText: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => phoneFocusNode.requestFocus(),
          decoration: InputDecoration(
            labelText: l10n.confirmPasswordLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          focusNode: phoneFocusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: l10n.phoneLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(message: _errorText(l10n, error!)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isLoading ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: isLoading
              ? const _LoadingIndicator()
              : Text(l10n.nextButton),
        ),
        const SizedBox(height: 20),
        _LoginLink(l10n: l10n),
      ],
    );
  }

  String _errorText(AppLocalizations l10n, SignupError error) =>
      switch (error) {
        SignupError.emptyFields => l10n.errorEmptyFields,
        SignupError.passwordMismatch => l10n.errorPasswordMismatch,
        SignupError.passwordTooShort => l10n.errorPasswordTooShort,
        SignupError.emailTaken => l10n.errorEmailTaken,
        SignupError.invalidCode => l10n.errorInvalidCode,
        SignupError.rateLimited => l10n.errorRateLimited,
        SignupError.generic => l10n.errorGeneric,
      };
}

// ---- Step 2: Email verification ---------------------------------------------

class _VerificationStep extends StatefulWidget {
  final String email;
  final bool isLoading;
  final SignupError? error;
  final AppLocalizations l10n;
  final ValueChanged<String> onSubmit;
  final VoidCallback onResend;

  const _VerificationStep({
    required this.email,
    required this.isLoading,
    required this.error,
    required this.l10n,
    required this.onSubmit,
    required this.onResend,
  });

  @override
  State<_VerificationStep> createState() => _VerificationStepState();
}

class _VerificationStepState extends State<_VerificationStep> {
  static const _otpLength = 8;
  final _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onBoxChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_currentCode.length == _otpLength) {
      widget.onSubmit(_currentCode);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _submit() {
    final code = _currentCode;
    if (code.length == _otpLength) widget.onSubmit(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.verifyEmailTitle,
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.verifyEmailSentTo(widget.email),
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            _otpLength,
            (i) => _OtpBox(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              onChanged: (v) => _onBoxChanged(i, v),
              onKeyEvent: (e) => _onKeyEvent(i, e),
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(message: l10n.errorInvalidCode),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: widget.isLoading
              ? const _LoadingIndicator()
              : Text(l10n.verifyButton),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.isLoading ? null : widget.onResend,
          child: Text(l10n.resendCode),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      onKeyEvent: (_, event) {
        onKeyEvent(event);
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: 44,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 1,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

// ---- Shared helpers ---------------------------------------------------------

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText({required this.message});

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

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}

class _LoginLink extends StatelessWidget {
  final AppLocalizations l10n;

  const _LoginLink({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(l10n.loginLink),
        ),
      ],
    );
  }
}
