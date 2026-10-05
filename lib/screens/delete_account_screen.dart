import "package:flutter/material.dart";
import "../data/hike_records.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _password = TextEditingController();
  final _confirmText = TextEditingController();

  bool _showPassword = false;
  bool _deleting = false;
  String? _error;

  /// Typing the word out makes this hard to do by accident.
  static const _confirmWord = "DELETE";

  bool get _canDelete =>
      !_deleting &&
      _password.text.isNotEmpty &&
      _confirmText.text.trim().toUpperCase() == _confirmWord;

  @override
  void dispose() {
    _password.dispose();
    _confirmText.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Delete permanently?"),
        content: Text(
          "Your account, hike history, badges and group membership will be "
          "erased. This cannot be undone.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: Text("Keep my account"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: const Text("Delete forever"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
      _error = null;
    });

    final error =
        await FirebaseService.deleteAccount(password: _password.text);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _deleting = false;
        _error = error;
      });
      return;
    }

    // Everything is gone, so drop the whole navigation stack.
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed("/");
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
                    onPressed: _deleting
                        ? null
                        : () => Navigator.of(context).maybePop(),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text("Delete account",
                      style: Theme.of(context).textTheme.headlineMedium),
                  SizedBox(height: 8),
                  Text(
                    "This erases your account and everything in it. There is "
                    "no way to recover it afterwards.",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                  SizedBox(height: 22),

                  // Showing what is lost is fairer than a vague warning.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x0DB3261E),
                      borderRadius: AppRadius.card,
                      border: Border.all(color: AppColors.alert, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You will lose",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.alert,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LossRow(
                          icon: Icons.hiking_rounded,
                          text: "${HikeLog.totalHikes} completed "
                              "${HikeLog.totalHikes == 1 ? "hike" : "hikes"}",
                        ),
                        _LossRow(
                          icon: Icons.straighten_rounded,
                          text: "${HikeLog.totalKm.toStringAsFixed(1)} km "
                              "of recorded distance",
                        ),
                        _LossRow(
                          icon: Icons.military_tech_rounded,
                          text: "${HikeLog.earnedBadgeCount} earned "
                              "${HikeLog.earnedBadgeCount == 1 ? "badge" : "badges"}",
                        ),
                        if (GroupSession.isActive)
                          _LossRow(
                            icon: Icons.groups_outlined,
                            text: "Your place in ${GroupSession.name}",
                          ),
                        _LossRow(
                          icon: Icons.person_outline,
                          text: "Your profile and emergency contact",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 26),
                  LabeledField(
                    label: "Confirm your password",
                    hint: "Your current password",
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

                  SizedBox(height: 20),
                  LabeledField(
                    label: "Type $_confirmWord to confirm",
                    hint: _confirmWord,
                    controller: _confirmText,
                    onChanged: (_) => setState(() => _error = null),
                  ),

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
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _canDelete ? _delete : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.alertFill,
                    foregroundColor: AppColors.onAlert,
                    disabledBackgroundColor: AppColors.fill,
                    disabledForegroundColor: AppColors.inkSoft,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.pill),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: Text(
                      _deleting ? "Deleting..." : "Delete my account"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LossRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _LossRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.alert),
          SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}











