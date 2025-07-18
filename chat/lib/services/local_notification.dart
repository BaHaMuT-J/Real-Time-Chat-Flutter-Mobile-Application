import 'dart:convert';

import 'package:chat/constant.dart';
import 'package:chat/main.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/user_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final UserFirestoreService _userFirestoreService = UserFirestoreService();
  static final ChatFirestoreService _chatFirestoreService = ChatFirestoreService();

  static final Map<String, String?> userNameCache = {};

  static void initialize() {
    const InitializationSettings initializationSettingsAndroid = InitializationSettings(android: AndroidInitializationSettings("@drawable/ic_launcher"));
    _notificationsPlugin.initialize(
      initializationSettingsAndroid,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('📲 Local notification tapped. Payload: ${details.payload}');

        final data = details.payload != null ? jsonDecode(details.payload!) : null;
        debugPrint('data: $data');

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => InitialPage(payload: data)),
              (route) => false,
        );
      },
    );
  }

  static Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'fcm_default_channel',
        'Firebase Notifications',
        channelDescription: 'Notifications from FCM and local',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> showNotificationFromSocket(data) async {
    final newMessage = MessageModel.fromJson(jsonDecode(data['message']));
    final messageChatId = data['chatId'];
    final ChatModel? chat = await _chatFirestoreService.getChatById(messageChatId);
    if (chat == null) return;

    String? friendName = userNameCache[newMessage.senderId];
    if (friendName == null) {
      final friend = await _userFirestoreService.getUser(newMessage.senderId);
      friendName = friend?.username;
    }

    final notificationTitle = chat.isGroup ? chat.chatName : friendName;
    final notificationBody = friendName != null ? '$friendName send a new message From Chat list' : 'New message';
    LocalNotificationService.showCustomNotification(
      title: notificationTitle!,
      body: notificationBody,
      payload: jsonEncode(data),
    );
  }

}