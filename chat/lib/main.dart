import 'package:chat/constant.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/pages/main_page.dart';
import 'package:chat/services/firebase_message.dart';
import 'package:chat/services/local_notification.dart';
import 'package:chat/userPref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  LocalNotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const InitialPage(),
    );
  }
}

class InitialPage extends StatefulWidget {
  const InitialPage({super.key, this.payload});

  final dynamic payload;

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("AppLifecycleState changed to $state");
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      UserPrefs.saveIsLoadUser(false);
      UserPrefs.saveIsLoadFriend(false);
      UserPrefs.saveIsLoadSentRequest(false);
      UserPrefs.saveIsLoadReceivedRequest(false);
      UserPrefs.saveIsLoadChat(false);
    } else if (state == AppLifecycleState.resumed) {
      setNotLoadFromPref();
    }
  }

  void setNotLoadFromPref() {
    debugPrint('Start app from main.dart');
    UserPrefs.saveIsLoadUser(false);
    UserPrefs.saveIsLoadFriend(false);
    UserPrefs.saveIsLoadSentRequest(false);
    UserPrefs.saveIsLoadReceivedRequest(false);
    UserPrefs.saveIsLoadChat(false);
    appStateNotifier.refresh();
  }

  Future<Widget> decideStartPage() async {
    RemoteMessage? initialMessage = await FirebaseMessagingService.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      debugPrint('initialMessage: $initialMessage');
    }

    final email = await UserPrefs.getEmail();
    final password = await UserPrefs.getPassword();

    if (email != null && password != null) {
      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        socketService.connect();
        setNotLoadFromPref();
        await FirebaseMessagingService.initialize();
        return MainPage(payload: widget.payload);
      } on FirebaseAuthException catch (e) {
        debugPrint('Login failed: ${e.message}');
        return const LoginPage();
      }
    } else {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: decideStartPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return snapshot.data!;
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

