import 'package:chat/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat/constant.dart';
import 'package:chat/user.dart';

class HomeInfoPage extends StatefulWidget {
  const HomeInfoPage({super.key});

  @override
  State<HomeInfoPage> createState() => _HomeInfoPageState();
}

class _HomeInfoPageState extends State<HomeInfoPage> {
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> friends = [
    "Alice",
    "Bob",
    "Charlie",
    "Diana",
  ];

  Future<String> _getEmail() async {
    final email = await UserPrefs.getEmail();
    return email ?? "No email";
  }

  Future<void> _handleLogOut() async {
    await _auth.signOut();

    await UserPrefs.logout();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout success')),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueGreenColor,
      appBar: AppBar(
        backgroundColor: lightBlueColor,
        title: const Text(
          "Home",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: strongBlueColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: strongBlueColor),
            onPressed: () async {
              await _handleLogOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getEmail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // loading
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final email = snapshot.data ?? "No email";

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        // backgroundImage: AssetImage('assets/default_avatar.png'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Username",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: strongBlueColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "No description yet.",
                        style: TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Friends",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: strongBlueColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...friends.map((friend) => ListTile(
                  leading:
                  const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(friend),
                )),
              ],
            );
          }
        },
      ),
    );
  }
}
