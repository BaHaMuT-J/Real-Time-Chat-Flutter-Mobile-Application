import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> users;
  final String? lastMessage;
  final DateTime? lastMessageTimeStamp;
  final String? lastSender;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.chatId,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTimeStamp,
    required this.lastSender,
    required this.unreadCounts,
  });

  @override
  String toString() {
    return 'ChatModel(chatId: $chatId, users: $users, lastMessage: $lastMessage, '
        'lastMessageTimeStamp: $lastMessageTimeStamp, lastSender: $lastSender, '
        'unreadCounts: $unreadCounts)';
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTimeStamp': lastMessageTimeStamp,
      'lastSender': lastSender,
      'unreadCounts': unreadCounts,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json, String chatId) {
    return ChatModel(
      chatId: chatId,
      users: List<String>.from(json['users']),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimeStamp: (json['lastMessageTimeStamp'] as Timestamp?)?.toDate(),
      lastSender: json['lastSender'] as String?,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
    );
  }
}
