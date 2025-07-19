import 'dart:convert';

import 'package:chat/constant.dart';
import 'package:chat/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get currentUid => _auth.currentUser!.uid;

  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  static StreamSubscription<String>? _onTokenRefreshSub;

  static Future<void> initialize() async {
    debugPrint('FirebaseMessaging init');

    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load();
    await Firebase.initializeApp();

    await _requestPermission();
    await _getToken();

    _onTokenRefreshSub = _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token refreshed: $newToken");
      _sendTokenToServer(newToken);
    });

    _setupForegroundMessageHandler();
    _setupNotificationTapHandler();
    _setupBackgroundHandler();

    final initialMessage = await getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }
  }

  static Future<RemoteMessage?> getInitialMessage() async {
    return await _firebaseMessaging.getInitialMessage();
  }

  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<void> _getToken() async {
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");

    if (token != null) {
      _sendTokenToServer(token);
    }
  }

  static void _sendTokenToServer(String token) async {
    debugPrint("Sending token to server: $token");
    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';
    final url = '$backendUrl/api/fcm/set';
    debugPrint('Send token to url: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": currentUid,
          "tokenFCM": token,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("FCM token registered successfully");
      } else {
        debugPrint("Failed to register token. Status: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error occurred while registering token: $e");
    }
  }

  static void _setupNotificationTapHandler() {
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 User tapped notification and app opened');
      _handleMessageNavigation(message);
    });
  }

  static void _setupForegroundMessageHandler() {
    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔥 Foreground message received');
      if (message.notification != null) {
        debugPrint('Title: ${message.notification!.title}');
        debugPrint('Body: ${message.notification!.body}');
      }
    });
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    debugPrint('Handling navigation from notification data: $data');

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => InitialPage(payload: data,)),
          (route) => false,
    );
  }

  static void _setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Cancel listener
  static Future<void> dispose({ String? uid }) async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    debugPrint("🧹 FirebaseMessaging listeners cancelled");

    // Also delete token to stop receiving pushes
    if (uid != null) {
      debugPrint("Unregister token to server with uid: $uid");
      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';
      final url = '$backendUrl/api/fcm/unset';
      debugPrint('Unregister token to url: $url');
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "userId": uid,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("FCM token unregistered successfully");
        } else {
          debugPrint("Failed to unregister token. Status: ${response.statusCode}");
          debugPrint("Response: ${response.body}");
        }
      } catch (e) {
        debugPrint("Error occurred while unregistering token: $e");
      }
    }

    await _firebaseMessaging.deleteToken();
    debugPrint("🚫 FCM token deleted");
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("💤 Handling background message: ${message.messageId}");
}
