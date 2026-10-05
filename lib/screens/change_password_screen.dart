import "package:flutter/material.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";

/// The same rules the sign-up screen enforces, kept here so the two
/// cannot drift apart.
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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _saving = false;
  String? _error;

  bool get _passwordsMatch =>
      _confirm.text.isNotEmpty && _next.text == _confirm.text;

  bool get _canSave =>
      !_saving &&
      _current.text.isNotEmpty &&
      PasswordRules.allMet(_next.text) &&
      _passwordsMatch;

  /// Names what is still missing, so a disabled button is never a mystery.
  String? get _blockingReason {
    if (_current.text.isEmpty) return "Enter your current password.";
    if (_next.text.isEmpty) return "Choose a new password.";

    final problem = PasswordRules.firstProblem(_next.text);
    if (problem != null) return problem;

    if (_next.text == _current.text) {
      return "The new password must be different from the current one.";
    }
    if (_confirm.text.isEmpty) return "Confirm your new password.";
    if (!_passwordsMatch) return "The two new passwords do not match.";
    return null;
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text == _current.text) {
      setState(() =>
          _error = "The new password must be different from the current one.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await FirebaseService.changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Password changed."),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconButton _eye({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: AppColors.inkSoft,
      ),
      tooltip: visible ? "Hide password" : "Show password",
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _next.text;
    final blocking = _blockingReason;
    final showMismatch = _confirm.text.isNotEmpty && !_passwordsMatch;

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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text("Change password",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your current password first, then choose a new one.",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 26),

                  LabeledField(
                    label: "Current password",
                    hint: "Your password right now",
                    controller: _current,
                    obscure: !_showCurrent,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: _eye(
                      visible: _showCurrent,
                      onTap: () =>
                          setState(() => _showCurrent = !_showCurrent),
                    ),
                  ),

                  const SizedBox(height: 26),
                  const SectionLabel("New password"),
                  const SizedBox(height: 14),

                  LabeledField(
                    label: "Enter new password",
                    hint: "e.g. Trail@2026",
                    controller: _next,
                    obscure: !_showNext,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: _eye(
                      visible: _showNext,
                      onTap: () => setState(() => _showNext = !_showNext),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live checklist, matching the one on the sign-up screen.
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

                  const SizedBox(height: 20),
                  LabeledField(
                    label: "Confirm new password",
                    hint: "Type the same password again",
                    controller: _confirm,
                    obscure: !_showConfirm,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: _eye(
                      visible: _showConfirm,
                      onTap: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showMismatch)
                    _StatusLine(
                      icon: Icons.error_outline,
                      color: AppColors.alert,
                      text: "Passwords do not match.",
                    )
                  else if (_passwordsMatch)
                    _StatusLine(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.forest,
                      text: "Passwords match.",
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
                          child: Text(_error!,
                              style: TextStyle(
                                  color: AppColors.alert, fontSize: 13)),
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
                    label: _saving ? "Changing..." : "Change password",
                    onPressed: _canSave ? _save : null,
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
