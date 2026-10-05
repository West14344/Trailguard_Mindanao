import "dart:io";

import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";
import "change_password_screen.dart";

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: HikerProfile.fullName);
  late final _contactName =
      TextEditingController(text: HikerProfile.emergencyContact);
  late final _contactEmail =
      TextEditingController(text: HikerProfile.emergencyEmail);
  late final _contactNumber =
      TextEditingController(text: HikerProfile.emergencyNumber);

  String? _photoPath = HikerProfile.photoPath;
  late String _level = HikerProfile.experienceLevel;
  bool _saving = false;
  String? _error;

  static const _levels = [
    "Beginner Hiker",
    "Intermediate Hiker",
    "Advanced Hiker",
  ];

  /// Gmail specifically, since that is where an emergency alert goes.
  bool get _contactEmailValid {
    final e = _contactEmail.text.trim().toLowerCase();
    if (e.isEmpty) return true; // empty is allowed, invalid is not
    return RegExp(r"^[\w.+-]+@gmail\.com$").hasMatch(e);
  }

  bool get _canSave => !_saving && _contactEmailValid;

  @override
  void dispose() {
    _name.dispose();
    _contactName.dispose();
    _contactEmail.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file != null && mounted) setState(() => _photoPath = file.path);
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: AppColors.forest),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined,
                  color: AppColors.forest),
              title: const Text("Take a photo"),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.alert),
                title: Text("Remove photo",
                    style: TextStyle(color: AppColors.alert)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _photoPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_contactEmailValid) {
      setState(() =>
          _error = "The emergency contact must use a Gmail address.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    HikerProfile.fullName = _name.text.trim();
    HikerProfile.emergencyContact = _contactName.text.trim();
    HikerProfile.emergencyEmail = _contactEmail.text.trim().toLowerCase();
    HikerProfile.emergencyNumber = _contactNumber.text.trim();
    HikerProfile.experienceLevel = _level;
    HikerProfile.photoPath = _photoPath;

    try {
      await FirebaseService.saveProfile();
      await FirebaseService.syncNameToGroup();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "Could not save changes. Check your connection.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailTyped = _contactEmail.text.trim().isNotEmpty;

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
                  Text("Edit profile",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 26),

                  Center(
                    child: GestureDetector(
                      onTap: _choosePhotoSource,
                      child: Stack(
                        children: [
                          ProfileAvatar(photoPath: _photoPath, size: 116),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.paper, width: 3),
                              ),
                              child: Icon(Icons.photo_camera_rounded,
                                  size: 17, color: AppColors.onAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _choosePhotoSource,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.forest),
                      child: const Text("Change photo"),
                    ),
                  ),

                  const SizedBox(height: 20),
                  LabeledField(
                    label: "Full name",
                    hint: "Nukie Blaze",
                    controller: _name,
                    keyboardType: TextInputType.name,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 18),

                  // Email is the login identity, so it is shown rather than
                  // editable. Changing it needs re-authentication.
                  Text("Email",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: AppRadius.field,
                    ),
                    child: Text(
                      HikerProfile.email,
                      style:
                          TextStyle(fontSize: 15, color: AppColors.inkSoft),
                    ),
                  ),

                  const SizedBox(height: 14),
                  // Changing a password needs re-authentication, so it has
                  // its own screen rather than sitting inline here.
                  Material(
                    color: AppColors.card,
                    borderRadius: AppRadius.card,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      ),
                      borderRadius: AppRadius.card,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.card,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 20, color: AppColors.forest),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text("Change password",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 20, color: AppColors.inkSoft),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                  const SectionLabel("Experience level"),
                  const SizedBox(height: 12),
                  for (final level in _levels) ...[
                    _LevelPick(
                      label: level,
                      selected: _level == level,
                      onTap: () => setState(() => _level = level),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 22),
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
                  if (emailTyped && !_contactEmailValid) ...[
                    const SizedBox(height: 8),
                    _StatusLine(
                      icon: Icons.error_outline,
                      color: AppColors.blaze,
                      text: "Must be a Gmail address ending in @gmail.com",
                    ),
                  ] else if (emailTyped) ...[
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
              child: PrimaryButton(
                label: _saving ? "Saving..." : "Save changes",
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPick extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LevelPick({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mist : AppColors.card,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.forest : AppColors.line,
                size: 21,
              ),
            ],
          ),
        ),
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

/// Photo if one is set, initials otherwise. Shared with the profile screen.
class ProfileAvatar extends StatelessWidget {
  final String? photoPath;
  final double size;

  const ProfileAvatar({super.key, this.photoPath, this.size = 108});

  @override
  Widget build(BuildContext context) {
    final path = photoPath;

    final initials = Center(
      child: Text(
        HikerProfile.initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: AppColors.moss,
          letterSpacing: 1,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.heroFill,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? initials
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              // A picked file can vanish between sessions; fall back quietly.
              errorBuilder: (_, _, _) => initials,
            ),
    );
  }
}



