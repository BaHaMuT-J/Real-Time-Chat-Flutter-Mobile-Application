import 'dart:convert';

import 'package:chat/constant.dart';
import 'package:chat/main.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettingsAndroid = InitializationSettings(android: AndroidInitializationSettings("@drawable/ic_launcher"));
    _notificationsPlugin.initialize(
      initializationSettingsAndroid,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('📲 Local notification tapped. Payload: ${details.payload}');

        // If you store JSON here, you can decode it and handle specific navigation.
        final data = details.payload != null ? jsonDecode(details.payload!) : null;
        debugPrint('data: $data');

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const InitialPage()),
              (route) => false,
        );

        if (data != null) {
          final message = MessageModel.fromJson(jsonDecode(data['message']));
          debugPrint('message: $message');
          final chat = ChatModel.fromJson(jsonDecode(data['chat']));
          debugPrint('chat: $chat');
          String name = data['chatName'];
          debugPrint('name: $name');
          navigatorKey.currentState?.push(
              MaterialPageRoute(
                  builder: (_) => ChatPage(chat: chat, chatName: name)
              )
          );
        }
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

}