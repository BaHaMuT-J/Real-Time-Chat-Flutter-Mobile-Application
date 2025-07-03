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
          time: DateTime.now().subtract(const Duration(days: 1))),
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
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = chats[index];
          final lastMsg = chat.messages.isNotEmpty ? chat.messages.last : null;
          return ListTile(
            leading: CircleAvatar(child: Text(chat.name[0])),
            title: Text(chat.name),
            subtitle: Text(
              lastMsg?.text ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              lastMsg != null ? formatTime(lastMsg.time) : "",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () async {
              final updatedMessages = await Navigator.push<List<Message>>(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatName: chat.name,
                    initialMessages: List<Message>.from(chat.messages),
                  ),
                ),
              );

              if (updatedMessages != null) {
                _updateChatMessages(index, updatedMessages);
              }
            },
          );
        },
      ),
    );
  }
}
