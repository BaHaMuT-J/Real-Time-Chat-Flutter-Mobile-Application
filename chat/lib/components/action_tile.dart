import 'package:chat/constant.dart';
import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ActionTile({
    super.key,
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: lightBlueColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.person_add, color: Colors.green),
        title: Text(
          user.username,
          style: const TextStyle(color: strongBlueColor),
        ),
        subtitle: Text(
          user.description,
          style: const TextStyle(color: strongBlueColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onApprove,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onReject,
            ),
          ],
        ),
      ),
    );
  }
}
