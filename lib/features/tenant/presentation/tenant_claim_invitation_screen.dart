import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

class TenantClaimInvitationScreen extends StatefulWidget {
  const TenantClaimInvitationScreen({super.key});

  @override
  State<TenantClaimInvitationScreen> createState() =>
      _TenantClaimInvitationScreenState();
}

class _TenantClaimInvitationScreenState
    extends State<TenantClaimInvitationScreen> {
  final _controller = TextEditingController();
  String? _error;

  static final _uuidPattern = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue(AppLocalizations l10n) {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = l10n.claimInvitationEmptyError);
      return;
    }

    final token = _extractToken(input);
    if (token == null) {
      setState(() => _error = l10n.claimInvitationInvalidError);
      return;
    }

    context.go('/join?token=$token');
  }

  String? _extractToken(String input) {
    // Try parsing as a URI with a token query parameter.
    try {
      final uri = Uri.parse(input);
      final token = uri.queryParameters['token'];
      if (token != null && _uuidPattern.hasMatch(token)) return token;
    } catch (_) {}

    // Fall back to the first UUID-shaped substring in the input.
    return _uuidPattern.firstMatch(input)?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.claimInvitationTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.claimInvitationFieldLabel,
                hintText: l10n.claimInvitationFieldHint,
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _onContinue(l10n),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _onContinue(l10n),
              child: Text(l10n.claimInvitationContinue),
            ),
          ],
        ),
      ),
    );
  }
}
