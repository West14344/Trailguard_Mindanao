import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  String? _error;

  /// Front end only: the button unlocks once both fields have something in
  /// them. Real credential checking waits for the backend.
  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _logIn() {
    final email = _email.text.trim();

    // Stand-in for server-side validation so the error state is visible
    // in demos. Delete this block when auth is wired up.
    if (!email.contains('@')) {
      setState(() => _error = 'That email address is missing an @.');
      return;
    }

    setState(() => _error = null);
    HikerProfile.email = email;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged in — dashboard arrives in a later module'),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 24, 0),
              child: BackHeader('Welcome back'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Text(
                    'Log in to pick up your saved trails and group.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  LabeledField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    label: 'Password',
                    hint: 'Your password',
                    controller: _password,
                    obscure: !_showPassword,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.inkSoft,
                      ),
                      tooltip:
                          _showPassword ? 'Hide password' : 'Show password',
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.alert),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.alert,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset needs the backend'),
                            backgroundColor: AppColors.pine,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Log in',
                    onPressed: _canSubmit ? _logIn : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New here?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.forest,
                        ),
                        child: const Text('Create an account'),
                      ),
                    ],
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