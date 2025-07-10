import 'package:flutter/material.dart';

const strongBlueColor = Color(0xFF003285);
const weakBlueColor = Color(0xFF578FCA);
const lightBlueColor = Color(0xFFA1E3F9);
const lightBlueGreenColor = Color(0xFFD1F8EF);

String formatTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays == 0) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  } else {
    return "${time.month}/${time.day}";
  }
}

class AppStateNotifier extends ValueNotifier<bool> {
  AppStateNotifier() : super(false);

  void refresh() {
    value = !value; // toggle to notify listeners
  }
}

final appStateNotifier = AppStateNotifier();

class Chat {
  final String name;
  final List<Message> messages;

  Chat({required this.name, required this.messages});
}

class Message {
  final String text;
  final bool isMe;
  final DateTime time;
  bool isRead;

  Message({
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
  });
}
