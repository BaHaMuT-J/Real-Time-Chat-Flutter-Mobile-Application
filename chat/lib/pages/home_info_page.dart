import 'dart:convert';
import 'dart:io';
import 'package:chat/components/add_friend_sheet.dart';
import 'package:chat/components/edit_profile_sheet.dart';
import 'package:chat/components/friend_list.dart';
import 'package:chat/components/friend_request_sheet.dart';
import 'package:chat/components/profile_avatar.dart';
import 'package:chat/model/received_friend_request_model.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:chat/pages/login_page.dart';
import 'package:chat/services/firebase_message.dart';
import 'package:chat/services/local_notification.dart';
import 'package:chat/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:chat/constant.dart';
import 'package:chat/userPref.dart';
import 'package:image_picker/image_picker.dart';

class HomeInfoPage extends StatefulWidget {
  const HomeInfoPage({super.key});

  @override
  State<HomeInfoPage> createState() => _HomeInfoPageState();
}

class _HomeInfoPageState extends State<HomeInfoPage> {
  final StorageService _storageService = StorageService();

  String email = '';
  String username = '';
  String description = '';
  String profileImageUrl = '';
  bool hasNewRequests = false;

  List<UserModel>? friends;
  List<SentFriendRequestModel>? sentFriendRequests;
  List<ReceivedFriendRequestModel>? receivedFriendRequests;

  @override
  void initState() {
    super.initState();
    appStateNotifier.addListener(_onAppStateChanged);
    startApp();
    socketService.on("message", _listenToMessage);
    socketService.on("friend", _listenToFriend);
    socketService.on("sentRequest", _listenToSentRequest);
    socketService.on("receivedRequest", _listenToReceivedRequest);
  }

  @override
  void dispose() {
    debugPrint('Dispose from Home Info page');
    // When dispose after logout, this will have error
    try {
      socketService.off("message", _listenToMessage);
      socketService.off("friend", _listenToFriend);
      socketService.off("sentRequest", _listenToSentRequest);
      socketService.off("receivedRequest", _listenToReceivedRequest);
    } catch (e) {
      debugPrint('Unregister socket error from Home Info page: $e');
    }
    appStateNotifier.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    debugPrint('On app state changed from home info page');
    startApp();
  }

  void _listenToMessage(data) async {
    UserPrefs.saveIsLoadChat(false);
    LocalNotificationService.showNotificationFromSocket(data);
  }

  // data = {
  //     'userId': senderUid,
  //     'friendId': currentUid,
  //     'isCreate': true,
  //     'isDelete': true,
  //   }
  void _listenToFriend(data) async {
    debugPrint('Home info socket friend in $currentUid: $data');
    final friendUid = data['friendId'];
    final friend = await userFirestoreService.getUser(friendUid);
    if (data['isCreate'] != null && data['isCreate'] as bool == true) {
      setState(() {
        friends?.add(friend!);
        friends?.sort((a, b) => a.username.compareTo(b.username));
        hasNewRequests = true;
      });
      UserPrefs.saveFriendsList(friends!);
    } else if (data['isDelete'] != null && data['isDelete'] as bool == true) {
      setState(() {
        friends?.removeWhere((user) => user.uid == friend?.uid);
        hasNewRequests = true;
      });
      UserPrefs.saveFriendsList(friends!);
    }
    UserPrefs.saveIsLoadChat(false);
  }

  void _listenToSentRequest(data) async {
    debugPrint('Home info socket sent request in $currentUid: $data');
    final sentRequest = SentFriendRequestModel.fromJson(jsonDecode(data['request']));
    if (data['isUpdate'] != null && data['isUpdate'] as bool == true) {
      setState(() {
        final index = sentFriendRequests?.indexWhere((request) => request.user.uid == sentRequest.user.uid);
        if (index != null && index != -1) {
          sentFriendRequests?[index] = sentRequest;
          hasNewRequests = true;
        }
      });
    } else if (data['isDelete'] != null && data['isDelete'] as bool == true) {
      setState(() {
        sentFriendRequests?.removeWhere((request) => request.user.uid == sentRequest.user.uid);
        hasNewRequests = true;
      });
    }
  }

