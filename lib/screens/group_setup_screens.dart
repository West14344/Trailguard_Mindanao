import 'dart:math';

import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

/// Shared header so both setup screens match the rest of the app.
class _SetupBackBar extends StatelessWidget {
  const _SetupBackBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        const Icon(Icons.error_outline, size: 16, color: AppColors.alert),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.alert, fontSize: 13),
          ),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.text = _generateCode();
  }

  /// Six characters, no ambiguous 0/O or 1/I, since people read these aloud.
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    String code;
    do {
      code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    } while (GroupRegistry.exists(code));
    return code;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim();
    final code = _code.text.trim().toUpperCase();

    if (name.isEmpty) {
      setState(() => _error = 'Give your group a name.');
      return;
    }
    if (code.length < 4) {
      setState(() => _error = 'Codes need at least 4 characters.');
      return;
    }
    if (GroupRegistry.exists(code)) {
      setState(() => _error = 'That code is already taken. Generate another.');
      return;
    }

    final group = GroupRegistry.create(name: name, code: code);
    GroupSession.setGroup(group);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _SetupBackBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text('Create a group',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Share the code with the people hiking with you.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),

                  LabeledField(
                    label: 'Group name',
                    hint: 'Abaca Hunters',
                    controller: _name,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 20),

                  LabeledField(
                    label: 'Group code',
                    hint: 'ABCD12',
                    controller: _code,
                    onChanged: (_) => setState(() => _error = null),
                    suffix: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          size: 20, color: AppColors.forest),
                      tooltip: 'Generate a new code',
                      onPressed: () => setState(() {
                        _code.text = _generateCode();
                        _error = null;
                      }),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorLine(_error!),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anyone with this code can see your position on the '
                          'trail while the hike is active.',
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
              child: PrimaryButton(label: 'Create group', onPressed: _create),
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
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    final code = _code.text.trim().toUpperCase();

    if (code.length < 4) {
      setState(() => _error = 'That code looks too short.');
      return;
    }

    final group = GroupRegistry.join(code);
    if (group == null) {
      setState(() => _error =
          'No group found with that code. Check it with whoever created it.');
      return;
    }

    GroupSession.setGroup(group);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _SetupBackBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text('Join a group',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Ask whoever made the group for the six-character code.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),

                  LabeledField(
                    label: 'Group code',
                    hint: 'ABCD12',
                    controller: _code,
                    onChanged: (_) => setState(() => _error = null),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorLine(_error!),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Groups are stored on this device only. Joining from '
                          'another phone needs a server connection.',
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
              child: PrimaryButton(label: 'Join group', onPressed: _join),
            ),
          ],
        ),
      ),
    );
  }
}