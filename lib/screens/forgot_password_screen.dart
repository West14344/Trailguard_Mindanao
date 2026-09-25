import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";

/// The password rules, in one place so the checklist and the button agree.
class PasswordRules {
  static bool startsWithUppercase(String p) => RegExp(r"^[A-Z]").hasMatch(p);
  static bool hasNumber(String p) => RegExp(r"\d").hasMatch(p);
  static bool hasSymbol(String p) => RegExp(r"[^A-Za-z0-9\s]").hasMatch(p);
  static bool longEnough(String p) => p.length >= 8;

  static bool allMet(String p) =>
      startsWithUppercase(p) && hasNumber(p) && hasSymbol(p) && longEnough(p);
}

enum _Step { email, code, password, done }

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ""});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _link = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _error;
  String? _oobCode;

  Timer? _cooldown;
  int _resendIn = 0;

  @override
  void dispose() {
    _email.dispose();
    _link.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _cooldown?.cancel();
    super.dispose();
  }

  String get _cleanEmail => _email.text.trim().toLowerCase();

  bool get _passwordsMatch =>
      _confirmPassword.text.isNotEmpty &&
      _newPassword.text == _confirmPassword.text;

  bool get _canSavePassword =>
      PasswordRules.allMet(_newPassword.text) && _passwordsMatch;

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _resendIn = 60);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendEmail() async {
    if (!_cleanEmail.contains("@")) {
      setState(() => _error = "Enter a valid email address.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await FirebaseService.sendPasswordReset(_cleanEmail);
    if (!mounted) return;

    setState(() => _busy = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    _link.clear();
    _startCooldown();
    setState(() => _step = _Step.code);
  }

  /// Pulls the oobCode parameter out of the pasted reset link.
  String? _extractCode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final code = uri?.queryParameters["oobCode"];
    if (code != null && code.isNotEmpty) return code;
    // Allow pasting just the code itself.
    if (!text.contains("/") && text.length > 15) return text;
    return null;
  }

  Future<void> _verifyLink() async {
    final code = _extractCode(_link.text);
    if (code == null) {
      setState(() => _error =
          "That does not look like the reset link. Copy the whole link "
          "from the email.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final email = await FirebaseService.verifyResetCode(code);
      if (!mounted) return;
      _oobCode = code;
      _email.text = email;
      setState(() {
        _busy = false;
        _step = _Step.password;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _savePassword() async {
    if (!PasswordRules.allMet(_newPassword.text)) {
      setState(() => _error = "Your password does not meet all the rules.");
      return;
    }
    if (!_passwordsMatch) {
      setState(() => _error = "The two passwords do not match.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await FirebaseService.confirmReset(
      code: _oobCode!,
      newPassword: _newPassword.text,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _step = _Step.done);
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      setState(() => _error = "Nothing was copied yet.");
      return;
    }
    setState(() {
      _link.text = text;
      _error = null;
    });
  }

  void _back() {
    setState(() {
      _error = null;
      switch (_step) {
        case _Step.code:
          _step = _Step.email;
        case _Step.password:
          _step = _Step.code;
        case _Step.email:
        case _Step.done:
          Navigator.of(context).maybePop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.email,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == _Step.done) {
          Navigator.of(context).pop(_cleanEmail);
        } else {
          _back();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_step != _Step.done)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : _back,
                        icon: Icon(Icons.arrow_back, size: 20),
                        label: Text("Back"),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      _Step.email => _emailStep(),
                      _Step.code => _linkStep(),
                      _Step.password => _passwordStep(),
                      _Step.done => _doneStep(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layout({
    required int stepNumber,
    required String title,
    required String subtitle,
    required List<Widget> fields,
    required String buttonLabel,
    required VoidCallback? onPressed,
    Widget? footer,
  }) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              _ProgressBar(step: stepNumber),
              SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 8),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5)),
              SizedBox(height: 28),
              ...fields,
              if (_error != null) ...[
                SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: AppColors.alert),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              color: AppColors.alert, fontSize: 13)),
                    ),
                  ],
                ),
              ],
              if (footer != null) ...[const SizedBox(height: 18), footer],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: PrimaryButton(
            label: _busy ? "Please wait..." : buttonLabel,
            onPressed: _busy ? null : onPressed,
          ),
        ),
      ],
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

  Widget _emailStep() {
    return _layout(
      stepNumber: 1,
      title: "Forgot password?",
      subtitle: "Enter the email you signed up with and we will send a "
          "reset link to it.",
      fields: [
        LabeledField(
          label: "Email",
          hint: "you@example.com",
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
      buttonLabel: "Send reset email",
      onPressed: _cleanEmail.isEmpty ? null : _sendEmail,
    );
  }

  Widget _linkStep() {
    return _layout(
      stepNumber: 2,
      title: "Paste the link",
      subtitle: "We sent a reset link to $_cleanEmail. Open the email, "
          "press and hold the link, choose Copy link, then paste it here. "
          "Check your spam folder if it has not arrived.",
      fields: [
        LabeledField(
          label: "Reset link",
          hint: "https://...",
          controller: _link,
          maxLines: 3,
          onChanged: (_) => setState(() => _error = null),
        ),
        SizedBox(height: 12),
        SecondaryButton(
          label: "Paste from clipboard",
          icon: Icons.content_paste_rounded,
          onPressed: _pasteLink,
        ),
      ],
      footer: Center(
        child: TextButton(
          onPressed: (_resendIn > 0 || _busy) ? null : _sendEmail,
          style: TextButton.styleFrom(foregroundColor: AppColors.forest),
          child: Text(_resendIn > 0
              ? "Resend email in ${_resendIn}s"
              : "Did not get it? Resend email"),
        ),
      ),
      buttonLabel: "Continue",
      onPressed: _link.text.trim().isEmpty ? null : _verifyLink,
    );
  }

  Widget _passwordStep() {
    final p = _newPassword.text;
    final showMismatch =
        _confirmPassword.text.isNotEmpty && !_passwordsMatch;

    return _layout(
      stepNumber: 3,
      title: "Create a new password",
      subtitle: "Every other device signed in to this account will be "
          "logged out once you save.",
      fields: [
        LabeledField(
          label: "Enter new password",
          hint: "e.g. Trail@2026",
          controller: _newPassword,
          obscure: !_showNew,
          onChanged: (_) => setState(() => _error = null),
          suffix: _eye(
            visible: _showNew,
            onTap: () => setState(() => _showNew = !_showNew),
          ),
        ),
        SizedBox(height: 14),
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
              Text("Your password must:",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      )),
              const SizedBox(height: 8),
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
              _RuleRow(
                met: PasswordRules.longEnough(p),
                text: "Be at least 8 characters long",
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        LabeledField(
          label: "Confirm password",
          hint: "Type the same password again",
          controller: _confirmPassword,
          obscure: !_showConfirm,
          onChanged: (_) => setState(() => _error = null),
          suffix: _eye(
            visible: _showConfirm,
            onTap: () => setState(() => _showConfirm = !_showConfirm),
          ),
        ),
        SizedBox(height: 8),
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
      ],
      buttonLabel: "Continue",
      onPressed: _canSavePassword ? _savePassword : null,
    );
  }

  Widget _doneStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 46, color: AppColors.forest),
          ),
          const SizedBox(height: 22),
          Text("Password updated",
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "You can now log in with your new password.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          PrimaryButton(
            label: "Back to log in",
            onPressed: () => Navigator.of(context).pop(_cleanEmail),
          ),
        ],
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
          SizedBox(width: 9),
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
        Text(text,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("STEP $step OF 3", style: Theme.of(context).textTheme.labelSmall),
        SizedBox(width: 12),
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











