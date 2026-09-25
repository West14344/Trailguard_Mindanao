import "package:flutter/material.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";
import "experience_screen.dart";

/// Password rules, in one place so the checklist and the button agree.
class PasswordRules {
  static bool startsWithUppercase(String p) => RegExp(r"^[A-Z]").hasMatch(p);
  static bool hasNumber(String p) => RegExp(r"\d").hasMatch(p);
  static bool hasSymbol(String p) => RegExp(r"[^A-Za-z0-9\s]").hasMatch(p);
  static bool longEnough(String p) => p.length >= 8;

  static bool allMet(String p) =>
      startsWithUppercase(p) && hasNumber(p) && hasSymbol(p) && longEnough(p);

  /// The single most useful thing to tell the hiker right now.
  static String? firstProblem(String p) {
    if (p.isEmpty) return null;
    if (!longEnough(p)) {
      return "Password is too short. It must be 8 characters or more.";
    }
    if (!startsWithUppercase(p)) {
      return "Password must start with an uppercase letter.";
    }
    if (!hasNumber(p)) return "Password must include at least one number.";
    if (!hasSymbol(p)) return "Password must include at least one symbol.";
    return null;
  }
}

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
  final _contactEmail = TextEditingController();
  final _contactNumber = TextEditingController();

  bool _showPassword = false;
  bool _saving = false;
  String? _error;

  bool get _passwordValid => PasswordRules.allMet(_password.text);

  /// Gmail specifically, since that is what the emergency alert would
  /// be sent to.
  bool get _contactEmailValid {
    final e = _contactEmail.text.trim().toLowerCase();
    return RegExp(r"^[\w.+-]+@gmail\.com$").hasMatch(e);
  }

  bool get _canContinue =>
      !_saving &&
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _passwordValid &&
      _contactName.text.trim().isNotEmpty &&
      _contactEmailValid &&
      _contactNumber.text.trim().isNotEmpty;

  /// Names what is still missing, so a disabled button is never a mystery.
  String? get _blockingReason {
    if (_name.text.trim().isEmpty) return "Enter your full name.";
    if (_email.text.trim().isEmpty) return "Enter your email address.";
    if (_password.text.isEmpty) return "Choose a password.";

    final passwordProblem = PasswordRules.firstProblem(_password.text);
    if (passwordProblem != null) return passwordProblem;

    if (_contactName.text.trim().isEmpty) {
      return "Enter your emergency contact's name.";
    }
    if (_contactEmail.text.trim().isEmpty) {
      return "Enter your emergency contact's Gmail address.";
    }
    if (!_contactEmailValid) {
      return "The emergency contact must use a Gmail address.";
    }
    if (_contactNumber.text.trim().isEmpty) {
      return "Enter your emergency contact's number.";
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _contactName.dispose();
    _contactEmail.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();

    if (!email.contains("@")) {
      setState(() => _error = "That email address is missing an @.");
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
      emergencyContactEmail: _contactEmail.text.trim().toLowerCase(),
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
    final p = _password.text;
    final blocking = _blockingReason;
    final contactEmailTyped = _contactEmail.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text("Back"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
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

                  Text("Create account",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Takes about a minute. You can change any of this later.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 26),

                  LabeledField(
                    label: "Full name",
                    hint: "Nukie Blaze",
                    controller: _name,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),

                  LabeledField(
                    label: "Email",
                    hint: "you@example.com",
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),

                  LabeledField(
                    label: "Password",
                    hint: "e.g. Trail@2026",
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
                          _showPassword ? "Hide password" : "Show password",
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live checklist. Each rule turns green as it is met, so
                  // the requirements are visible before submitting.
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppRadius.field,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your password must:",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _RuleRow(
                          met: PasswordRules.longEnough(p),
                          text: "Be 8 characters or more",
                        ),
                        _RuleRow(
                          met: PasswordRules.startsWithUppercase(p),
                          text: "Start with an uppercase letter (A-Z)",
                        ),
                        _RuleRow(
                          met: PasswordRules.hasNumber(p),
                          text: "Include at least one number (0-9)",
                        ),
                        _RuleRow(
                          met: PasswordRules.hasSymbol(p),
                          text: "Include at least one symbol (! @ # % & *)",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const SectionLabel("Emergency contact"),
                  const SizedBox(height: 6),
                  Text(
                    "This person is alerted with your location when you hold "
                    "SOS on the trail.",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 16),

                  LabeledField(
                    label: "Name of contact person",
                    hint: "Benhard Awanon",
                    controller: _contactName,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),

                  LabeledField(
                    label: "Gmail of contact person",
                    hint: "contact@gmail.com",
                    controller: _contactEmail,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  if (contactEmailTyped && !_contactEmailValid) ...[
                    const SizedBox(height: 8),
                    _StatusLine(
                      icon: Icons.error_outline,
                      color: AppColors.blaze,
                      text: "Must be a Gmail address ending in @gmail.com",
                    ),
                  ] else if (_contactEmailValid) ...[
                    const SizedBox(height: 8),
                    _StatusLine(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.forest,
                      text: "Valid Gmail address",
                    ),
                  ],
                  const SizedBox(height: 18),

                  LabeledField(
                    label: "Number of contact person",
                    hint: "+63 912 345 6789",
                    controller: _contactNumber,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() => _error = null),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: AppColors.alert),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                                color: AppColors.alert, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (blocking != null && !_saving) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 15, color: AppColors.inkSoft),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(blocking,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: _saving ? "Creating account..." : "Continue",
                    onPressed: _canContinue ? _continue : null,
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

class _RuleRow extends StatelessWidget {
  final bool met;
  final String text;
  const _RuleRow({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 17,
            color: met ? AppColors.forest : AppColors.inkSoft,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: met ? AppColors.forest : AppColors.inkSoft,
                fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ),
      ],
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
        Text("STEP $step OF 3", style: Theme.of(context).textTheme.labelSmall),
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


