import 'package:chat/pages/login_page.dart';
import 'package:chat/pages/main_page.dart';
import 'package:chat/userPref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Widget> decideStartPage() async {
    final email = await UserPrefs.getEmail();
    final password = await UserPrefs.getPassword();

    if (email != null && password != null) {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
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
