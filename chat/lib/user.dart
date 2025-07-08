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

  static Future<void> logout() async {
    final prefs = await UserPrefs._getPrefs();
    await prefs.clear();
  }
}