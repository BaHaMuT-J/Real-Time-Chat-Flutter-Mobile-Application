import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatName;
  final List<Message> initialMessages;

  const ChatPage({
    Key? key,
    required this.chatName,
    required this.initialMessages,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late List<Message> messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    messages = widget.initialMessages;
    _controller.addListener(() {
      setState(() {}); // Update send button enabled state
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final newMsg = Message(
      text: text,
      isMe: true,
      time: DateTime.now(),
      isRead: false,
    );

    setState(() {
      messages.add(newMsg);
      _controller.clear();
    });

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
      appBar: AppBar(title: Text(widget.chatName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(message: msg);
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
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
                    onPressed:
                    _controller.text.trim().isEmpty ? null : _sendMessage,
                    child: const Icon(Icons.send),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      foregroundColor: Colors.blue
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Chat bubble widget
class ChatBubble extends StatelessWidget {
  final Message message;
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final align =
    message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isMe ? Colors.blueAccent : Colors.grey[300];
    final textColor = message.isMe ? Colors.white : Colors.black87;
    final radius = message.isMe
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
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatTime(message.time),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (message.isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.check,
                  size: 14,
                  color: message.isRead ? Colors.blue : Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
