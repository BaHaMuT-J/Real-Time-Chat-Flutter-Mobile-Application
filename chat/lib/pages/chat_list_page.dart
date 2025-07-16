import 'package:chat/components/profile_avatar.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:chat/constant.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/firebase_message.dart';
import 'package:chat/services/socket.dart';
import 'package:chat/services/user_firestore.dart';
import 'package:chat/userPref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  final ChatFirestoreService _chatFirestoreService = ChatFirestoreService();
  String get currentUid => _auth.currentUser!.uid;
  final socketService = SocketService();

  List<ChatModel>? allChats;
  final Map<String, UserModel?> friendCache = {};

  @override
  void initState() {
    super.initState();
    appStateNotifier.addListener(_onAppStateChanged);
    startApp();
    registerSocket(socketService, currentUid);
    socketService.on("message", _listenToMessage);
  }

  @override
  void dispose() {
    // When dispose after logout, this will have error
    try {
      unregisterSocket(socketService, currentUid);
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

  // data = {
  //         'userId': uid,
  //         'chatId': widget.chat.chatId,
  //         'message': message,
  //       }
  void _listenToMessage(data) async {
    try {
      debugPrint('Chat list socket message in $currentUid: $data');
      final chatId = data['chatId'] as String;
      final message = MessageModel.fromJson(data['message']);
      setState(() {
        final chatIndex = allChats?.indexWhere((chat) => chat.chatId == chatId);
        if (chatIndex != null && chatIndex >= 0) {
          // Update the existing chat
          final chat = allChats![chatIndex];

          chat.lastMessage = message.text;
          chat.lastMessageTimeStamp = message.timeStamp;

          // Increase unread count for this user
          chat.unreadCounts[currentUid] = (chat.unreadCounts[currentUid] ?? 0) + 1;

          // Move this chat to the top
          allChats!.removeAt(chatIndex);
          allChats!.insert(0, chat);
        } else {
          debugPrint('Chat not found in list, optionally reload chats');
          // _loadChats();
        }
      });
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
      final chatUsers = await _chatFirestoreService.getChats(isPreferPref: isPreferPref);
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
      await _auth.signOut();
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
                future: _userFirestoreService.getUser(friendUid),
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
        socketService.off("message", _listenToMessage);        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatPage(chat: chat, chatName: name, chatImage: imageUrl,),
        )).then((value) {
          _loadChats();
          socketService.on("message", _listenToMessage);        });
      },
    );
  }
}
