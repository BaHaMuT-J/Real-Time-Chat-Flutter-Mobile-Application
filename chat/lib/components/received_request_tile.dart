import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:chat/model/received_friend_request_model.dart';
import 'package:flutter/material.dart';

class ReceivedFriendRequestTile extends StatefulWidget {
  final ReceivedFriendRequestModel request;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final double fontSize;
  final ThemeColors color;

  const ReceivedFriendRequestTile({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.fontSize,
    required this.color,
  });

  @override
  State<ReceivedFriendRequestTile> createState() => _ReceivedFriendRequestTileState();
}

class _ReceivedFriendRequestTileState extends State<ReceivedFriendRequestTile> {
  bool _isApproving = false;
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.colorShade3.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: ProfileAvatar(
          imagePath: widget.request.profileImageUrl,
        ),
        title: Text(
          widget.request.username,
          style: TextStyle(color: widget.color.colorShade1, fontSize: 14 + widget.fontSize),
        ),
        subtitle: Text(
          widget.request.description,
          style: TextStyle(color: widget.color.colorShade1, fontSize: 14 + widget.fontSize),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isApproving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                setState(() => _isApproving = true);
                await widget.onApprove();
                if (mounted) setState(() => _isApproving = false);
              },
            ),
            _isRejecting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () async {
                setState(() => _isRejecting = true);
                await widget.onReject();
                if (mounted) setState(() => _isRejecting = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
