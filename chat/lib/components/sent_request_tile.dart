import 'package:chat/components/profile_avatar.dart';
import 'package:chat/constant.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:flutter/material.dart';

class SentFriendRequestTile extends StatefulWidget {
  final SentFriendRequestModel request;
  final Future<void> Function() onCancel;
  final Future<void> Function() onClose;
  final double fontSize;

  const SentFriendRequestTile({
    super.key,
    required this.request,
    required this.onCancel,
    required this.onClose,
    required this.fontSize,
  });

  @override
  State<SentFriendRequestTile> createState() => _SentFriendRequestTileState();
}

class _SentFriendRequestTileState extends State<SentFriendRequestTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: lightBlueColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: SizedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              switch (widget.request.status) {
                'Pending...' => const Icon(Icons.hourglass_top, color: Colors.grey),
                'Accepted'   => const Icon(Icons.check_circle, color: Colors.green),
                'Rejected'   => const Icon(Icons.cancel, color: Colors.red),
                _            => const Icon(Icons.help_outline),
              },
              const SizedBox(width: 8),
              ProfileAvatar(
                imagePath: widget.request.user.profileImageUrl,
              ),
            ],
          ),
        ),
        title: Text(
          widget.request.user.username,
          style: TextStyle(color: strongBlueColor, fontSize: 14 + widget.fontSize),
        ),
        subtitle: Text(
          widget.request.status,
          style: TextStyle(color: strongBlueColor, fontSize: 14 + widget.fontSize),
        ),
        trailing: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : switch (widget.request.status) {
          'Pending...' => TextButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await widget.onCancel();
              if (mounted) setState(() => _isLoading = false);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 14 + widget.fontSize)),
                SizedBox(width: 4),
                Icon(Icons.close, color: Colors.red),
              ],
            ),
          ),
          _ => TextButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await widget.onClose();
              if (mounted) setState(() => _isLoading = false);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Close', style: TextStyle(color: Colors.grey, fontSize: 14 + widget.fontSize)),
                SizedBox(width: 4),
                Icon(Icons.close, color: Colors.grey),
              ],
            ),
          ),
        },
      ),
    );
  }
}
