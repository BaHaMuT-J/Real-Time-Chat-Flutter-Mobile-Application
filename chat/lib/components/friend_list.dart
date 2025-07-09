import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class FriendsList extends StatelessWidget {
  final List<UserModel> friends;

  const FriendsList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends.map((friend) => ListTile(
        leading: ProfileAvatar(
          imagePath: friend.profileImageUrl,
        ),
        title: Text(friend.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: strongBlueColor)),
        subtitle: Text(friend.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: weakBlueColor)),
      )).toList(),
    );
  }
}
