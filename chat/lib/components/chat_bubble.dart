import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isMe;
  final bool isGroup;
  final bool isRead;
  final int readByCount;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    required this.isGroup,
    required this.isRead,
    required this.readByCount,
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
                const SizedBox(width: 6),
                if (!isGroup)
                  Icon(
                    isRead ? Icons.check : null,
                    size: 14,
                    color: isRead ? Colors.blue : Colors.grey,
                  ),
                if (isGroup && readByCount > 0)
                  Text(
                    "$readByCount read",
                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
