import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final ChatModel chat;
  final String? chatName;
  final String? chatImage;

  const ChatPage({
    super.key,
    required this.chat,
    this.chatName,
    this.chatImage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  final ChatFirestoreService _chatFirestoreService = ChatFirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String get currentUid => _auth.currentUser!.uid;

  late List<MessageModel> messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, String?> userImageCache = {};
  final Map<String, String?> userNameCache = {};
  bool isLoadingUsers = false;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    messages = [];

    _controller.addListener(() {
      setState(() {});
    });

    appStateNotifier.addListener(_onAppStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMessages();
      await _chatFirestoreService.markAsRead(widget.chat.chatId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    appStateNotifier.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() async {
    debugPrint('On app state changed from chat page');
    await _loadMessages();
    await _chatFirestoreService.markAsRead(widget.chat.chatId);
  }

  Future<void> _loadMessages() async {
    final fetchedMessages = await _chatFirestoreService.getMessages(widget.chat.chatId);

    if (widget.chat.isGroup) {
      setState(() {
        isLoadingUsers = true;
      });

      final uniqueUserIds = fetchedMessages.map((m) => m.senderId).toSet();
      final futures = uniqueUserIds.map((uid) async {
        final user = await _userFirestoreService.getUser(uid);
        userImageCache[uid] = user?.profileImageUrl;
        userNameCache[uid] = user?.username;
      });

      await Future.wait(futures);

      setState(() {
        isLoadingUsers = false;
      });
    }

    setState(() {
      messages = fetchedMessages;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstUnread();
    });
  }

  void _scrollToFirstUnread() {
    final index = messages.indexWhere((msg) => !msg.readBys.contains(currentUid));

    if (index != -1 && _scrollController.hasClients) {
      double offset = index * 80.0;
      offset = (offset - 50).clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    await _chatFirestoreService.sendMessage(widget.chat.chatId, text);

    setState(() {
      _controller.clear();
      isSending = false;
    });

    await _loadMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueGreenColor,
      appBar: AppBar(
        backgroundColor: lightBlueColor,
        title: Text(
          widget.chat.chatName ?? (widget.chatName ?? "Chat"),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: strongBlueColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  final isMe = msg.senderId == currentUid;
                  final isFirstUnread = (!msg.readBys.contains(currentUid) &&
                      (index == 0 || messages[index - 1].readBys.contains(currentUid)));

                  // Decide avatar + username
                  String? avatarUrl;
                  String? userName;
                  if (!isMe) {
                    if (widget.chat.isGroup) {
                      avatarUrl = userImageCache[msg.senderId];
                      userName = userNameCache[msg.senderId] ?? "Unknown";
                    } else {
                      avatarUrl = widget.chatImage;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isFirstUnread)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: const [
                              Expanded(child: Divider()),
                              SizedBox(width: 8),
                              Text(
                                "New Messages",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  ProfileAvatar(imagePath: avatarUrl ?? ""),
                                  if (widget.chat.isGroup && userName != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ChatBubble(
                              text: msg.text,
                              time: msg.timeStamp,
                              isMe: isMe,
                              isRead: msg.readBys.contains(currentUid),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: lightBlueColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: const TextStyle(
                          color: strongBlueColor,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_controller.text.trim().isEmpty || isSending) ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      foregroundColor: Colors.blue,
                    ),
                    child: isSending
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
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

class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isMe;
  final bool isRead;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Colors.blueAccent : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;
    final radius = isMe
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(0),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(0),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
            ),
            child: Text(
              text,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatTime(time),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  isRead ? Icons.check : null,
                  size: 14,
                  color: isRead ? Colors.blue : Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
