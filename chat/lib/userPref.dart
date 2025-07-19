import 'dart:convert';

import 'package:chat/constant.dart';
import 'package:chat/model/chat_model.dart';
import 'package:chat/model/received_friend_request_model.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveIsOnBoard(bool isOnBoard) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('isOnBoard', isOnBoard);
  }

  static Future<bool> getIsOnBoard() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('isOnBoard') ?? false;
  }

  static Future<void> saveFontSize(double size) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setDouble('fontSize', size);
  }

  static Future<double> getFontSize() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getDouble('fontSize') ?? 0;
  }

  static Future<void> saveThemeColor(int index) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setInt('themeColor', index);
  }

  static Future<int> getThemeColor() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getInt('themeColor') ?? 0;
  }

  static Future<void> saveCredential(String email, String password) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  static Future<String?> getEmail() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getString('email');
  }

  static Future<String?> getPassword() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getString('password');
  }

  static Future<void> saveUserProfile(String username, String description, String profileImageUrl) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setString('username', username);
    await prefs.setString('description', description);
    await prefs.setString('profileImageUrl', profileImageUrl);
  }

  static Future<String?> getUsername() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getString('username');
  }

  static Future<String?> getDescription() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getString('description');
  }

  static Future<String?> getProfileImageUrl() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getString('profileImageUrl');
  }

  static Future<void> saveFriendsList(List<UserModel> users) async {
    final prefs = await UserPrefs._getPrefs();
    List<String> userJsonList = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('friendsList', userJsonList);
  }

  static Future<List<UserModel>> getFriendsList() async {
    final prefs = await UserPrefs._getPrefs();
    List<String>? userJsonList = prefs.getStringList('friendsList');
    if (userJsonList == null) return [];

    return userJsonList
        .map((userJson) => UserModel.fromJson(jsonDecode(userJson)))
        .toList();
  }

  static Future<Pair<List<UserModel>, bool>> handleFriendFromSocket(data) async {
    final friends = await UserPrefs.getFriendsList();
    bool hasNewRequests = false;

    final friendUid = data['friendId'];
    final friend = await userFirestoreService.getUser(friendUid);
    if (data['isCreate'] != null && data['isCreate'] as bool == true) {
      friends.add(friend!);
      friends.sort((a, b) => a.username.compareTo(b.username));
      UserPrefs.saveFriendsList(friends);
    } else if (data['isDelete'] != null && data['isDelete'] as bool == true) {
      friends.removeWhere((user) => user.uid == friend?.uid);
      hasNewRequests = true;
      UserPrefs.saveFriendsList(friends);
      UserPrefs.saveHasNewRequest(true);
    }

    UserPrefs.saveIsLoadChat(false);
    return Pair(friends, hasNewRequests);
  }

  static Future<void> saveSentFriendRequests(List<SentFriendRequestModel> requests) async {
    final prefs = await UserPrefs._getPrefs();
    List<String> requestJsonList = requests.map((request) => jsonEncode(request.toJson())).toList();
    await prefs.setStringList('sentRequestsList', requestJsonList);
  }

  static Future<List<SentFriendRequestModel>> getSentFriendRequests() async {
    final prefs = await UserPrefs._getPrefs();
    List<String>? request = prefs.getStringList('sentRequestsList');
    if (request == null) return [];

    return request
        .map((requestJson) => SentFriendRequestModel.fromJson(jsonDecode(requestJson)))
        .toList();
  }

  static Future<Pair<List<SentFriendRequestModel>, bool>> handleSentRequestFromSocket(data) async {
    final sentFriendRequests = await UserPrefs.getSentFriendRequests();
    bool hasNewRequests = false;

    final sentRequest = SentFriendRequestModel.fromJson(jsonDecode(data['request']));
    if (data['isUpdate'] != null && data['isUpdate'] as bool == true) {
      final index = sentFriendRequests.indexWhere((request) => request.user.uid == sentRequest.user.uid);
      if (index != -1) {
        sentFriendRequests[index] = sentRequest;
        hasNewRequests = true;
        UserPrefs.saveSentFriendRequests(sentFriendRequests);
        UserPrefs.saveHasNewRequest(true);
      }
    } else if (data['isDelete'] != null && data['isDelete'] as bool == true) {
      sentFriendRequests.removeWhere((request) => request.user.uid == sentRequest.user.uid);
      hasNewRequests = true;
      UserPrefs.saveSentFriendRequests(sentFriendRequests);
      UserPrefs.saveHasNewRequest(true);
    }

    return Pair(sentFriendRequests, hasNewRequests);
  }

  static Future<void> saveReceivedFriendRequests(List<ReceivedFriendRequestModel> users) async {
    final prefs = await UserPrefs._getPrefs();
    List<String> userJsonList = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('receivedRequestsList', userJsonList);
  }

  static Future<List<ReceivedFriendRequestModel>> getReceivedFriendRequests() async {
    final prefs = await UserPrefs._getPrefs();
    List<String>? userJsonList = prefs.getStringList('receivedRequestsList');
    if (userJsonList == null) return [];

    return userJsonList
        .map((userJson) => ReceivedFriendRequestModel.fromJson(jsonDecode(userJson)))
        .toList();
  }

  static Future<Pair<List<ReceivedFriendRequestModel>, bool>> handleReceivedRequestFromSocket(data) async {
    final receivedFriendRequests = await UserPrefs.getReceivedFriendRequests();
    bool hasNewRequests = false;

    final receivedRequest = ReceivedFriendRequestModel.fromJson(jsonDecode(data['request']));
    if (data['isCreate'] != null && data['isCreate'] as bool == true) {
      receivedFriendRequests.add(receivedRequest);
      receivedFriendRequests.sort((a, b) => a.username.compareTo(b.username));
      hasNewRequests = true;
      UserPrefs.saveReceivedFriendRequests(receivedFriendRequests);
      UserPrefs.saveHasNewRequest(true);
    } else if (data['isDelete'] != null && data['isDelete'] as bool == true) {
      receivedFriendRequests.removeWhere((request) => request.uid == receivedRequest.uid);
      hasNewRequests = true;
      UserPrefs.saveReceivedFriendRequests(receivedFriendRequests);
      UserPrefs.saveHasNewRequest(true);
    }

    return Pair(receivedFriendRequests, hasNewRequests);
  }

  static Future<void> saveHasNewRequest(bool hasNewRequest) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('hasNewRequest', hasNewRequest);
  }

  static Future<bool> getHasNewRequest() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('hasNewRequest') ?? false;
  }

  static Future<void> saveChats(List<ChatModel> chats) async {
    final prefs = await UserPrefs._getPrefs();
    List<String> chatsList = chats.map((chat) => jsonEncode(chat.toJson())).toList();
    await prefs.setStringList('chats', chatsList);
  }

  static Future<List<ChatModel>> getChats() async {
    final prefs = await UserPrefs._getPrefs();
    List<String>? chatJsonList = prefs.getStringList('chats');
    if (chatJsonList == null) return [];

    return chatJsonList
        .map((chatJson) => ChatModel.fromJson(jsonDecode(chatJson)))
        .toList();
  }

  static Future<void> saveIsLoadUser(bool isLoad) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('isLoadUser', isLoad);
  }

  static Future<bool?> getIsLoadUser() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('isLoadUser');
  }

  static Future<void> saveIsLoadFriend(bool isLoad) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('isLoadFriend', isLoad);
  }

  static Future<bool?> getIsLoadFriend() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('isLoadFriend');
  }

  static Future<void> saveIsLoadSentRequest(bool isLoad) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('isLoadUser', isLoad);
  }

  static Future<bool?> getIsLoadSentRequest() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('isLoadSentRequest');
  }

  static Future<void> saveIsLoadReceivedRequest(bool isLoad) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('isLoadReceivedRequest', isLoad);
  }

  static Future<bool?> getIsLoadReceivedRequest() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('isLoadReceivedRequest');
  }

  static Future<void> saveIsLoadChat(bool isLoad) async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.setBool('isLoadChat', isLoad);
  }

  static Future<bool?> getIsLoadChat() async {
    final prefs = await UserPrefs._getPrefs();
    return prefs.getBool('isLoadChat');
  }

  static Future<void> logout() async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.clear();
  }
}