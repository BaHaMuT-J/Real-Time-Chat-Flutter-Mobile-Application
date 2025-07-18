import 'dart:convert';

import 'package:chat/components/profile_avatar.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:chat/constant.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/services/firebase_message.dart';
import 'package:chat/services/local_notification.dart';
import 'package:chat/userPref.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key, this.payload});

  final dynamic payload;

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<ChatModel>? allChats;
  final Map<String, UserModel?> friendCache = {};

  @override
  void initState() {
    super.initState();
    appStateNotifier.addListener(_onAppStateChanged);
    startApp();
    socketService.on("message", _listenToMessage);

    // Navigate to Chat page when user tap notification
    if (widget.payload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final chat = ChatModel.fromJson(jsonDecode(widget.payload['chat']));
          final name = widget.payload['chatName'];
          pushToChatPage(chat, name);
        } catch (e) {
          debugPrint('Error parsing payload and navigating: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('Dispose from Chat list page');
    // When dispose after logout, this will have error
    try {
      socketService.off("message", _listenToMessage);
    } catch (e) {
      debugPrint('Unregister socket error from Chat list page: $e');
    }
    appStateNotifier.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    debugPrint('On app state changed from Chat list page');
    startApp();
  }

  void _listenToMessage(data) async {
    try {
      debugPrint('Chat list socket message in $currentUid: $data');
      final chatId = data['chatId'] as String;
      final message = MessageModel.fromJson(jsonDecode(data['message']));
      final chatIndex = allChats?.indexWhere((chat) => chat.chatId == chatId);
      if (chatIndex != null && chatIndex >= 0) {
        final chat = allChats![chatIndex];
        setState(() {
          // Update chat
          chat.lastMessage = message.text;
          chat.lastMessageTimeStamp = message.timeStamp;
          chat.unreadCounts[currentUid] = (chat.unreadCounts[currentUid] ?? 0) + 1;

          // Move this chat to the top
          allChats!.removeAt(chatIndex);
          allChats!.insert(0, chat);
        });
        UserPrefs.saveChats(allChats!);
      } else {
        debugPrint('Chat not found in list');
      }
      LocalNotificationService.showNotificationFromSocket(data);
    } catch (e) {
      debugPrint('Error handling incoming socket message: $e');
    }
  }

  void startApp() {
    debugPrint('Start app from chat list page');
    Future.wait([
      _loadChats(),
    ]).then((_) {
      UserPrefs.saveIsLoadChat(true);
    });
  }

  Future<void> _loadChats({bool isPreferPref = true}) async {
    try {
      final chatUsers = await chatFirestoreService.getChats(isPreferPref: isPreferPref);
      setState(() {
        allChats = chatUsers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
      }
    }
  }

  Future<void> _handleLogOut() async {
    try {
      String uid = currentUid;
      socketService.disconnect();
      await auth.signOut();
      await UserPrefs.logout();
      await FirebaseMessagingService.dispose(uid: uid);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout success')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  void pushToChatPage(ChatModel chat, String name) {
    socketService.off("message", _listenToMessage);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatPage(chat: chat, chatName: name),
    )).then((value) {
      _loadChats();
      socketService.on("message", _listenToMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueGreenColor,
      appBar: AppBar(
        backgroundColor: lightBlueColor,
        title: const Text("Chat", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: strongBlueColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: strongBlueColor),
            onPressed: _handleLogOut,
          ),
        ],
      ),
      body: allChats == null
          ? const Center(child: CircularProgressIndicator())
          : allChats!.isEmpty
          ? const Center(child: Text("You have no chats"))
          : ListView.separated(
        itemCount: allChats!.length,
        separatorBuilder: (_, __) => const Divider(
          thickness: 2,
          color: strongBlueColor,
        ),
        itemBuilder: (context, index) {
          final chat = allChats![index];
          final unreadCount = chat.unreadCounts[currentUid] ?? 0;

          if (chat.isGroup) {
            // GROUP CHAT: show group name & image
            return _buildChatTile(
              chat: chat,
              chatId: chat.chatId,
              name: chat.chatName ?? "Unnamed Group",
              imageUrl: chat.chatImageUrl ?? "",
              lastMessage: chat.lastMessage,
              lastMessageTimeStamp: chat.lastMessageTimeStamp,
              unreadCount: unreadCount,
            );
          } else {
            // PRIVATE CHAT: load friend info
            final friendUid = chat.users.firstWhere((u) => u != currentUid);
            UserModel? friend = friendCache[friendUid];
            if (friend != null) {
              return _buildChatTile(
                chat: chat,
                chatId: chat.chatId,
                name: friend.username,
                imageUrl: friend.profileImageUrl,
                lastMessage: chat.lastMessage,
                lastMessageTimeStamp: chat.lastMessageTimeStamp,
                unreadCount: unreadCount,
              );
            } else {
              return FutureBuilder<UserModel?>(
                future: userFirestoreService.getUser(friendUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text("Loading..."));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const ListTile(title: Text("Unknown User"));
                  }

                  final friend = snapshot.data!;
                  friendCache[friendUid] = friend;

                  return _buildChatTile(
                    chat: chat,
                    chatId: chat.chatId,
                    name: friend.username,
                    imageUrl: friend.profileImageUrl,
                    lastMessage: chat.lastMessage,
                    lastMessageTimeStamp: chat.lastMessageTimeStamp,
                    unreadCount: unreadCount,
                  );
                },
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String chatId,
    required String name,
    required String imageUrl,
    String? lastMessage,
    DateTime? lastMessageTimeStamp,
    required int unreadCount,
  }) {
    return ListTile(
      leading: ProfileAvatar(imagePath: imageUrl),
      title: Text(
        name,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      ),
      subtitle: Text(
        lastMessage ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            lastMessageTimeStamp != null ? formatTime(lastMessageTimeStamp) : "",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () async {
        pushToChatPage(chat, name);
      },
    );
  }
}
