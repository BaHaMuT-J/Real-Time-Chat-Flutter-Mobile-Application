import 'package:chat/model/user_model.dart';
import 'package:chat/components/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:chat/constant.dart';
import 'package:chat/services/firestore.dart';

class AddFriendSheet extends StatefulWidget {
  final VoidCallback onRequestSent;

  const AddFriendSheet({super.key, required this.onRequestSent});

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
                  style: ElevatedButton.styleFrom(backgroundColor: strongBlueColor),
                  onPressed: _performSearch,
                  child: const Text("Search", style: TextStyle(color: Colors.white)),
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
                            title: Text(user.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: strongBlueColor)),
                            subtitle: Text(user.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: weakBlueColor)),
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
                                  icon: const Icon(Icons.person_add, color: strongBlueColor),
                                  onPressed: () async {
                                    setState(() {
                                      loadingRequests.add(user.uid);
                                    });
                                    await FirestoreService().sendFriendRequest(user.uid);
                                    setState(() {
                                      localSentRequests.add(user.uid);
                                      loadingRequests.remove(user.uid);
                                    });
                                    widget.onRequestSent();
                                  },
                                ),
                          );
                        }).toList(),
                        )
                        : const Text("No users found.", style: TextStyle(color: strongBlueColor, fontSize: 16, fontWeight: FontWeight.w600));
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
    // if (query.isEmpty) return; // Only search with query (not allow search all user)
    setState(() => isLoading = true);
    final results = await FirestoreService().searchUsers(query);
    searchResults.value = results;
    localSentRequests.clear();
    setState(() => isLoading = false);
  }

  Widget _searchInput() =>
      TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Search by username",
          labelStyle: const TextStyle(color: strongBlueColor),
          prefixIcon: const Icon(Icons.search, color: strongBlueColor),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: strongBlueColor)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: weakBlueColor, width: 2)),
        ),
        style: const TextStyle(color: strongBlueColor),
        cursorColor: strongBlueColor,
      );
}
