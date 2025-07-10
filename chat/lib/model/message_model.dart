import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timeStamp;
  final List<String> readBys;
  final bool isFile;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timeStamp,
    required this.readBys,
    required this.isFile,
  });

  @override
  String toString() {
    return 'MessageModel(messageId: $messageId, senderId: $senderId, text: $text, '
        'timeStamp: $timeStamp, readBys: $readBys, isFile: $isFile)';
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timeStamp': timeStamp.toIso8601String(),
      'readBys': readBys,
      'isFile': isFile,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      timeStamp: json['timeStamp'] != null
          ? (json['timeStamp'] is String
          ? DateTime.parse(json['timeStamp'])
          : (json['timeStamp'] as Timestamp).toDate())
          : DateTime.now(),
      readBys: List<String>.from(json['readBys'] ?? []),
      isFile: json['isFile'],
    );
  }
}
