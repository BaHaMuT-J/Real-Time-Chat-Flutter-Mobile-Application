import 'package:chat/model/chat_model.dart';
import 'package:chat/userPref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  Future<String> createChat(String friendUID) async {
    final currentUID = currentUid;

    final chatRef = _firestore.collection('chats').doc(); // auto ID
    final chatId = chatRef.id;

    await chatRef.set({
      'users': [currentUID, friendUID],
      'lastMessage': null,
      'lastMessageTimeStamp': null,
      'lastSender': null,
      'unreadCounts': {currentUID: 0, friendUID: 0},
      'isGroup': false,
      'chatName': null,
      'chatImageUrl': null,
    });

    debugPrint('Create chat $chatId');

    await _firestore.collection('users').doc(currentUID).collection('chats').doc(chatId).set({});
    debugPrint('Create chatRef in $currentUID successfully');

    await _firestore.collection('users').doc(friendUID).collection('chats').doc(chatId).set({});
    debugPrint('Create chatRef in $friendUID successfully');

    return chatId;
  }

  Future<void> deleteChat(String friendUID) async {
    final currentUID = currentUid;

    // Find the chat document that contains exactly these 2 users
    final querySnap = await _firestore
        .collection('chats')
        .where('users', arrayContains: currentUID)
        .get();

    for (var doc in querySnap.docs) {
      final data = doc.data();
      final users = List<String>.from(data['users']);

      // Only delete if it's exactly a chat between these two users (future proof for group)
      if (users.length == 2 && users.contains(friendUID)) {
        final chatId = doc.id;

        // Delete chat references under both users
        await _firestore.collection('users').doc(currentUID).collection('chats').doc(chatId).delete();

        debugPrint('Delete chatRef in $currentUID successfully');

        await _firestore.collection('users').doc(friendUID).collection('chats').doc(chatId).delete();

        debugPrint('Delete chatRef in $friendUID successfully');

        // Delete chat document
        await _firestore.collection('chats').doc(chatId).delete();

        debugPrint('Delete chat $chatId');

        return;
      }
    }

    debugPrint("No chat found between $currentUID and $friendUID");
  }

  Future<List<ChatModel>> getChats({ isPreferPref = true }) async {
    final chatsRef = await UserPrefs.getChats();
    final isLoadPref = await UserPrefs.getIsLoadChat();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load chats from Pref');
      debugPrint('Get chats: $chatsRef');
      return chatsRef;
    }

    debugPrint('Load chats from Firestore');

    final currentUID = currentUid;
    final userChatsSnap = await _firestore
        .collection('users')
        .doc(currentUID)
        .collection('chats')
        .get();

    final chatIds = userChatsSnap.docs.map((d) => d.id).toList();

    debugPrint('Get chatIds: $chatIds');
    if (chatIds.isEmpty) return [];

    final chatsSnap = await _firestore
        .collection('chats')
        .where(FieldPath.documentId, whereIn: chatIds)
        .get();

    final chats = chatsSnap.docs.map((doc) {
      final data = doc.data();
      data['chatId'] = doc.id;
      return ChatModel.fromJson(data);
    }).toList();

    chats.sort((a, b) {
      final aTime = a.lastMessageTimeStamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageTimeStamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    debugPrint('Get chats: $chats');
    UserPrefs.saveChats(chats);

    return chats;
  }

}
