import 'package:flutter/material.dart';

class FriendsList extends StatelessWidget {
  final List<String> friends;

  const FriendsList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends.map((friend) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(friend),
      )).toList(),
    );
  }
}
