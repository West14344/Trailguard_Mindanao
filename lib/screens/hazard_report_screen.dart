import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HazardReportScreen extends StatefulWidget {
  const HazardReportScreen({super.key});

  @override
  State<HazardReportScreen> createState() => _HazardReportScreenState();
}

class _HazardReportScreenState extends State<HazardReportScreen> {
  int? _selectedType;
  String? _photoPath;
  final _notes = TextEditingController();
  final _otherType = TextEditingController();

  /// Nine types. "Other" sits last and unlocks a free-text field, so the
  /// list stays scannable without excluding anything a hiker might see.
  static const _types = [
    ['Fallen tree', Icons.park_outlined],
    ['Flooded trail', Icons.water_outlined],
    ['Wildfire', Icons.local_fire_department_outlined],
    ['Landslide', Icons.landslide_outlined],
    ['Blocked path', Icons.block_outlined],
    ['Damaged bridge', Icons.dangerous_outlined],
    ['Wildlife', Icons.pets_outlined],
    ['Missing trail sign', Icons.signpost_outlined],
    ['Other', Icons.more_horiz_rounded],
  ];

  int get _otherIndex => _types.length - 1;
  bool get _isOther => _selectedType == _otherIndex;

  bool get _canSubmit {
    if (_selectedType == null) return false;
    if (_isOther && _otherType.text.trim().isEmpty) return false;
    return true;
  }

  @override
  void dispose() {
    _notes.dispose();
    _otherType.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
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
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.forest),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.forest),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
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

  void _submit() {
    final label = _isOther
        ? _otherType.text.trim()
        : _types[_selectedType!][0] as String;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label reported. Nearby hikers have been notified.'),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text('Report a hazard',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Other hikers on this trail see your report straight away.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 26),

                  const SectionLabel('What did you see?'),
                  const SizedBox(height: 12),

                  // Three columns keeps nine tiles compact without shrinking
                  // the tap targets below a comfortable size.
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _types.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, i) => _typeTile(i),
                  ),

                  // Free-text type, shown only when it is relevant.
                  if (_isOther) ...[
                    const SizedBox(height: 18),
                    LabeledField(
                      label: 'Type of incident',
                      hint: 'e.g. Broken ladder section',
                      controller: _otherType,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 26),
                  const SectionLabel('Photo'),
                  const SizedBox(height: 12),
                  _photoBox(),

                  const SizedBox(height: 26),
                  LabeledField(
                    label: 'Description',
                    hint: 'Where on the trail, how bad, is it passable?',
                    controller: _notes,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 16, color: AppColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your current location is attached automatically.',
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
                label: 'Submit report',
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoBox() {
    final path = _photoPath;

    if (path != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.card,
            child: Image.file(
              File(path),
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 190,
                color: AppColors.fill,
                child: const Center(
                  child: Text('Could not load that image'),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _choosePhotoSource,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit_outlined,
                      size: 19, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _choosePhotoSource,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                size: 34, color: AppColors.inkSoft),
            const SizedBox(height: 10),
            Text('Add a photo',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text('Camera or gallery',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _typeTile(int index) {
    final selected = _selectedType == index;
    final label = _types[index][0] as String;
    final icon = _types[index][1] as IconData;

    return Material(
      color: selected ? const Color(0x14E3712B) : AppColors.card,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: () => setState(() => _selectedType = index),
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.blaze : AppColors.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 25,
                  color: selected ? AppColors.blaze : AppColors.inkSoft),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.blaze : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}