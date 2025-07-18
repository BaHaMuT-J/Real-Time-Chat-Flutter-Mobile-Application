import 'package:chat/constant.dart';
import 'package:chat/model/received_friend_request_model.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:chat/services/chat_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat/userPref.dart';
import 'package:flutter/cupertino.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatFirestoreService _chatFirestoreService = ChatFirestoreService();

  Future<UserModel?> getUser(String uid) async {
    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (docSnap.exists) {
        final data = docSnap.data()!;
        data['uid'] = uid;
        final user = UserModel.fromJson(data);
        return user;
      } else {
        debugPrint('User $uid not found');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting user $uid: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String email,
    required String username,
    required String description,
    required String profileImageUrl,
  }) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
      'email': email,
      'username': username,
      'description': description,
      'profileImageUrl': profileImageUrl,
    });

    await UserPrefs.saveUserProfile(username, description, profileImageUrl);
  }

  Future<Map<String, dynamic>?> loadProfile({ bool isPreferPref = true}) async {
    final usernamePref = await UserPrefs.getUsername();
    final isLoadPref = await UserPrefs.getIsLoadUser();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load profile from Pref');
      final emailPref = await UserPrefs.getEmail();
      final descriptionPref = await UserPrefs.getDescription();
      final profileImageUrlPref = await UserPrefs.getProfileImageUrl();
      return {
        'email': emailPref ?? '',
        'username': usernamePref ?? '',
        'description': descriptionPref ?? "No description yet.",
        'profileImageUrl': profileImageUrlPref ?? '',
      };
    }

    debugPrint('Load profile from Firestore');
    final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    final data = doc.data();
    if (data != null) {
      final loadedEmail = data['email'] ?? "";
      final loadedUsername = data['username'] ?? loadedEmail;
      final loadedDescription = data['description'] ?? "No description yet.";
      final loadedProfileImageUrl = data['profileImageUrl'] ?? "";

      UserPrefs.saveUserProfile(
        loadedUsername,
        loadedDescription,
        loadedProfileImageUrl,
      );

      return {
        'email': loadedEmail,
        'username': loadedUsername,
        'description': loadedDescription,
        'profileImageUrl': loadedProfileImageUrl,
      };
    }
    return null;
  }

  Future<List<UserModel>> loadFriends({ bool isPreferPref = true}) async {
    final friendsListRef = await UserPrefs.getFriendsList();
    final isLoadPref = await UserPrefs.getIsLoadFriend();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load friends list from Pref');
      return friendsListRef;
    }

    debugPrint('Load friends list from Firestore');
    final uid = _auth.currentUser!.uid;
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .get();

    final List<DocumentReference> friendRefs = friendsSnapshot.docs.map((doc) {
      return doc['friend'] as DocumentReference;
    }).toList();

    final friendUserSnapshots = await Future.wait(
      friendRefs.map((ref) => ref.get()),
    );

    final friendUsers = friendUserSnapshots.map((docSnapshot) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final uid = docSnapshot.id;
      data['uid'] = uid;
      return UserModel.fromJson(data);
    }).toList();

    friendUsers.sort((a, b) => a.username.compareTo(b.username));

    UserPrefs.saveFriendsList(friendUsers);

    return friendUsers;
  }

  Future<Pair<List<SentFriendRequestModel>, bool>> getAllSentFriendRequest({ bool isPreferPref = true}) async {
    final sentFriendRequestsListRef = await UserPrefs.getSentFriendRequests();
    final isLoadPref = await UserPrefs.getIsLoadSentRequest();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load sent requests from Pref');
      return Pair(sentFriendRequestsListRef, false);
    }

    debugPrint('Load sent requests from Firestore');

    final uid = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('sent_friend_requests')
        .get();

    final List<SentFriendRequestModel> requests = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final DocumentReference userRef = data['user'];

      final userSnap = await userRef.get();
      final userData = userSnap.data() as Map<String, dynamic>;
      userData['uid'] = userSnap.id;
      final userModel = UserModel.fromJson(userData);

      requests.add(SentFriendRequestModel(user: userModel, status: data['status']));
    }

    requests.sort((a, b) => a.user.username.compareTo(b.user.username));

    UserPrefs.saveSentFriendRequests(requests);
    return Pair(requests, sentFriendRequestsListRef.length != requests.length);
  }

  Future<Pair<List<ReceivedFriendRequestModel>, bool>> getAllReceivedFriendRequest({ bool isPreferPref = true}) async {
    final receivedFriendRequestsListRef = await UserPrefs.getReceivedFriendRequests();
    final isLoadPref = await UserPrefs.getIsLoadReceivedRequest();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load received requests from Pref');
      return Pair(receivedFriendRequestsListRef, false);
    }

    debugPrint('Load received requests from Firestore');

    final uid = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('received_friend_requests')
        .get();

    final List<ReceivedFriendRequestModel> requests = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final DocumentReference userRef = data['user'];

      final userSnap = await userRef.get();
      final userData = userSnap.data() as Map<String, dynamic>;
      userData['uid'] = userSnap.id;
      final requestModel = ReceivedFriendRequestModel.fromJson(userData);

      requests.add(requestModel);
    }

    requests.sort((a, b) => a.username.compareTo(b.username));

    UserPrefs.saveReceivedFriendRequests(requests);
    return Pair(requests, receivedFriendRequestsListRef.length != requests.length);
  }

  Future<Pair<SentFriendRequestModel, ReceivedFriendRequestModel>> sendFriendRequest(String receiverUid) async {
    final currentUid = _auth.currentUser!.uid;

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final receiverUserRef = _firestore.collection('users').doc(receiverUid);

    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('sent_friend_requests')
        .doc(receiverUid)
        .set({
          'user': receiverUserRef,
          'status': 'Pending...',
        });

    await _firestore
        .collection('users')
        .doc(receiverUid)
        .collection('received_friend_requests')
        .doc(currentUid)
        .set({
          'user': currentUserRef,
        });

    final currentUserSnap = await currentUserRef.get();
    final receiverUserSnap = await receiverUserRef.get();

    final currentUserData = currentUserSnap.data()!;
    currentUserData['uid'] = currentUserSnap.id;

    final receiverUserData = receiverUserSnap.data()!;
    receiverUserData['uid'] = receiverUserSnap.id;

    final currentUserModel = UserModel.fromJson(currentUserData);
    final receiverUserModel = UserModel.fromJson(receiverUserData);

    final sentRequest = SentFriendRequestModel(
      user: receiverUserModel,
      status: 'Pending...',
    );

    final receivedRequest = ReceivedFriendRequestModel(
      uid: currentUserModel.uid,
      username: currentUserModel.username,
      description: currentUserModel.description,
      profileImageUrl: currentUserModel.profileImageUrl,
    );

    return Pair(sentRequest, receivedRequest);
  }

  Future<List<UserModel>> searchUsers(String keyword) async {
    final currentUid = _auth.currentUser!.uid;

    // 1. Get current friends
    final friendsSnap = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .get();
    final friendUids = friendsSnap.docs.map((doc) => doc.id).toSet();

    // 2. Get sent requests
    final sentSnap = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('sent_friend_requests')
        .where('status', isEqualTo: 'Pending...')
        .get();
    final sentUids = sentSnap.docs.map((doc) => doc.id).toSet();

    // 3. Get received requests
    final receivedSnap = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('received_friend_requests')
        .get();
    final receivedUids = receivedSnap.docs.map((doc) => doc.id).toSet();

    // 4. Query users where name matches
    final userSnap = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: keyword)
        .where('username', isLessThanOrEqualTo: '$keyword\uf8ff')
        .orderBy('username')
        .get();

    final List<UserModel> results = [];
    for (var doc in userSnap.docs) {
      if (doc.id == currentUid) continue;
      if (friendUids.contains(doc.id)) continue;
      if (sentUids.contains(doc.id)) continue;
      if (receivedUids.contains(doc.id)) continue;

      final data = doc.data();
      data['uid'] = doc.id;
      results.add(UserModel.fromJson(data));
    }

    return results;
  }

  Future<void> acceptFriendRequest(String senderUid) async {
    final currentUid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(senderUid)
        .collection('sent_friend_requests')
        .doc(currentUid)
        .update({'status': 'Accepted'});

    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('received_friend_requests')
        .doc(senderUid)
        .delete();

    final currentUserRef = _firestore.collection('users').doc(currentUid);
    final senderUserRef = _firestore.collection('users').doc(senderUid);

    await _firestore.collection('users').doc(currentUid)
        .collection('friends')
        .doc(senderUid)
        .set({'friend': senderUserRef});

    await _firestore.collection('users').doc(senderUid)
        .collection('friends')
        .doc(currentUid)
        .set({'friend': currentUserRef});

    // Create chat between these users
    await UserPrefs.saveIsLoadChat(false);
    _chatFirestoreService.createChat(senderUid);
  }

  Future<void> rejectFriendRequest(String senderUid) async {
    final currentUid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(senderUid)
        .collection('sent_friend_requests')
        .doc(currentUid)
        .update({'status': 'Rejected'});

    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('received_friend_requests')
        .doc(senderUid)
        .delete();
  }

  Future<void> cancelSentRequest(String receiverUid) async {
    final currentUid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('sent_friend_requests')
        .doc(receiverUid)
        .delete();

    await _firestore
        .collection('users')
        .doc(receiverUid)
        .collection('received_friend_requests')
        .doc(currentUid)
        .delete();
  }

  Future<void> closeSentRequest(String receiverUid) async {
    final currentUid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('sent_friend_requests')
        .doc(receiverUid)
        .delete();
  }

  Future<void> unfriend(String friendUID) async {
    final currentUid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(friendUID)
        .collection('friends')
        .doc(currentUid)
        .delete();

    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .doc(friendUID)
        .delete();

    // Clean up any leftover sent friend requests
    await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('sent_friend_requests')
        .doc(friendUID)
        .delete()
        .catchError((e) => debugPrint('No sent request to $friendUID to delete'));

    await _firestore
        .collection('users')
        .doc(friendUID)
        .collection('sent_friend_requests')
        .doc(currentUid)
        .delete()
        .catchError((e) => debugPrint('No sent request from $friendUID to delete'));

    // Delete chat between these users
    await UserPrefs.saveIsLoadChat(false);
    _chatFirestoreService.deleteChat(friendUID);
  }

}
