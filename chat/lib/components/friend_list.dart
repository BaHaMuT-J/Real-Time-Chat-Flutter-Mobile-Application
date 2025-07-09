import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class FriendsList extends StatelessWidget {
  final List<UserModel> friends;
  final Future<void> Function(UserModel friend)? onUnfriend;

  const FriendsList({
    super.key,
    required this.friends,
    this.onUnfriend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends.map((friend) => Column(
        children: [
          ListTile(
            leading: ProfileAvatar(imagePath: friend.profileImageUrl),
            title: Text(
              friend.username,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: strongBlueColor,
              ),
            ),
            subtitle: Text(
              friend.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: weakBlueColor,
              ),
            ),
            trailing: TextButton.icon(
              onPressed: onUnfriend != null ? () => onUnfriend!(friend) : null,
              icon: const Icon(Icons.person_remove, color: Colors.red, size: 20),
              label: const Text(
                "Unfriend",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0), // shrink
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const Divider(),
        ],
      )).toList(),
    );
  }
}
