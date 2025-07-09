import 'package:flutter/material.dart';
import 'package:chat/components/received_request_tile.dart';
import 'package:chat/components/sent_request_tile.dart';
import 'package:chat/constant.dart';

class FriendRequestsSheet extends StatelessWidget {
  final List<SentFriendRequest>? sentRequests;
  final List<UserModel>? receivedRequests;
  final Future<void> Function(String uid) onCancelSent;
  final Future<void> Function(String uid) onCloseSent;
  final Future<void> Function(String uid) onApproveReceived;
  final Future<void> Function(String uid) onRejectReceived;

  const FriendRequestsSheet({
    super.key,
    required this.sentRequests,
    required this.receivedRequests,
    required this.onCancelSent,
    required this.onCloseSent,
    required this.onApproveReceived,
    required this.onRejectReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          _sectionTitle("Friend Requests"),
          const SizedBox(height: 16),
          _subTitle("Sent"),
          ...(sentRequests != null
              ? sentRequests!.isNotEmpty
              ? sentRequests!.map((request) => SentFriendRequestTile(
            request: request,
            onCancel: () async {
              await onCancelSent(request.user.uid);
            },
            onClose: () async {
              await onCloseSent(request.user.uid);
            },
          ))
              .toList()
              : [
            Text(
              "You have no sent friend request",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: strongBlueColor),
            )
          ]
              : [_loading()]
          ),
          const SizedBox(height: 16),
          _subTitle("Received"),
          ...(receivedRequests != null
              ? receivedRequests!.isNotEmpty
              ? receivedRequests!.map((user) => ReceivedFriendRequestTile(
            user: user,
            onApprove: () async {
              await onApproveReceived(user.uid);
            },
            onReject: () async {
              await onRejectReceived(user.uid);
            },
          ))
              .toList()
              : [
            Text(
              "You have no received friend request",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: strongBlueColor),
            )
          ]
              : [_loading()]
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: strongBlueColor),
  );
  Widget _subTitle(String subtitle) => Text(
    subtitle,
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: weakBlueColor),
  );
  Widget _loading() => const Center(child: CircularProgressIndicator());
}
