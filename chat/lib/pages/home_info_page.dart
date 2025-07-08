import 'dart:io';
import 'package:chat/components/edit_profile_sheet.dart';
import 'package:chat/components/friend_list.dart';
import 'package:chat/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late String _uid;

  String email = '';
  String username = '';
  String description = '';
  String profileImageUrl = '';
  bool hasPendingNotifications = true;

  List<UserModel> friends = [];

  @override
  void initState() {
    super.initState();
    _uid = _auth.currentUser!.uid;
    debugPrint('UID: $_uid');
    _loadProfile();
    _loadFriends();
  }

  Future<void> _loadProfile() async {
    final usernamePref = await UserPrefs.getUsername();

    if (usernamePref == null) {
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final data = doc.data();
      if (data != null) {
        final loadedEmail = data['email'] ?? "";
        final loadedUsername = data['username'] ?? loadedEmail;
        final loadedDescription = data['description'] ?? "No description yet.";
        final loadedProfileImageUrl = data['profileImageUrl'] ?? "";

        setState(() {
          email = loadedEmail;
          username = loadedUsername;
          description = loadedDescription;
          profileImageUrl = loadedProfileImageUrl;
        });

        // Save to SharedPreferences for future use
        await UserPrefs.saveUserProfile(
          loadedUsername,
          loadedDescription,
          loadedProfileImageUrl,
        );
      }
      return;
    } else {
      final emailPref = await UserPrefs.getEmail();
      final descriptionPref = await UserPrefs.getDescription();
      final profileImageUrlPref = await UserPrefs.getProfileImageUrl();
      setState(() {
        email = emailPref!;
        username = usernamePref;
        description = descriptionPref!;
        profileImageUrl = profileImageUrlPref!;
      });
    }
  }

  Future<void> _loadFriends() async {
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .get();

    final List<DocumentReference> friendRefs = friendsSnapshot.docs.map((doc) {
      return doc['friend'] as DocumentReference;
    }).toList();

    final friendUserSnapshots = await Future.wait(
        friendRefs.map((ref) => ref.get())
    );

    final friendUsers = friendUserSnapshots.map((docSnapshot) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return UserModel.fromFirestore(data);
    }).toList();

    debugPrint('friendUsers: $friendUsers');

    setState(() {
      friends = friendUsers;
    });
  }

  Future<void> _handleLogOut() async {
    await _auth.signOut();
    await UserPrefs.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout success')));
  }

  void _editProfileSheet() async {
    final nameController = TextEditingController(text: username);
    final descController = TextEditingController(text: description);
    String? pickedImagePath = profileImageUrl;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => EditProfileSheet(
        nameController: nameController,
        descController: descController,
        pickedImagePath: pickedImagePath,
        onImagePick: () async {
          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked != null) setState(() => pickedImagePath = picked.path);
        },
        onSave: () async {
          final newUsername = nameController.text.trim();
          final newDescription = descController.text.trim();
          final newProfileImageUrl = pickedImagePath;
          await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
            'email': email,
            'username': newUsername,
            'description': newDescription,
            'profileImageUrl': newProfileImageUrl,
          });
          await UserPrefs.saveUserProfile(
            newUsername,
            newDescription,
            newProfileImageUrl ?? '',
          );
          Navigator.pop(context);
          _loadProfile();
        },
      ),
    );
  }

  void _addFriendSheet() {
    final searchController = TextEditingController();
    final dummyResults = ["Eve", "Frank", "Grace", "Heidi"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: lightBlueGreenColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _searchInput(searchController),
          const SizedBox(height: 16),
          ...dummyResults.map((user) => _friendRequestTile(user)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showFriendRequests() {
    final sent = ["Eve", "Frank"];
    final received = ["Grace", "Henry"];

    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlueGreenColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(shrinkWrap: true, children: [
          _sectionTitle("Friend Requests"),
          _subTitle("Sent"),
          ...sent.map((name) => _statusTile(name, "Pending...", Icons.hourglass_top)),
          const SizedBox(height: 16),
          _subTitle("Received"),
          ...received.map((name) => _actionTile(name)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlueGreenColor,
      appBar: AppBar(
        backgroundColor: lightBlueColor,
        title: const Text("Home", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: strongBlueColor)),
        actions: [IconButton(icon: const Icon(Icons.logout, color: strongBlueColor), onPressed: _handleLogOut)],
      ),
      body: email.isEmpty
        ? _loading()
        : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _profileSection()),
            const SizedBox(height: 24),
            _friendsSection(),
            const SizedBox(height: 12),
            friends.isNotEmpty ? FriendsList(friends: friends) : _loading(),
          ],
      ),
    );
  }

  Widget _profileSection() => Column(children: [
    CircleAvatar(
      radius: 50,
      backgroundImage: profileImageUrl.isNotEmpty ? FileImage(File(profileImageUrl)) : null,
      child: profileImageUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
    ),
    const SizedBox(height: 12),
    Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: strongBlueColor)),
    Text(email, style: const TextStyle(fontSize: 16)),
    Text(description, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
    const SizedBox(height: 12),
    ElevatedButton.icon(
      onPressed: _editProfileSheet,
      icon: const Icon(Icons.edit),
      label: const Text("Edit Profile"),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
    ),
  ]);

  Widget _friendsSection() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text("Friends", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: strongBlueColor)),
      Row(children: [
        Stack(children: [
          IconButton(icon: const Icon(Icons.email, color: strongBlueColor), onPressed: _showFriendRequests),
          if (hasPendingNotifications)
            Positioned(
              right: 8, top: 8,
              child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
        ]),
        IconButton(icon: const Icon(Icons.person_add, color: strongBlueColor), onPressed: _addFriendSheet),
      ]),
    ],
  );

  Widget _searchInput(TextEditingController controller) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: "Search user",
      labelStyle: const TextStyle(color: strongBlueColor),
      prefixIcon: const Icon(Icons.search, color: strongBlueColor),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: strongBlueColor)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: weakBlueColor, width: 2)),
    ),
    style: const TextStyle(color: strongBlueColor),
    cursorColor: strongBlueColor,
  );

  Widget _friendRequestTile(String user) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(color: lightBlueColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
    child: ListTile(
      leading: const CircleAvatar(backgroundColor: weakBlueColor, child: Icon(Icons.person, color: Colors.white)),
      title: Text(user, style: const TextStyle(color: strongBlueColor)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: strongBlueColor, foregroundColor: Colors.white),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Friend request sent to $user'))),
        child: const Text("Send Request"),
      ),
    ),
  );

  Widget _statusTile(String name, String subtitle, IconData icon) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(color: lightBlueColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
    child: ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(name, style: const TextStyle(color: strongBlueColor)),
      subtitle: Text(subtitle, style: const TextStyle(color: strongBlueColor)),
    ),
  );

  Widget _actionTile(String name) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(color: lightBlueColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
    child: ListTile(
      leading: const Icon(Icons.person_add, color: Colors.green),
      title: Text(name, style: const TextStyle(color: strongBlueColor)),
      subtitle: const Text("Wants to be your friend", style: TextStyle(color: strongBlueColor)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {}),
        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
      ]),
    ),
  );

  Widget _sectionTitle(String title) => Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: strongBlueColor));
  Widget _subTitle(String subtitle) => Text(subtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: weakBlueColor));
  Widget _loading() => const Center(child: CircularProgressIndicator());
}
