import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class StatusTile extends StatelessWidget {
  final SentFriendRequest request;
  final Function onCancel;
  final Function onClose;

  const StatusTile({super.key, required this.request, required this.onCancel, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: lightBlueColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: switch (request.status) {
          'Pending...' => const Icon(Icons.hourglass_top, color: Colors.grey),
          'Approved'   => const Icon(Icons.check_circle, color: Colors.green),
          'Rejected'   => const Icon(Icons.cancel, color: Colors.red),
          _            => const Icon(Icons.help_outline),
        },
        title: Text(
          request.user.username,
          style: const TextStyle(color: strongBlueColor),
        ),
        subtitle: Text(
          request.status,
          style: const TextStyle(color: strongBlueColor),
        ),
        trailing: switch (request.status) {
          'Pending...' => TextButton(
            onPressed: () async {
              await onCancel();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Cancel', style: TextStyle(color: Colors.red)),
                SizedBox(width: 4),
                Icon(Icons.close, color: Colors.red),
              ],
            ),
          ),
          _ => TextButton(
            onPressed: () async {
              await onClose();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Close', style: TextStyle(color: Colors.grey)),
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