import "dart:math";

import "package:flutter/material.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";

class _SetupBackBar extends StatelessWidget {
  final bool disabled;
  const _SetupBackBar({this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed:
                disabled ? null : () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, size: 20),
            label: Text("Back"),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.forest,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  final String message;
  const _ErrorLine(this.message);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 16, color: AppColors.alert),
        SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: TextStyle(color: AppColors.alert, fontSize: 13)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.text = _generateCode();
  }

  /// Six characters, no ambiguous 0/O or 1/I, since people read these aloud.
  String _generateCode() {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final code = _code.text.trim().toUpperCase();

    if (name.isEmpty) {
      setState(() => _error = "Give your group a name.");
      return;
    }
    if (code.length < 4) {
      setState(() => _error = "Codes need at least 4 characters.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await FirebaseService.createGroup(name: name, code: code);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    GroupSession.setGroup(groupCode: code, groupName: name);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SetupBackBar(disabled: _busy),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text("Create a group",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text("Share the code with the people hiking with you.",
                      style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: 28),

                  LabeledField(
                    label: "Group name",
                    hint: "Abaca Hunters",
                    controller: _name,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  SizedBox(height: 20),

                  LabeledField(
                    label: "Group code",
                    hint: "ABCD12",
                    controller: _code,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: IconButton(
                      icon: Icon(Icons.refresh_rounded,
                          size: 20, color: AppColors.forest),
                      tooltip: "Generate a new code",
                      onPressed: () => setState(() {
                        _code.text = _generateCode();
                        _error = null;
                      }),
                    ),
                  ),

                  if (_error != null) ...[
                    SizedBox(height: 14),
                    _ErrorLine(_error!),
                  ],

                  SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Anyone with this code can see your position on "
                          "the trail while your hike is running.",
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
                label: _busy ? "Creating..." : "Create group",
                onPressed: _busy ? null : _create,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();

    if (code.length < 4) {
      setState(() => _error = "That code looks too short.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await FirebaseService.joinGroup(code);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    final name = await FirebaseService.groupName(code) ?? "Trail group";
    if (!mounted) return;

    GroupSession.setGroup(groupCode: code, groupName: name);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SetupBackBar(disabled: _busy),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text("Join a group",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    "Ask whoever made the group for the six-character code.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 28),

                  LabeledField(
                    label: "Group code",
                    hint: "ABCD12",
                    controller: _code,
                    onChanged: (_) => setState(() => _error = null),
                  ),

                  if (_error != null) ...[
                    SizedBox(height: 14),
                    _ErrorLine(_error!),
                  ],

                  SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.groups_outlined,
                          size: 16, color: AppColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Once you join, everyone in the group sees how far "
                          "apart you are while hiking.",
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
                label: _busy ? "Joining..." : "Join group",
                onPressed: _busy ? null : _join,
              ),
            ),
          ],
        ),
      ),
    );
  }
}











