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

    await _firestore.collection('users').doc(currentUID).collection('chats').doc(chatId).set({});
    await _firestore.collection('users').doc(friendUID).collection('chats').doc(chatId).set({});
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
        await _firestore.collection('users').doc(friendUID).collection('chats').doc(chatId).delete();

        // Delete chat document
        await _firestore.collection('chats').doc(chatId).delete();

        return;
      }
    }
  }

  Future<List<ChatModel>> getChats({ isPreferPref = true }) async {
    final chatsRef = await UserPrefs.getChats();
    final isLoadPref = await UserPrefs.getIsLoadChat();
    if (isPreferPref && isLoadPref != null && isLoadPref) {
      debugPrint('Load chats from Pref');
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
    if (chatIds.isEmpty) {
      UserPrefs.saveChats([]);
      return [];
    };

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

    UserPrefs.saveChats(chats);
    return chats;
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return ChatModel(
        chatId: doc.id,
        users: List<String>.from(data['users'] ?? []),
        isGroup: data['isGroup'] ?? false,
        chatName: data['chatName'],
        chatImageUrl: data['chatImageUrl'],
        lastMessage: data['lastMessage'],
        lastMessageTimeStamp: data['lastMessageTimeStamp'] != null
            ? (data['lastMessageTimeStamp'] as Timestamp).toDate()
            : null,
        unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      );
    } catch (e) {
      debugPrint('Error fetching chat by ID: $e');
      return null;
    }
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
    return messages;
  }

  Future<MessageModel> sendMessage(String chatId, String text) async {
    final currentUID = currentUid;
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final timeNow = DateTime.now();

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

    // Build MessageModel
    return MessageModel(
      messageId: messageRef.id,
      senderId: currentUID,
      text: text,
      timeStamp: timeNow,
      readBys: [currentUID],
      isFile: false,
    );
  }

  Future<void> markAsRead(String chatId, String messageId) async {
    final currentUID = currentUid;

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final messageSnap = await messageRef.get();
    if (!messageSnap.exists) {
      debugPrint('Message $messageId does not exist in chat $chatId');
      return;
    }

    final data = messageSnap.data();
    final readBys = List<String>.from(data?['readBys'] ?? []);

    if (!readBys.contains(currentUID)) {
      final batch = _firestore.batch();
      batch.update(messageRef, {
        'readBys': FieldValue.arrayUnion([currentUID]),
      });

      // safely decrement unreadCounts
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnap = await chatRef.get();
      final chatData = chatSnap.data();
      final unreadCounts = Map<String, dynamic>.from(chatData?['unreadCounts'] ?? {});
      final currentCount = (unreadCounts[currentUID] ?? 0) as int;

      if (currentCount > 0) {
        batch.update(chatRef, {
          'unreadCounts.$currentUID': FieldValue.increment(-1),
        });
      }

      await batch.commit();
      debugPrint('Marked message $messageId in chat $chatId as read by $currentUID');
    } else {
      debugPrint('Message $messageId in chat $chatId already marked as read by $currentUID');
    }

    UserPrefs.saveIsLoadChat(false);
  }

  Future<void> markAsReadAll(String chatId) async {
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
