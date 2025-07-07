import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static Future<void> saveUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> setProfile(String username, String description, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('description', description);
    if (imagePath != null) {
      await prefs.setString('profileImage', imagePath);
    }
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? "Username";
  }

  static Future<String?> getDescription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('description') ?? "No description yet.";
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImage');
  }
}
