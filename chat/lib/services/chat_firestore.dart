import 'package:chat/model/chat_model.dart';
import 'package:chat/model/message_model.dart';
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

  Future<List<MessageModel>> getMessages(String chatId) async {
    final messagesSnap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timeStamp', descending: false)
        .get();

    final messages = messagesSnap.docs.map((doc) {
      final data = doc.data();
      return MessageModel(
        messageId: doc.id,
        senderId: data['senderId'] as String,
        text: data['text'] as String,
        timeStamp: (data['timeStamp'] as Timestamp).toDate(),
        readBys: List<String>.from(data['readBys'] ?? []),
        isFile: data['isFile'] as bool,
      );
    }).toList();

    debugPrint('Fetched messages for chat $chatId : $messages');
    return messages;
  }

  Future<void> sendMessage(String chatId, String text) async {
    final currentUID = currentUid;
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'senderId': currentUID,
      'text': text,
      'timeStamp': FieldValue.serverTimestamp(),
      'readBys': [currentUID],
      'isFile': false,
    });

    debugPrint('Sent message to $chatId: $text');

    // Update chat preview
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTimeStamp': FieldValue.serverTimestamp(),
      'lastSender': currentUID,
    });

    // Increment unread counts for other users
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final users = List<String>.from(chatDoc.data()?['users'] ?? []);
    for (final uid in users) {
      if (uid != currentUID) {
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCounts.$uid': FieldValue.increment(1),
        });
      }
    }

    UserPrefs.saveIsLoadChat(false);
  }

  Future<void> markAsRead(String chatId) async {
    final currentUID = currentUid;

    final unreadMessagesSnap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('readBys', whereNotIn: [[currentUID]])
        .get();

    final batch = _firestore.batch();

    for (final doc in unreadMessagesSnap.docs) {
      final data = doc.data();
      final readBys = List<String>.from(data['readBys'] ?? []);

      if (!readBys.contains(currentUID)) {
        final msgRef = doc.reference;
        batch.update(msgRef, {
          'readBys': FieldValue.arrayUnion([currentUID]),
        });
      }
    }

    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'unreadCounts.$currentUID': 0,
    });

    await batch.commit();
    UserPrefs.saveIsLoadChat(false);

    debugPrint('Marked all messages in chat $chatId as read by $currentUID');
  }

}
