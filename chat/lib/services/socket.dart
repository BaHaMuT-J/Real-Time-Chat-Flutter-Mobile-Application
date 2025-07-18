import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  String get currentUid => _auth.currentUser!.uid;

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal() {
    _init();
  }

  late IO.Socket socket;

  void _init() {
    final String server = dotenv.env['SOCKET_URL']!;
    socket = IO.io(
      server,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
  }

  void connect() {
    debugPrint('Socket connect');
    socket.connect();
    socket.onConnect((_) {
      debugPrint('Connected to socket server');
    });

    socket.onDisconnect((_) {
      debugPrint('Disconnected from socket server');
    });

    debugPrint('Register currentUid: $currentUid');
    socket.emit("register", { "userId": currentUid });
  }

  void disconnect() {
    debugPrint('Unregister currentUid: $currentUid');
    socket.emit("unregister", { "userId": currentUid });

    debugPrint('Socket disconnect');
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    debugPrint('Socket emit to event: $event with data: $data');
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    debugPrint('Socket on event: $event');
    socket.on(event, callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    debugPrint('Socket off event: $event');
    socket.off(event, callback);
  }
}
