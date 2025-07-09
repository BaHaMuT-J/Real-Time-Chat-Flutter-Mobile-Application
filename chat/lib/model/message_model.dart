class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timeStamp;
  final List<String> readBys;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timeStamp,
    required this.readBys,
  });

  @override
  String toString() {
    return 'MessageModel(messageId: $messageId, senderId: $senderId, text: $text, '
        'timeStamp: $timeStamp, readBys: $readBys)';
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timeStamp': timeStamp,
      'readBys': readBys,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      timeStamp: json['timeStamp'] as DateTime,
      readBys: List<String>.from(json['readBys']),
    );
  }
}
