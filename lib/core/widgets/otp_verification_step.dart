import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// A self-contained OTP entry widget shared between the signup and join flows.
///
/// Renders a title, a subtitle showing [email], eight digit-boxes, an optional
/// error message, a verify button, and a resend link. Automatically submits
/// when all eight boxes are filled.
class OtpVerificationStep extends StatefulWidget {
  final String email;
  final bool isLoading;
  final bool hasError;
  final AppLocalizations l10n;
  final ValueChanged<String> onSubmit;
  final VoidCallback onResend;

  const OtpVerificationStep({
    super.key,
    required this.email,
    required this.isLoading,
    required this.hasError,
    required this.l10n,
    required this.onSubmit,
    required this.onResend,
  });

  @override
  State<OtpVerificationStep> createState() => _OtpVerificationStepState();
}

class _OtpVerificationStepState extends State<OtpVerificationStep> {
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
        if (widget.hasError) ...[
          const SizedBox(height: 12),
          Text(
            l10n.errorInvalidCode,
            style: TextStyle(color: colors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.isLoading ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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
