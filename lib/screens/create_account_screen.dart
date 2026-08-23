import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'experience_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _contact = TextEditingController();

  bool _showPassword = false;
  String? _error;

  /// Front end only: unlocks once every field has something in it.
  bool get _canContinue =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _contact.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _continue() {
    final email = _email.text.trim();

    // Stand-in checks so the error state is visible in demos.
    // Replace with server-side validation when auth is wired up.
    if (!email.contains('@')) {
      setState(() => _error = 'That email address is missing an @.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters for your password.');
      return;
    }

    setState(() => _error = null);

    // Nothing is persisted yet; this carries the name into later screens.
    HikerProfile.fullName = _name.text.trim();
    HikerProfile.email = email;
    HikerProfile.emergencyContact = _contact.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExperienceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  // Progress across the three onboarding steps.
                  const _StepBar(step: 1),
                  const SizedBox(height: 18),

                  Text(
                    'Create account',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Takes about a minute. You can change any of this later.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 26),

                  LabeledField(
                    label: 'Full name',
                    hint: 'Nukie Blaze',
                    controller: _name,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),

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
                    hint: 'At least 8 characters',
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
                  const SizedBox(height: 18),

                  LabeledField(
                    label: 'Emergency contact',
                    hint: 'Name and phone number',
                    controller: _contact,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() => _error = null),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
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

                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.forest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your emergency contact is alerted when you hold SOS '
                          'on the trail.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Continue',
                onPressed: _canContinue ? _continue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-segment progress bar shared by the onboarding steps.
class _StepBar extends StatelessWidget {
  final int step;
  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('STEP $step OF 3',
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: i < step ? AppColors.forest : AppColors.fill,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}