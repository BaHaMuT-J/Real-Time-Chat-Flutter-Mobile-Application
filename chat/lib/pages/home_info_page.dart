import 'dart:io';
import 'package:chat/components/action_tile.dart';
import 'package:chat/components/add_friend_sheet.dart';
import 'package:chat/components/edit_profile_sheet.dart';
import 'package:chat/components/friend_list.dart';
import 'package:chat/components/status_tile.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/services/firestore.dart';
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

class _HomeInfoPageState extends State<HomeInfoPage> with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String email = '';
  String username = '';
  String description = '';
  String profileImageUrl = '';
  bool hasPendingNotifications = true; // Not implement yet

  List<UserModel>? friends;
  List<SentFriendRequest>? sentFriendRequests;
  List<UserModel>? receivedFriendRequests;

  Set<String> sentRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("AppLifecycleState changed to $state");
    if (state == AppLifecycleState.paused) {
      UserPrefs.saveIsLoad(false);
    } else if (state == AppLifecycleState.resumed) {
      startApp();
    }
  }

  void startApp() {
    Future.wait([
      _loadProfile(),
      _loadFriends(),
      _loadSentFriendRequests(),
      _loadReceivedFriendRequests(),
    ]).then((_) {
      UserPrefs.saveIsLoad(true);
    });
  }

  Future<void> _loadProfile({ bool isPreferPref = true}) async {
    final data = await _firestoreService.loadProfile(isPreferPref: isPreferPref);
    if (data != null) {
      setState(() {
        email = data['email'];
        username = data['username'];
        description = data['description'];
        profileImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _loadFriends({ bool isPreferPref = true}) async {
    final friendUsers = await _firestoreService.loadFriends(isPreferPref: isPreferPref);
    setState(() {
      friends = friendUsers;
    });
  }

  Future<void> _loadSentFriendRequests({ bool isPreferPref = true}) async {
    final allSentFriendRequests = await _firestoreService.getAllSentFriendRequest(isPreferPref: isPreferPref);
    setState(() {
      sentFriendRequests = allSentFriendRequests;
    });
  }

  Future<void> _loadReceivedFriendRequests({ bool isPreferPref = true}) async {
    final allReceivedFriendRequests = await _firestoreService.getAllReceivedFriendRequest(isPreferPref: isPreferPref);
    setState(() {
      receivedFriendRequests = allReceivedFriendRequests;
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
          final newProfileImageUrl = pickedImagePath ?? '';
          await _firestoreService.updateProfile(
            email: email,
            username: newUsername,
            description: newDescription,
            profileImageUrl: newProfileImageUrl,
          );
          Navigator.pop(context);
          _loadProfile();
        },
      ),
    );
  }

  void _addFriendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: lightBlueGreenColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddFriendSheet(
        onRequestSent: () => _loadSentFriendRequests(isPreferPref: false),
      ),
    );
  }

  void _showFriendRequests() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlueGreenColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(shrinkWrap: true, children: [
          _sectionTitle("Friend Requests"),
          const SizedBox(height: 16),
          _subTitle("Sent"),
          ...(sentFriendRequests != null
            ? sentFriendRequests!.isNotEmpty
              ? sentFriendRequests!
                .map((request) => StatusTile(
                  request: request,
                  onCancel: () async {
                    await _firestoreService.cancelSentRequest(request.user.uid);
                    _loadSentFriendRequests(isPreferPref: false);
                  },
                  onClose: () async {
                    await _firestoreService.closeSentRequest(request.user.uid);
                    _loadSentFriendRequests(isPreferPref: false);
                  },
                )).toList()
              : [Text("You have no sent friend request", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: strongBlueColor))]
            : [_loading()]
          ),
          const SizedBox(height: 16),
          _subTitle("Received"),
          ...(receivedFriendRequests != null
            ? receivedFriendRequests!.isNotEmpty
              ? receivedFriendRequests!
                .map((user) => ActionTile(
                  user: user,
                  onApprove: () async {
                    await _firestoreService.acceptFriendRequest(user.uid);
                    _loadReceivedFriendRequests(isPreferPref: false);
                    _loadFriends(isPreferPref: false);
                  },
                  onReject: () async {
                    await _firestoreService.rejectFriendRequest(user.uid);
                    _loadReceivedFriendRequests(isPreferPref: false);
                  },
                ))
                .toList()
              : [Text("You have no received friend request", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: strongBlueColor))]
            : [_loading()]
          ),
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
            friends != null
                ? friends!.isNotEmpty
                  ? FriendsList(friends: friends!)
                  : Center(
                      child: Text("You have no friend yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: strongBlueColor))
                    )
                : _loading(),
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

  Widget _sectionTitle(String title) => Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: strongBlueColor));
  Widget _subTitle(String subtitle) => Text(subtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: weakBlueColor));
  Widget _loading() => const Center(child: CircularProgressIndicator());
}
