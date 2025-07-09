class UserModel {
  final String uid;
  final String username;
  final String description;
  final String profileImageUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.description,
    required this.profileImageUrl,
  });

  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, description: $description, profileImageUrl: $profileImageUrl)';
  }

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      username: data['username'],
      description: data['description'] ?? "No description yet.",
      profileImageUrl: data['profileImageUrl'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'description': description,
      'profileImageUrl': profileImageUrl,
    };
  }
}