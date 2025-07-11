import 'package:chat/constant.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/pages/main_page.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:chat/services/socket.dart';
import 'package:chat/services/user_firestore.dart';
import 'package:chat/userPref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const InitialPage(),
    );
  }
}

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> with WidgetsBindingObserver {
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  final ChatFirestoreService _chatFirestoreService = ChatFirestoreService();
  final socketService = SocketService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    socketService.connect();
  }

  @override
  void dispose() {
    socketService.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("AppLifecycleState changed to $state");
    if (state == AppLifecycleState.paused) {
      UserPrefs.saveIsLoadUser(false);
    } else if (state == AppLifecycleState.resumed) {
      startApp(isPreferPref: false);
    }
  }

  void startApp({ isPreferPref = true}) {
    debugPrint('Start app from main.dart');
    Future.wait([
      _userFirestoreService.loadProfile(isPreferPref: isPreferPref),
      _userFirestoreService.loadFriends(isPreferPref: isPreferPref),
      _userFirestoreService.getAllSentFriendRequest(isPreferPref: isPreferPref),
      _userFirestoreService.getAllReceivedFriendRequest(isPreferPref: isPreferPref),
      _chatFirestoreService.getChats(isPreferPref: false),
    ]).then((_) {
      UserPrefs.saveIsLoadUser(true);
      UserPrefs.saveIsLoadChat(true);
      appStateNotifier.refresh();
    });
  }

  Future<Widget> decideStartPage() async {
    final email = await UserPrefs.getEmail();
    final password = await UserPrefs.getPassword();

    if (email != null && password != null) {
      try {
        await InitialPage._auth.signInWithEmailAndPassword(email: email, password: password);
        startApp(isPreferPref: false);
        return const MainPage();
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

