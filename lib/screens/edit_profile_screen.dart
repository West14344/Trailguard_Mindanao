import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/mock_data.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: HikerProfile.fullName);
  late final _contactName =
      TextEditingController(text: HikerProfile.emergencyContact);
  late final _contactNumber =
      TextEditingController(text: HikerProfile.emergencyNumber);

  String? _photoPath = HikerProfile.photoPath;
  late String _level = HikerProfile.experienceLevel;
  bool _saving = false;

  static const _levels = [
    'Beginner Hiker',
    'Intermediate Hiker',
    'Advanced Hiker',
  ];

  @override
  void dispose() {
    _name.dispose();
    _contactName.dispose();
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
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.forest),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.forest),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.alert),
                title: const Text('Remove photo',
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
    setState(() => _saving = true);

    HikerProfile.fullName = _name.text.trim();
    HikerProfile.emergencyContact = _contactName.text.trim();
    HikerProfile.emergencyNumber = _contactNumber.text.trim();
    HikerProfile.experienceLevel = _level;
    HikerProfile.photoPath = _photoPath;

    try {
      await FirebaseService.saveProfile();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save changes. Check your connection.'),
          backgroundColor: AppColors.alert,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text('Edit profile',
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
                              child: const Icon(Icons.photo_camera_rounded,
                                  size: 17, color: Colors.white),
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
                      child: const Text('Change photo'),
                    ),
                  ),

                  const SizedBox(height: 20),
                  LabeledField(
                    label: 'Full name',
                    hint: 'Nukie Blaze',
                    controller: _name,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 18),

                  // Email is the login identity, so it is shown rather than
                  // editable here. Changing it needs re-authentication.
                  Text('Email',
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
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.inkSoft),
                    ),
                  ),

                  const SizedBox(height: 26),
                  const SectionLabel('Experience level'),
                  const SizedBox(height: 12),
                  for (final level in _levels) ...[
                    _LevelPick(
                      label: level,
                      selected: _level == level,
                      onTap: () => setState(() => _level = level),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 20),
                  const SectionLabel('Emergency contact'),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Name of contact person',
                    hint: 'Benhard Awanon',
                    controller: _contactName,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 18),
                  LabeledField(
                    label: 'Number of contact person',
                    hint: '+63 912 345 6789',
                    controller: _contactNumber,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: _saving ? 'Saving…' : 'Save changes',
                onPressed: _saving ? null : _save,
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
      decoration: const BoxDecoration(
        color: AppColors.pine,
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