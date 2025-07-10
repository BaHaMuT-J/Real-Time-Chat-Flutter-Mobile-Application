import 'dart:convert';

import 'package:chat/model/chat_model.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
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

  static Future<void> saveReceivedFriendRequests(List<UserModel> users) async {
    final prefs = await UserPrefs._getPrefs();
    List<String> userJsonList = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('receivedRequestsList', userJsonList);
  }

  static Future<List<UserModel>> getReceivedFriendRequests() async {
    final prefs = await UserPrefs._getPrefs();
    List<String>? userJsonList = prefs.getStringList('receivedRequestsList');
    if (userJsonList == null) return [];

    return userJsonList
        .map((userJson) => UserModel.fromJson(jsonDecode(userJson)))
        .toList();
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