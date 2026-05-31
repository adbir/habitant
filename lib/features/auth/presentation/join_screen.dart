import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../../../core/widgets/otp_verification_step.dart';
import '../../../l10n/app_localizations.dart';
import 'join_view_model.dart';

class JoinScreen extends StatefulWidget {
  final String token;
  final ApiClient apiClient;
  final AuthService authService;

  const JoinScreen({
    super.key,
    required this.token,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late final JoinViewModel _viewModel;

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
    _viewModel = JoinViewModel(
      apiClient: widget.apiClient,
      authService: widget.authService,
    );
    _viewModel.loadInvitation(widget.token);
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
        appBar: _buildAppBar(),
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

  AppBar _buildAppBar() {
    final step = _viewModel.step;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Only allow back on the preview — once credentials are submitted the
      // auth account exists and back navigation makes no sense.
      automaticallyImplyLeading: step == JoinStep.preview,
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    return switch (_viewModel.step) {
      JoinStep.loading => const Center(child: CircularProgressIndicator()),
      JoinStep.invalidToken => _InvalidTokenStep(l10n: l10n),
      JoinStep.preview => _PreviewStep(
          viewModel: _viewModel,
          l10n: l10n,
        ),
      JoinStep.credentials => _CredentialsStep(
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
      JoinStep.verification => OtpVerificationStep(
          email: _viewModel.email,
          isLoading: _viewModel.isLoading,
          hasError: _viewModel.error == JoinError.invalidCode,
          l10n: l10n,
          onSubmit: _viewModel.submitCode,
          onResend: _viewModel.resendCode,
        ),
    };
  }
}

// ---- Invalid token ----------------------------------------------------------

class _InvalidTokenStep extends StatelessWidget {
  final AppLocalizations l10n;

  const _InvalidTokenStep({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.link_off, size: 48, color: colors.error),
        const SizedBox(height: 24),
        Text(
          l10n.joinInvalidTokenTitle,
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.joinInvalidTokenBody,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => context.go('/login'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(l10n.joinGoToLogin),
        ),
      ],
    );
  }
}

// ---- Preview step -----------------------------------------------------------

class _PreviewStep extends StatelessWidget {
  final JoinViewModel viewModel;
  final AppLocalizations l10n;

  const _PreviewStep({required this.viewModel, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final inv = viewModel.invitation!;
    final address = inv.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.joinTitle,
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.joinSubtitle,
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        _AddressPreviewCard(
          housingName: inv.housingName,
          address: address?.displayAddress,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: viewModel.proceed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(l10n.joinContinueButton),
        ),
        const SizedBox(height: 16),
        _GoToLoginLink(l10n: l10n),
      ],
    );
  }
}

class _AddressPreviewCard extends StatelessWidget {
  final String? housingName;
  final String? address;

  const _AddressPreviewCard({this.housingName, this.address});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.home_outlined, color: colors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (housingName != null)
                    Text(
                      housingName!,
                      style: text.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (address != null)
                    Text(
                      address!,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoToLoginLink extends StatelessWidget {
  final AppLocalizations l10n;

  const _GoToLoginLink({required this.l10n});

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

// ---- Credentials step -------------------------------------------------------

class _CredentialsStep extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController phoneController;
  final FocusNode passwordFocusNode;
  final FocusNode confirmFocusNode;
  final FocusNode phoneFocusNode;
  final bool isLoading;
  final JoinError? error;
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
          l10n.joinTitle,
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
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
          Text(
            _errorText(l10n, error!),
            style: TextStyle(color: colors.error, fontSize: 13),
          ),
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
      ],
    );
  }

  String _errorText(AppLocalizations l10n, JoinError error) =>
      switch (error) {
        JoinError.emptyFields => l10n.errorEmptyFields,
        JoinError.passwordMismatch => l10n.errorPasswordMismatch,
        JoinError.passwordTooShort => l10n.errorPasswordTooShort,
        JoinError.emailTaken => l10n.errorEmailTaken,
        JoinError.invalidCredentials => l10n.errorInvalidCredentials,
        JoinError.invalidCode => l10n.errorInvalidCode,
        JoinError.rateLimited => l10n.errorRateLimited,
        JoinError.generic => l10n.errorGeneric,
      };
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
