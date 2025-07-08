import 'dart:io';

import 'package:flutter/material.dart';

class EditProfileSheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final String? pickedImagePath;
  final Function onImagePick;
  final Function onSave;

  const EditProfileSheet({
    super.key,
    required this.nameController,
    required this.descController,
    this.pickedImagePath,
    required this.onImagePick,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              await onImagePick();
            },
            child: CircleAvatar(
              radius: 40,
              backgroundImage: pickedImagePath != null
                  ? FileImage(File(pickedImagePath!))
                  : null,
              child: pickedImagePath == null
                  ? const Icon(Icons.add_a_photo, size: 30)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: "Description"),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await onSave();
            },
            child: const Text("Save"),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
