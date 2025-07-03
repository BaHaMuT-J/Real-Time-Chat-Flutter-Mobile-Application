class Chat {
  final String name;
  final List<Message> messages;

  Chat({required this.name, required this.messages});
}

class Message {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isRead;

  Message({
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
  });
}

String formatTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays == 0) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  } else {
    return "${time.month}/${time.day}";
  }
}
