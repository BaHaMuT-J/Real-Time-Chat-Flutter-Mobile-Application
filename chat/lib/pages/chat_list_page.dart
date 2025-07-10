import 'package:chat/model/chat_model.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:chat/constant.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/services/chat_firestore.dart';
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
  final ChatFirestoreService _chatFirestoreService = ChatFirestoreService();

  List<ChatModel>? allChats;

  List<Chat> chats = [
    Chat(name: "Family Group", messages: [
      Message(
          text: "Hi family!",
          isMe: true,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: true),
      Message(
          text: "Hello!",
          isMe: false,
          time: DateTime.now().subtract(const Duration(minutes: 4))),
    ]),
    Chat(name: "Best Friend", messages: [
      Message(
          text: "Yo! Want to game later?",
          isMe: true,
          time: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true),
      Message(
          text: "Definitely!",
          isMe: false,
          time: DateTime.now().subtract(const Duration(minutes: 50))),
    ]),
    Chat(name: "Work Team", messages: [
      Message(
          text: "Meeting at 10?",
          isMe: false,
          time: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true),
      Message(
          text: "Yes, noted.",
          isMe: true,
          time: DateTime.now().subtract(const Duration(days: 1, minutes: -10)),
          isRead: false),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    appStateNotifier.addListener(_onAppStateChanged);
    startApp();
  }

  @override
  void dispose() {
    appStateNotifier.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    debugPrint('On app state changed from chat list page');
    startApp();
  }

  void startApp() {
    debugPrint('Start app from chat list page');
    Future.wait([
      _loadChats(),
    ]).then((_) {
      UserPrefs.saveIsLoad(true);
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

  void _updateChatMessages(int chatIndex, List<Message> updatedMessages) {
    setState(() {
      chats[chatIndex].messages
        ..clear()
        ..addAll(updatedMessages);
    });
  }

  Future<void> _handleLogOut() async {
    try {
      await _auth.signOut();
      await UserPrefs.logout();
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
        title: Row(
          children: [
            const Text(
              "Chat",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: strongBlueColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: strongBlueColor),
            onPressed: _handleLogOut,
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(
          thickness: 2,
          color: strongBlueColor,
        ),
        itemBuilder: (context, index) {
          final chat = chats[index];
          final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;
          final unreadCount = chat.messages
              .where((msg) => !msg.isMe && !msg.isRead)
              .length;
          return ListTile(
            leading: CircleAvatar(child: Text(chat.name[0])),
            title: Text(
              chat.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            subtitle: Text(
              lastMsg?.text ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMsg != null ? formatTime(lastMsg.time) : "",
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
              // final updatedMessages = await Navigator.push<List<Message>>(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => ChatPage(
              //       chatName: chat.name,
              //       initialMessages: List<Message>.from(chat.messages),
              //     ),
              //   ),
              // );

              // Mock read/unread messages
              final updatedMessages = await Navigator.push<List<Message>>(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatName: chat.name,
                    initialMessages: List.generate(30, (index) {
                      return Message(
                        text: index < 20
                            ? "Read message #$index"
                            : "Unread message #$index",
                        isMe: index < 20,
                        time: DateTime.now().subtract(Duration(minutes: (30 - index) * 5)),
                        isRead: index < 20,
                      );
                    }),
                  ),
                ),
              );

              debugPrint("Update Msg");
              debugPrint(updatedMessages.toString());

              if (updatedMessages != null) {
                _updateChatMessages(index, updatedMessages);
                setState(() {
                  for (var msg in chats[index].messages) {
                    if (!msg.isMe) msg.isRead = true;
                  }
                });
              }

            },
          );
        },
      ),
    );
  }
}
