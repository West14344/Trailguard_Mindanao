import "package:flutter/material.dart";
import "../data/mock_data.dart";
import "../services/firebase_service.dart";
import "../theme/app_theme.dart";

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
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _input.clear();

    await FirebaseService.sendMessage(code: widget.code, text: text);
    if (!mounted) return;
    setState(() => _sending = false);

    // Drop to the newest message once it lands.
    await Future.delayed(const Duration(milliseconds: 250));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
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
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
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
                    children: [
                      Text(widget.groupName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text("Code ${widget.code}",
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: AppColors.line),

            Expanded(
              child: StreamBuilder<List<GroupMessage>>(
                stream: FirebaseService.messageStream(widget.code),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child:
                          CircularProgressIndicator(color: AppColors.forest),
                    );
                  }

                  final messages = snapshot.data ?? const <GroupMessage>[];
                  if (messages.isEmpty) return const _NoMessages();

                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final mine = m.senderId == FirebaseService.uid;
                      // Only label the sender when it changes.
                      final showSender = !mine &&
                          (i == 0 ||
                              messages[i - 1].senderId != m.senderId);

                      return _MessageBubble(
                        message: m,
                        isMine: mine,
                        showSender: showSender,
                      );
                    },
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                          fontSize: 15, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: "Message your group",
                        hintStyle: TextStyle(
                            color: AppColors.inkSoft, fontSize: 15),
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
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
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: FilledButton(
                      onPressed:
                          _input.text.trim().isEmpty || _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        disabledBackgroundColor: AppColors.fill,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 21,
                        color: _input.text.trim().isEmpty
                            ? AppColors.inkSoft
                            : Colors.white,
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

class _NoMessages extends StatelessWidget {
  const _NoMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.forum_outlined,
                  size: 38, color: AppColors.forest),
            ),
            const SizedBox(height: 20),
            Text("No messages yet",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "Say where you are, or flag something the group should know "
              "about on the trail.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMine;
  final bool showSender;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSender,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: showSender ? 12 : 4),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(message.senderName,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.74,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.forest : AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMine ? AppColors.forest : AppColors.line,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: isMine ? Colors.white : AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        message.timeLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isMine
                              ? const Color(0xB3FFFFFF)
                              : AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}











