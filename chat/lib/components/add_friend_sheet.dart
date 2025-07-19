import 'package:chat/model/received_friend_request_model.dart';
import 'package:chat/model/sent_friend_request_model.dart';
import 'package:chat/model/user_model.dart';
import 'package:chat/components/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:chat/constant.dart';
import 'package:chat/services/user_firestore.dart';

class AddFriendSheet extends StatefulWidget {
  final Future<void> Function(SentFriendRequestModel sentRequest, ReceivedFriendRequestModel receivedRequest) onRequestSent;
  final double fontSize;
  final ThemeColors color;

  const AddFriendSheet({
    super.key,
    required this.onRequestSent,
    required this.fontSize,
    required this.color,
});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<List<UserModel>> searchResults = ValueNotifier([]);
  Set<String> loadingRequests = {};
  Set<String> localSentRequests = {};
  bool isLoading = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _searchInput(),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: widget.color.colorShade1),
                  onPressed: _performSearch,
                  child: Text("Search", style: TextStyle(color: Colors.white, fontSize: 14 + widget.fontSize)),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ValueListenableBuilder<List<UserModel>>(
                    valueListenable: searchResults,
                    builder: (_, users, __) {
                      return users.isNotEmpty
                          ? Column(
                        children: users.map((user) {
                          final isSent = localSentRequests.contains(user.uid);
                          return ListTile(
                            leading: ProfileAvatar(
                              imagePath: user.profileImageUrl,
                            ),
                            title: Text(user.username, style: TextStyle(fontSize: 18 + widget.fontSize, fontWeight: FontWeight.bold, color: widget.color.colorShade1)),
                            subtitle: Text(user.description, style: TextStyle(fontSize: 16 + widget.fontSize, fontWeight: FontWeight.w600, color: widget.color.colorShade2)),
                            trailing: isSent
                              ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                  "Sent",
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                ),
                              )
                              : loadingRequests.contains(user.uid)
                                ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                : IconButton(
                                  icon: Icon(Icons.person_add, color: widget.color.colorShade1),
                                  onPressed: () async {
                                    setState(() {
                                      loadingRequests.add(user.uid);
                                    });
                                    final pair = await UserFirestoreService().sendFriendRequest(user.uid);
                                    final sentRequest = pair.first;
                                    final receivedRequest = pair.second;
                                    setState(() {
                                      localSentRequests.add(user.uid);
                                      loadingRequests.remove(user.uid);
                                    });
                                    widget.onRequestSent(sentRequest, receivedRequest);
                                  },
                                ),
                          );
                        }).toList(),
                        )
                        : Text("No users found.", style: TextStyle(color: widget.color.colorShade1, fontSize: 16 + widget.fontSize, fontWeight: FontWeight.w600));
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return; // Only search with query (not allow search all user)
    setState(() => isLoading = true);
    final results = await UserFirestoreService().searchUsers(query);
    searchResults.value = results;
    localSentRequests.clear();
    setState(() => isLoading = false);
  }

  Widget _searchInput() =>
      TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Search by username",
          labelStyle: TextStyle(color: widget.color.colorShade1),
          prefixIcon: Icon(Icons.search, color: widget.color.colorShade1),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.color.colorShade1)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.color.colorShade2, width: 2)),
        ),
        style: TextStyle(color: widget.color.colorShade1),
        cursorColor: widget.color.colorShade1,
      );
}
