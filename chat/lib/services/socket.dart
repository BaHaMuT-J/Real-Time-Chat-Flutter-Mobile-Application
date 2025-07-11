import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  // final isTesting = true; // dummy for testing, check if socket server is running
  final isTesting = false;

  SocketService._internal() {
    _init();
  }

  late IO.Socket socket;

  void _init() {
    final String server = dotenv.env['SOCKET_URL']!;
    if (isTesting) return;
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
    if (isTesting) return;
    socket.connect();
    socket.onConnect((_) {
      debugPrint('Connected to socket server');
    });

    socket.onDisconnect((_) {
      debugPrint('Disconnected from socket server');
    });
  }

  void disconnect() {
    debugPrint('Socket disconnect');
    if (isTesting) return;
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    if (isTesting) return;
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    if (isTesting) return;
    socket.on(event, callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    if (isTesting) return;
    socket.off(event, callback);
  }
}
