import 'package:chat/model/received_friend_request_model.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:flutter/material.dart';
import 'package:chat/components/received_request_tile.dart';
import 'package:chat/components/sent_request_tile.dart';
import 'package:chat/constant.dart';

class FriendRequestsSheet extends StatelessWidget {
  final List<SentFriendRequestModel>? sentRequests;
  final List<ReceivedFriendRequestModel>? receivedRequests;
  final Future<void> Function(String uid) onCancelSent;
  final Future<void> Function(String uid) onCloseSent;
  final Future<void> Function(String uid) onApproveReceived;
  final Future<void> Function(String uid) onRejectReceived;
  final double fontSize;
  final ThemeColors color;

  const FriendRequestsSheet({
    super.key,
    required this.sentRequests,
    required this.receivedRequests,
    required this.onCancelSent,
    required this.onCloseSent,
    required this.onApproveReceived,
    required this.onRejectReceived,
    required this.fontSize,
    required this.color,
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
            fontSize: fontSize,
            color: color,
          ))
              .toList()
              : [
            Text(
              "You have no sent friend request",
              style: TextStyle(fontSize: 14 + fontSize, fontWeight: FontWeight.w500, color: color.colorShade1),
            )
          ]
              : [_loading()]
          ),
          const SizedBox(height: 16),
          _subTitle("Received"),
          ...(receivedRequests != null
              ? receivedRequests!.isNotEmpty
              ? receivedRequests!.map((request) => ReceivedFriendRequestTile(
            request: request,
            onApprove: () async {
              await onApproveReceived(request.uid);
            },
            onReject: () async {
              await onRejectReceived(request.uid);
            },
            fontSize: fontSize,
            color: color,
          ))
              .toList()
              : [
            Text(
              "You have no received friend request",
              style: TextStyle(fontSize: 14 + fontSize, fontWeight: FontWeight.w500, color: color.colorShade1),
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
    style: TextStyle(fontSize: 20 + fontSize, fontWeight: FontWeight.bold, color: color.colorShade1),
  );
  Widget _subTitle(String subtitle) => Text(
    subtitle,
    style: TextStyle(fontSize: 16 + fontSize, fontWeight: FontWeight.w600, color: color.colorShade2),
  );
  Widget _loading() => const Center(child: CircularProgressIndicator());
}
