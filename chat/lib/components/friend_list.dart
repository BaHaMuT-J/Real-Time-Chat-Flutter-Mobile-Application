import 'package:chat/model/user_model.dart';
import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class FriendsList extends StatefulWidget {
  final List<UserModel> friends;
  final Future<void> Function(UserModel friend)? onUnfriend;

  const FriendsList({
    super.key,
    required this.friends,
    this.onUnfriend,
  });

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final Set<String> _loadingFriendIds = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.friends.map((friend) {
        final isLoading = _loadingFriendIds.contains(friend.uid);
        return Column(
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
              trailing: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : TextButton.icon(
                onPressed: widget.onUnfriend != null
                    ? () async {
                  setState(() {
                    _loadingFriendIds.add(friend.uid);
                  });
                  await widget.onUnfriend!(friend);
                  if (mounted) {
                    setState(() {
                      _loadingFriendIds.remove(friend.uid);
                    });
                  }
                }
                    : null,
                icon: const Icon(Icons.person_remove, color: Colors.red, size: 20),
                label: const Text(
                  "Unfriend",
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}
