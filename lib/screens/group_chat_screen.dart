import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image/image.dart" as img;
import "package:image_picker/image_picker.dart";

import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";

/// Shrinks a photo twice: a thumbnail small enough to ride inside the
/// message document, and a full version kept in its own document.
///
/// Runs off the UI thread, because decoding a 12-megapixel phone photo
/// freezes the frame for about a second otherwise.
List<String>? _encodePhoto(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final bool wide = decoded.width >= decoded.height;

  img.Image full = decoded;
  if (decoded.width > 1000 || decoded.height > 1000) {
    full = img.copyResize(
      decoded,
      width: wide ? 1000 : null,
      height: wide ? null : 1000,
    );
  }

  List<int> fullJpg = img.encodeJpg(full, quality: 75);
  // A Firestore document stops at 1 MB and base64 adds a third, so keep
  // the encoded payload comfortably under that.
  if (fullJpg.length > 600 * 1024) {
    fullJpg = img.encodeJpg(
      img.copyResize(full, width: wide ? 720 : null, height: wide ? null : 720),
      quality: 60,
    );
  }

  final img.Image small = img.copyResize(
    decoded,
    width: wide ? 240 : null,
    height: wide ? null : 240,
  );

  return <String>[
    base64Encode(fullJpg),
    base64Encode(img.encodeJpg(small, quality: 55)),
  ];
}

class GroupChatScreen extends StatefulWidget {
  final String code;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.code,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    _input.clear();
    await FirebaseService.sendMessage(code: widget.code, text: text);
  }

  /// Photos only. Video would need Firebase Storage, which this project
  /// does not use.
  Future<void> _attachPhoto() async {
    if (_sending) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined,
                  color: AppColors.forest),
              title: const Text("Take a photo"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: AppColors.forest),
              title: const Text("Choose from gallery"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _sending = true);

    final Uint8List bytes = await picked.readAsBytes();
    final List<String>? pair = await compute(_encodePhoto, bytes);

    if (!mounted) return;

    if (pair == null) {
      setState(() => _sending = false);
      _complain("That file could not be read as a photo.");
      return;
    }

    final String? error = await FirebaseService.sendImageMessage(
      code: widget.code,
      fullBase64: pair[0],
      thumbBase64: pair[1],
      caption: _input.text.trim(),
    );

    if (!mounted) return;
    _input.clear();
    setState(() => _sending = false);
    if (error != null) _complain(error);
  }

  void _complain(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.alert,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPhoto(GroupMessage m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoViewer(code: widget.code, message: m),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? me = FirebaseService.uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back, size: 20),
                    label: Text("Back"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        widget.groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        "Code ${widget.code}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.line),

            Expanded(
              child: StreamBuilder<List<GroupMessage>>(
                stream: FirebaseService.messageStream(widget.code),
                builder: (BuildContext context,
                    AsyncSnapshot<List<GroupMessage>> snapshot) {
                  final List<GroupMessage> messages =
                      snapshot.data ?? const <GroupMessage>[];

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          snapshot.connectionState == ConnectionState.waiting
                              ? "Loading messages..."
                              : "No messages yet. Say where you are, or "
                                  "send a photo of the trail.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  }

                  // Newest at the bottom, and the view sticks there.
                  final List<GroupMessage> ordered =
                      messages.reversed.toList();

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: ordered.length,
                    itemBuilder: (BuildContext context, int i) {
                      final GroupMessage m = ordered[i];
                      return _Bubble(
                        message: m,
                        mine: m.senderId == me,
                        onOpenPhoto: () => _openPhoto(m),
                      );
                    },
                  );
                },
              ),
            ),

            if (_sending)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.forest),
                    ),
                    const SizedBox(width: 10),
                    Text("Sending photo...",
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _sending ? null : _attachPhoto,
                    icon: Icon(Icons.add_photo_alternate_outlined,
                        color: _sending ? AppColors.inkSoft : AppColors.forest),
                    tooltip: "Send a photo",
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Message your group",
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(color: AppColors.forest),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide:
                              BorderSide(color: AppColors.forest, width: 1.6),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.mist,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _send,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.arrow_upward_rounded,
                            size: 20, color: AppColors.forest),
                      ),
                    ),
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

class _Bubble extends StatelessWidget {
  final GroupMessage message;
  final bool mine;
  final VoidCallback onOpenPhoto;

  const _Bubble({
    required this.message,
    required this.mine,
    required this.onOpenPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = mine ? AppColors.forest : AppColors.card;
    final Color ink = mine ? Colors.white : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 3),
              child: Text(
                message.senderName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Material(
              color: background,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (message.isImage && message.thumbBase64 != null)
                    InkWell(
                      onTap: onOpenPhoto,
                      child: Image.memory(
                        base64Decode(message.thumbBase64!),
                        width: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 240,
                          height: 140,
                          color: AppColors.fill,
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.inkSoft),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        if (message.text.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              message.text,
                              style: TextStyle(
                                  color: ink, fontSize: 15, height: 1.35),
                            ),
                          ),
                        Text(
                          message.timeLabel,
                          style: TextStyle(
                            color: mine
                                ? Colors.white.withAlpha(190)
                                : AppColors.inkSoft,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-size photo, fetched only when somebody opens it.
class _PhotoViewer extends StatelessWidget {
  final String code;
  final GroupMessage message;

  const _PhotoViewer({required this.code, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          message.senderName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: FutureBuilder<String?>(
        future: FirebaseService.chatImage(code, message.imageId!),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final String? data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text(
                "That photo could not be loaded.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.memory(base64Decode(data)),
            ),
          );
        },
      ),
    );
  }
}
