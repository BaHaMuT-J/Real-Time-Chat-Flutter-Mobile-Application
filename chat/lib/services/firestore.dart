import 'package:chat/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat/user.dart';
import 'package:flutter/cupertino.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    final isLoadPref = await UserPrefs.getIsLoad();
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
    final isLoadPref = await UserPrefs.getIsLoad();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load friends list from Pref');
      debugPrint('$friendsListRef');
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

    UserPrefs.saveFriendsList(friendUsers);

    debugPrint('$friendUsers');
    return friendUsers;
  }

  Future<List<SentFriendRequest>> getAllSentFriendRequest({ bool isPreferPref = true}) async {
    final sentFriendRequestsListRef = await UserPrefs.getSentFriendRequests();
    final isLoadPref = await UserPrefs.getIsLoad();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load sent requests from Pref');
      debugPrint('Sent friend requests (resolved): $sentFriendRequestsListRef');
      return sentFriendRequestsListRef;
    }

    debugPrint('Load sent requests from Firestore');

    final uid = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('sent_friend_requests')
        .get();

    final List<SentFriendRequest> requests = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final DocumentReference userRef = data['user'];

      final userSnap = await userRef.get();
      final userData = userSnap.data() as Map<String, dynamic>;
      userData['uid'] = userSnap.id;
      final userModel = UserModel.fromJson(userData);

      requests.add(SentFriendRequest(user: userModel, status: data['status']));
    }

    UserPrefs.saveSentFriendRequests(requests);
    debugPrint('Sent friend requests (resolved): $requests');
    return requests;
  }

  Future<List<UserModel>> getAllReceivedFriendRequest({ bool isPreferPref = true}) async {
    final receivedFriendRequestsListRef = await UserPrefs.getReceivedFriendRequests();
    final isLoadPref = await UserPrefs.getIsLoad();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load received requests from Pref');
      debugPrint('Received friend requests (resolved): $receivedFriendRequestsListRef');
      return receivedFriendRequestsListRef;
    }

    debugPrint('Load received requests from Firestore');

    final uid = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('received_friend_requests')
        .get();

    final List<UserModel> requests = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final DocumentReference userRef = data['user'];

      final userSnap = await userRef.get();
      final userData = userSnap.data() as Map<String, dynamic>;
      userData['uid'] = userSnap.id;
      final userModel = UserModel.fromJson(userData);

      requests.add(userModel);
    }

    UserPrefs.saveReceivedFriendRequests(requests);
    debugPrint('Received friend requests (resolved): $requests');
    return requests;
  }

  Future<void> sendFriendRequest(String receiverUid) async {
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

    debugPrint('Create sent request in $currentUid');

    await _firestore
        .collection('users')
        .doc(receiverUid)
        .collection('received_friend_requests')
        .doc(currentUid)
        .set({
          'user': currentUserRef,
        });

    debugPrint('Create received request in $receiverUid');
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
        .get();

    final List<UserModel> results = [];
    for (var doc in userSnap.docs) {
      if (doc.id == currentUid) continue; // exclude self
      if (friendUids.contains(doc.id)) continue;
      if (sentUids.contains(doc.id)) continue;
      if (receivedUids.contains(doc.id)) continue;

      final data = doc.data();
      data['uid'] = doc.id;
      results.add(UserModel.fromJson(data));
    }

    debugPrint('Search results for "$keyword": ${results.map((u) => u.username)}');
    return results;
  }

}
