import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/socket.dart';
import 'package:chat/services/user_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

// For notify app state change in each page
class AppStateNotifier extends ValueNotifier<bool> {
  AppStateNotifier() : super(false);

  void refresh() {
    value = !value; // toggle to notify listeners
  }
}

final appStateNotifier = AppStateNotifier();

final FirebaseAuth auth = FirebaseAuth.instance;
final UserFirestoreService userFirestoreService = UserFirestoreService();
final ChatFirestoreService chatFirestoreService = ChatFirestoreService();
String get currentUid => auth.currentUser!.uid;
final socketService = SocketService();