  void _listenToReceivedRequest(data) async {
    debugPrint('Home info socket received request in $currentUid: $data');
    final receivedRequest = ReceivedFriendRequestModel.fromJson(jsonDecode(data['request']));
    if (data['isCreate'] != null && data['isCreate'] as bool == true) {
      setState(() {
        receivedFriendRequests?.add(receivedRequest);
        receivedFriendRequests?.sort((a, b) => a.username.compareTo(b.username));
        hasNewRequests = true;
      });
    } else if (data['isDelete'] != null && data['isDelete'] as bool == true) {
      setState(() {
        receivedFriendRequests?.removeWhere((request) => request.uid == receivedRequest.uid);
        hasNewRequests = true;
      });
    }
  }

  void startApp() {
    debugPrint('Start app from home info page');
    Future.wait([
      _loadProfile(),
      _loadFriends(),
      _loadSentFriendRequests(),
      _loadReceivedFriendRequests(),
    ]).then((_) {
      UserPrefs.saveIsLoadUser(true);
      UserPrefs.saveIsLoadFriend(true);
      UserPrefs.saveIsLoadSentRequest(true);
      UserPrefs.saveIsLoadReceivedRequest(true);
    });
  }

  Future<void> _loadProfile({bool isPreferPref = true}) async {
    try {
      final data = await userFirestoreService.loadProfile(isPreferPref: isPreferPref);
      if (data != null) {
        setState(() {
          email = data['email'];
          username = data['username'];
          description = data['description'];
          profileImageUrl = data['profileImageUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _loadFriends({bool isPreferPref = true}) async {
    try {
      final friendUsers = await userFirestoreService.loadFriends(isPreferPref: isPreferPref);
      setState(() {
        friends = friendUsers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load friends: $e')),
        );
      }
    }
  }

  Future<void> _loadSentFriendRequests({bool isPreferPref = true}) async {
    try {
      final pair = await userFirestoreService.getAllSentFriendRequest(isPreferPref: isPreferPref);
      setState(() {
        sentFriendRequests = pair.first;
        hasNewRequests = pair.second || hasNewRequests;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sent friend requests: $e')),
        );
      }
    }
  }

  Future<void> _loadReceivedFriendRequests({bool isPreferPref = true}) async {
    try {
      final pair = await userFirestoreService.getAllReceivedFriendRequest(isPreferPref: isPreferPref);
      setState(() {
        receivedFriendRequests = pair.first;
        hasNewRequests = pair.second || hasNewRequests;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load received friend requests: $e')),
        );
      }
    }
  }

  Future<void> _handleLogOut() async {
    try {
      String uid = currentUid;
      socketService.disconnect();
      await auth.signOut();
      await UserPrefs.logout();
      await FirebaseMessagingService.dispose(uid: uid);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout success')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
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
        initialImagePath: profileImageUrl,
        onImagePick: () async {
          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked != null) setState(() => pickedImagePath = picked.path);
          return picked?.path;
        },
        onSave: () async {
          final newUsername = nameController.text.trim();
          final newDescription = descController.text.trim();

          String newProfileImageUrl = profileImageUrl;
          if (pickedImagePath != null && !pickedImagePath!.startsWith('http')) {
            final file = File(pickedImagePath!);
            newProfileImageUrl = await _storageService.uploadProfileImage(file, currentUid);
          }

          if (newUsername != username || newDescription != description || newProfileImageUrl != profileImageUrl) {
            await userFirestoreService.updateProfile(
              email: email,
              username: newUsername,
              description: newDescription,
              profileImageUrl: newProfileImageUrl,
            );
            await _loadProfile(isPreferPref: false);
          }

          Navigator.pop(context);
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
        onRequestSent: (sentRequest, receivedRequest) async {
          // Create own new request
          setState(() {
            sentFriendRequests?.add(sentRequest);
            sentFriendRequests?.sort((a, b) => a.user.username.compareTo(b.user.username));
          });

          // Emit to create received request of other user
          socketService.emit("receivedRequest", {
            'userId': sentRequest.user.uid,
            'request': jsonEncode(receivedRequest.toJson()),
            'isCreate': true,
          });
        },
      ),
    );
  }

  void _showFriendRequests() {
    showModalBottomSheet(
      context: context,
      backgroundColor: lightBlueGreenColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => FriendRequestsSheet(
          sentRequests: sentFriendRequests,
          receivedRequests: receivedFriendRequests,
          onCancelSent: (receiverUid) async {
            final pair = await userFirestoreService.cancelSentRequest(receiverUid);
            final sentRequest = pair.first;
            final receivedRequest = pair.second;

            // Delete own sent request
            setState(() {
              sentFriendRequests?.removeWhere((request) => request.user.uid == sentRequest.user.uid);
            });

            // Emit to delete received request of other user
            socketService.emit("receivedRequest", {
              'userId': sentRequest.user.uid,
              'request': jsonEncode(receivedRequest.toJson()),
              'isDelete': true,
            });

            setModalState(() {});
          },
          onCloseSent: (receiverUid) async {
            await userFirestoreService.closeSentRequest(receiverUid);

            // Delete own sent request
            setState(() {
              sentFriendRequests?.removeWhere((request) => request.user.uid == receiverUid);
            });

            setModalState(() {});
          },
          onApproveReceived: (uid) async {
            final mainPair = await userFirestoreService.acceptFriendRequest(uid);
            final senderUid = mainPair.first;
            final sentRequest = mainPair.second;

            // Emit to delete sentRequest of other user
            socketService.emit("sentRequest", {
              'userId': senderUid,
              'request': jsonEncode(sentRequest.toJson()),
              'isUpdate': true,
            });

            // Delete own received request
            setState(() {
              receivedFriendRequests?.removeWhere((request) => request.uid == senderUid);
            });

            // Emit friend to other user
            socketService.emit("friend", {
              'userId': senderUid,
              'friendId': currentUid,
              'isCreate': true,
            });

            // Create own new friend
            final friend = await userFirestoreService.getUser(senderUid);
            setState(() {
              friends?.add(friend!);
              friends?.sort((a, b) => a.username.compareTo(b.username));
            });

            setModalState(() {});
          },
          onRejectReceived: (uid) async {
            final pair = await userFirestoreService.rejectFriendRequest(uid);
            final sentRequest = pair.first;
            final receivedRequest = pair.second;

            // Emit to update status of sent request of other user
            socketService.emit("sentRequest", {
              'userId': receivedRequest.uid,
              'request': jsonEncode(sentRequest.toJson()),
              'isUpdate': true,
            });

            // Delete own received request
            setState(() {
              receivedFriendRequests?.removeWhere((request) => request.uid == receivedRequest.uid);
            });

            setModalState(() {});
          },
        ),
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
                  ? FriendsList(
                      friends: friends!,
              onUnfriend: (UserModel friend) async {
                try {
                  await userFirestoreService.unfriend(friend.uid);
                  await _loadFriends(isPreferPref: false);
                  await _loadSentFriendRequests(isPreferPref: false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unfriended ${friend.username}')),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to unfriend: $e')),
                    );
                  }
                }
              },
            )
                  : Center(
                      child: Text("You have no friend yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: strongBlueColor))
                    )
                : _loading(),
          ],
      ),
    );
  }

  Widget _profileSection() => Column(children: [
    ProfileAvatar(imagePath: profileImageUrl, radius: 50,),
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
          if (hasNewRequests)
            Positioned(
              right: 8, top: 8,
              child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
        ]),
        IconButton(icon: const Icon(Icons.person_add, color: strongBlueColor), onPressed: _addFriendSheet),
      ]),
    ],
  );

  Widget _loading() => const Center(child: CircularProgressIndicator());
}
