import 'package:chat/model/user_model.dart';

class SentFriendRequestModel {
  final UserModel user;
  final String status;

  SentFriendRequestModel({
    required this.user,
    required this.status,
  });

  @override
  String toString() {
    return 'SentFriendRequest(user: $user, status: $status)';
  }

  factory SentFriendRequestModel.fromJson(Map<String, dynamic> data) {
    return SentFriendRequestModel(
      user: UserModel.fromJson(data['user']),
      status: data['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'status': status,
    };
  }
}