import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const strongBlueColor = Color(0xFF003285);
const weakBlueColor = Color(0xFF578FCA);
const lightBlueColor = Color(0xFFA1E3F9);
const lightBlueGreenColor = Color(0xFFD1F8EF);

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

class UserModel {
  final String uid;
  final String username;
  final String description;
  final String profileImageUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.description,
    required this.profileImageUrl,
  });

  @override
  String toString() {
    return 'UserModel(uid: $uid,username: $username, description: $description, profileImageUrl: $profileImageUrl)';
  }

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      username: data['username'],
      description: data['description'] ?? "No description yet.",
      profileImageUrl: data['profileImageUrl'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'description': description,
      'profileImageUrl': profileImageUrl,
    };
  }
}

String formatTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays == 0) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  } else {
    return "${time.month}/${time.day}";
  }
}
