import 'package:chat/chat_page.dart';
import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  void _updateChatMessages(int chatIndex, List<Message> updatedMessages) {
    setState(() {
      chats[chatIndex].messages
        ..clear()
        ..addAll(updatedMessages);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueGreenColor,
      appBar: AppBar(
        backgroundColor: lightBlueColor,
        title: Row(
          children: [
            const Icon(Icons.chat),
            const SizedBox(width: 12),
            const Text(
              "Item Tracker",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: strongBlueColor,
              ),
            ),
          ],
        ),
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
