import 'dart:io';

import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class FriendsList extends StatelessWidget {
  final List<UserModel> friends;

  const FriendsList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends.map((friend) => ListTile(
        leading: CircleAvatar(
          backgroundImage: friend.profileImageUrl.isNotEmpty ? FileImage(File(friend.profileImageUrl)) : null,
          child: friend.profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(
          friend.username
        ),
      )).toList(),
    );
  }
}
