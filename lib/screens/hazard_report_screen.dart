import "dart:io";

import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "../data/hike_records.dart";
import "../data/mock_data.dart";
import "../data/mountains.dart";
import "../services/firebase_service.dart";
import "../services/location_service.dart";
import "../theme/app_theme.dart";
import "../widgets/app_widgets.dart";

class HazardReportScreen extends StatefulWidget {
  /// Pre-selects the trail when opened from a trail page.
  final Trail? trail;
  const HazardReportScreen({super.key, this.trail});

  @override
  State<HazardReportScreen> createState() => _HazardReportScreenState();
}

class _HazardReportScreenState extends State<HazardReportScreen> {
  Trail? _mountain;
  int? _selectedType;
  String? _photoPath;
  bool _sending = false;
  String? _error;

  final _notes = TextEditingController();
  final _otherType = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _findingLocation = true;

  static const _types = [
    ["Fallen tree", Icons.park_outlined],
    ["Flooded trail", Icons.water_outlined],
    ["Wildfire", Icons.local_fire_department_outlined],
    ["Landslide", Icons.landslide_outlined],
    ["Blocked path", Icons.block_outlined],
    ["Damaged bridge", Icons.dangerous_outlined],
    ["Wildlife", Icons.pets_outlined],
    ["Missing trail sign", Icons.signpost_outlined],
    ["Other", Icons.more_horiz_rounded],
  ];

  int get _otherIndex => _types.length - 1;
  bool get _isOther => _selectedType == _otherIndex;
  bool get _hasPhoto => _photoPath != null;

  bool get _canSubmit {
    if (_sending) return false;
    if (_mountain == null) return false;
    if (_selectedType == null) return false;
    if (!_hasPhoto) return false;
    if (_isOther && _otherType.text.trim().isEmpty) return false;
    return true;
  }

  /// Names what is still missing, so a disabled button is never a mystery.
  String? get _blockingReason {
    if (_mountain == null) return "Choose which mountain this is on.";
    if (_selectedType == null) return "Choose what you saw to continue.";
    if (_isOther && _otherType.text.trim().isEmpty) {
      return "Describe the type of incident to continue.";
    }
    if (!_hasPhoto) {
      return "A photo is required. It shows other hikers how bad the "
          "hazard is.";
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill from the trail page, or from a hike in progress.
    _mountain = widget.trail ?? ActiveHike.trail;
    _findLocation();
  }

  @override
  void dispose() {
    _notes.dispose();
    _otherType.dispose();
    super.dispose();
  }

  Future<void> _findLocation() async {
    if (ActiveHike.latitude != null) {
      setState(() {
        _latitude = ActiveHike.latitude;
        _longitude = ActiveHike.longitude;
        _findingLocation = false;
      });
      return;
    }

    final position = await LocationService.currentPosition();
    if (!mounted) return;
    setState(() {
      _latitude = position?.latitude;
      _longitude = position?.longitude;
      _findingLocation = false;
    });
  }

  Future<void> _pickMountain() async {
    final chosen = await showModalBottomSheet<Trail>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _MountainPicker(),
    );

    if (chosen != null && mounted) {
      setState(() {
        _mountain = chosen;
        _error = null;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() {
        _photoPath = file.path;
        _error = null;
      });
    }
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
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined,
                  color: AppColors.forest),
              title: const Text("Take a photo"),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: AppColors.forest),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final mountain = _mountain!;
    final label = _isOther
        ? _otherType.text.trim()
        : _types[_selectedType!][0] as String;

    setState(() {
      _sending = true;
      _error = null;
    });

