import 'dart:io';
import 'package:chat/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat/constant.dart';
import 'package:chat/user.dart';
import 'package:image_picker/image_picker.dart';

class HomeInfoPage extends StatefulWidget {
  const HomeInfoPage({super.key});

  @override
  State<HomeInfoPage> createState() => _HomeInfoPageState();
}

class _HomeInfoPageState extends State<HomeInfoPage> {
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> friends = ["Alice", "Bob", "Charlie", "Diana"];

  String? email;
  String username = "Username";
  String description = "No description yet.";
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userEmail = await UserPrefs.getEmail();
    final userName = await UserPrefs.getUsername();
    final userDesc = await UserPrefs.getDescription();
    final imagePath = await UserPrefs.getProfileImage();

    setState(() {
      email = userEmail;
      username = userName ?? "Username";
      description = userDesc ?? "No description yet.";
      profileImagePath = imagePath;
    });
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

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: username);
    final descController = TextEditingController(text: description);
    String? pickedImagePath = profileImagePath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      pickedImagePath = picked.path;
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: pickedImagePath != null
                      ? FileImage(File(pickedImagePath!))
                      : null,
                  child: pickedImagePath == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await UserPrefs.setProfile(
                    nameController.text,
                    descController.text,
                    pickedImagePath,
                  );
                  Navigator.pop(context);
                  _loadProfile();
                },
                child: const Text("Save"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
            onPressed: _handleLogOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImagePath != null
                      ? FileImage(File(profileImagePath!))
                      : null,
                  child: profileImagePath == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: strongBlueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? "Loading...",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
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
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(friend),
          )),
        ],
      ),
    );
  }
}
