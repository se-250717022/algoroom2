import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  PhoneChallenge? _challenge;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final backend = ref.watch(authRepositoryProvider);
    final repository = backend.value;
    final challenge = _challenge;
    final canSignIn = repository != null && !_busy;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.brand)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(strings.signIn, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(strings.signInIntro),
                const SizedBox(height: 24),
                if (backend.isLoading || _busy) const LinearProgressIndicator(),
                if (repository == null && !backend.isLoading) ...[
                  Text(
                    backend.hasError
                        ? strings.authSetupError
                        : strings.authNotConfigured,
                  ),
                  if (backend.hasError)
                    TextButton(
                      onPressed: () {
                        ref.invalidate(authRepositoryProvider);
                        ref.invalidate(signedInProvider);
                      },
                      child: Text(strings.retry),
                    ),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _form,
                  child: challenge == null
                      ? TextFormField(
                          key: const ValueKey('phone'),
                          controller: _phone,
                          enabled: canSignIn,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: InputDecoration(
                            labelText: strings.phoneNumber,
                            hintText: '+90 5XX XXX XX XX',
                          ),
                          validator: (value) =>
                              normalizePhoneNumber(value ?? '') == null
                              ? strings.invalidPhone
                              : null,
                        )
                      : TextFormField(
                          key: const ValueKey('sms-code'),
                          controller: _code,
                          enabled: canSignIn,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            labelText: strings.smsCode,
                          ),
                          validator: (value) => (value?.length ?? 0) != 6
                              ? strings.invalidCode
                              : null,
                        ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: !canSignIn
                      ? null
                      : () {
                          if (!_form.currentState!.validate()) return;
                          if (challenge != null) {
                            _run(
                              () => challenge(_code.text),
                              strings.codeFailed,
                            );
                            return;
                          }
                          final number = normalizePhoneNumber(_phone.text)!;
                          _run(() async {
                            final sent = await repository.sendCode(number);
                            if (mounted) setState(() => _challenge = sent);
                          }, strings.smsFailed);
                        },
                  child: Text(
                    challenge == null ? strings.sendSms : strings.verifyCode,
                  ),
                ),
                if (challenge != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _challenge = null;
                            _error = null;
                            _code.clear();
                          }),
                    child: Text(strings.changeNumber),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: !canSignIn
                      ? null
                      : () => _run(
                          repository.signInWithGoogle,
                          strings.googleFailed,
                        ),
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(strings.continueGoogle),
                ),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () => context.go('/demo'),
                  child: Text(strings.openDemo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
