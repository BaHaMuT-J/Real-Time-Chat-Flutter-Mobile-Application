import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> users;
  String? lastMessage;
  DateTime? lastMessageTimeStamp;
  Map<String, int> unreadCounts;
  final bool isGroup;
  final String? chatName;
  final String? chatImageUrl;

  ChatModel({
    required this.chatId,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTimeStamp,
    required this.unreadCounts,
    required this.isGroup,
    required this.chatName,
    required this.chatImageUrl,
  });

  @override
  String toString() {
    return 'ChatModel(chatId: $chatId, users: $users, lastMessage: $lastMessage, '
        'lastMessageTimeStamp: $lastMessageTimeStamp,'
        'unreadCounts: $unreadCounts, isGroup: $isGroup, '
        'chatName: $chatName, chatImageUrl: $chatImageUrl)';
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTimeStamp': lastMessageTimeStamp?.toIso8601String(),
      'unreadCounts': unreadCounts,
      'isGroup': isGroup,
      'chatName': chatName,
      'chatImageUrl': chatImageUrl,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'],
      users: List<String>.from(json['users']),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimeStamp: json['lastMessageTimeStamp'] != null
          ? (json['lastMessageTimeStamp'] is String
          ? DateTime.parse(json['lastMessageTimeStamp'])
          : (json['lastMessageTimeStamp'] as Timestamp).toDate())
          : null,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      isGroup: json['isGroup'] as bool? ?? false,
      chatName: json['chatName'] as String?,
      chatImageUrl: json['chatImageUrl'] as String?,
    );
  }
}