    // Fall back to the mountain's own coordinates when GPS is
    // unavailable, so the marker still lands on the right peak.
    final error = await FirebaseService.reportHazard(
      type: label,
      description: _notes.text.trim(),
      nearestTrail: mountain.name,
      latitude: _latitude ?? mountain.latitude,
      longitude: _longitude ?? mountain.longitude,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _sending = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label reported on ${mountain.name}."),
        backgroundColor: AppColors.pine,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocking = _blockingReason;
    final mountain = _mountain;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _sending
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
                  Text("Report a hazard",
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    "Other hikers heading to that mountain see your report "
                    "straight away.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 26),

                  Row(
                    children: [
                      const SectionLabel("Which mountain?"),
                      const SizedBox(width: 6),
                      const _RequiredTag(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MountainField(
                    mountain: mountain,
                    onTap: _sending ? null : _pickMountain,
                  ),

                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const SectionLabel("What did you see?"),
                      const SizedBox(width: 6),
                      const _RequiredTag(),
                    ],
                  ),
                  const SizedBox(height: 12),
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

                  if (_isOther) ...[
                    SizedBox(height: 18),
                    LabeledField(
                      label: "Type of incident",
                      hint: "e.g. Broken ladder section",
                      controller: _otherType,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  SizedBox(height: 26),
                  Row(
                    children: [
                      const SectionLabel("Photo"),
                      SizedBox(width: 6),
                      _RequiredTag(),
                      const Spacer(),
                      if (_hasPhoto)
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 15, color: AppColors.forest),
                            SizedBox(width: 4),
                            Text("Attached",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forest,
                                )),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _photoBox(),

                  SizedBox(height: 26),
                  LabeledField(
                    label: "Description",
                    hint: "Where on the trail, how bad, is it passable?",
                    controller: _notes,
                    maxLines: 4,
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

                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _latitude != null
                            ? Icons.place_rounded
                            : Icons.place_outlined,
                        size: 16,
                        color: _latitude != null
                            ? AppColors.forest
                            : AppColors.inkSoft,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _findingLocation
                              ? "Finding your location..."
                              : _latitude == null
                                  ? "GPS unavailable. The report will be "
                                      "pinned to the mountain instead."
                                  : "Your exact position will be attached: "
                                      "${_latitude!.toStringAsFixed(4)}, "
                                      "${_longitude!.toStringAsFixed(4)}",
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
              child: Column(
                children: [
                  if (blocking != null && !_sending) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 15, color: AppColors.inkSoft),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(blocking,
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: _sending ? "Sending..." : "Submit report",
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ],
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
                child:
                    const Center(child: Text("Could not load that image")),
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
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.blaze, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 34, color: AppColors.blaze),
            SizedBox(height: 10),
            Text("Photo required",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.blaze)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Take a photo of the hazard so other hikers can judge it "
                "for themselves.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
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
              SizedBox(height: 8),
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

/// The chosen mountain, or a prompt to choose one.
class _MountainField extends StatelessWidget {
  final Trail? mountain;
  final VoidCallback? onTap;

  const _MountainField({required this.mountain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chosen = mountain != null;

    return Material(
      color: chosen ? AppColors.card : AppColors.fill,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: chosen ? AppColors.forest : AppColors.blaze,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: chosen ? AppColors.mist : Colors.transparent,
                  borderRadius: AppRadius.field,
                ),
                child: Icon(
                  Icons.terrain_rounded,
                  size: 22,
                  color: chosen ? AppColors.forest : AppColors.blaze,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: chosen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mountain!.name,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 2),
                          Text(mountain!.region,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ],
                      )
                    : Text(
                        "Choose a mountain",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.blaze),
                      ),
              ),
              Icon(
                chosen ? Icons.edit_outlined : Icons.chevron_right_rounded,
                size: 20,
                color: chosen ? AppColors.inkSoft : AppColors.blaze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable list of all 60 destinations.
class _MountainPicker extends StatefulWidget {
  const _MountainPicker();

  @override
  State<_MountainPicker> createState() => _MountainPickerState();
}

class _MountainPickerState extends State<_MountainPicker> {
  final _search = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Trail> get _results {
    final q = _query.trim().toLowerCase();
    final list = kMountains.where((m) {
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.region.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: AppRadius.pill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Choose a mountain",
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(
                        fontSize: 15, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: "Search by name or province",
                      hintStyle: TextStyle(
                          color: AppColors.inkSoft, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 21, color: AppColors.inkSoft),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded,
                                  size: 19),
                              color: AppColors.inkSoft,
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = "");
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.paper,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.pill,
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.pill,
                        borderSide: BorderSide(
                            color: AppColors.forest, width: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text("No mountains match that search",
                          style: Theme.of(context).textTheme.titleMedium),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: AppColors.line),
                      itemBuilder: (context, i) {
                        final m = results[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: AppRadius.field,
                            ),
                            child: Icon(Icons.terrain_rounded,
                                size: 20, color: AppColors.forest),
                          ),
                          title: Text(m.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium),
                          subtitle: Text(m.region,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                          onTap: () => Navigator.pop(context, m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequiredTag extends StatelessWidget {
  const _RequiredTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x1AE3712B),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        "REQUIRED",
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.blaze,
        ),
      ),
    );
  }
}










