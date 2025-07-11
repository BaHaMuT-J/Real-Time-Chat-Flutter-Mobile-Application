import 'package:chat/components/chat_bubble.dart';
import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/socket.dart';
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
  final socketService = SocketService();

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

    registerSocket();
  }

  @override
  void dispose() {
    unregisterSocket();
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

  void registerSocket() async {
    debugPrint('Register currentUid: $currentUid');
    socketService.emit("register", { "userId": currentUid });
    socketService.on("message", _listenToMessage);
  }

  void unregisterSocket() async {
    debugPrint('Unregister currentUid: $currentUid');
    socketService.emit("unregister", { "userId": currentUid });
    socketService.off("message", _listenToMessage);
  }

  void _listenToMessage(data) async {
    debugPrint('socket message in $currentUid: $data');
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

    MessageModel message = await _chatFirestoreService.sendMessage(widget.chat.chatId, text);
    for (String uid in widget.chat.users) {
      if (uid == currentUid) continue;
      socketService.emit("message", {
        'userId': uid,
        'message': message,
      });
      debugPrint('Sent message to socket with uid $uid');
    }

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

                  // For group: calculate how many OTHER users have read
                  int readByCount = 0;
                  if (isMe && widget.chat.isGroup) {
                    readByCount = msg.readBys.length;
                    if (msg.readBys.contains(currentUid)) {
                      readByCount -= 1; // exclude self
                    }
                  }

                  // For private: check if OTHER user have read
                  bool isOtherRead = false;
                  if (isMe && !widget.chat.isGroup) {
                    isOtherRead = msg.readBys.length > 1;
                  }

                  // Avatar + username
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
                              isGroup: widget.chat.isGroup,
                              isRead: isOtherRead,
                              readByCount: readByCount,
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
