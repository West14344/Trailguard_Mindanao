import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
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
  final _contactName = TextEditingController();
  final _contactNumber = TextEditingController();

  bool _showPassword = false;
  bool _saving = false;
  String? _error;

  bool get _canContinue =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _contactName.text.trim().isNotEmpty &&
      _contactNumber.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _contactName.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();

    if (!email.contains('@')) {
      setState(() => _error = 'That email address is missing an @.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters for your password.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await FirebaseService.signUp(
      fullName: _name.text.trim(),
      email: email,
      password: _password.text,
      emergencyContactName: _contactName.text.trim(),
      emergencyContactNumber: _contactNumber.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    setState(() => _saving = false);
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
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).maybePop(),
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
                  const _StepBar(step: 1),
                  const SizedBox(height: 18),

                  Text('Create account',
                      style: Theme.of(context).textTheme.headlineMedium),
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

                  const SizedBox(height: 30),
                  const SectionLabel('Emergency contact'),
                  const SizedBox(height: 14),

                  LabeledField(
                    label: 'Name of contact person',
                    hint: 'Benhard Awanon',
                    controller: _contactName,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),

                  LabeledField(
                    label: 'Number of contact person',
                    hint: '+63 912 345 6789',
                    controller: _contactNumber,
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
                          'This person is alerted with your location when you '
                          'hold SOS on the trail.',
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
                label: _saving ? 'Creating account…' : 'Continue',
                onPressed: (_canContinue && !_saving) ? _continue : null,
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
        Text('STEP $step OF 3', style: Theme.of(context).textTheme.labelSmall),
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