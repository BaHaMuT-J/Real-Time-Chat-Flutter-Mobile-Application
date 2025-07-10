import 'dart:io';

import 'package:flutter/material.dart';

class EditProfileSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final String? pickedImagePath;
  final Future<String?> Function() onImagePick;
  final Future<void> Function() onSave;
  final String? initialImagePath;

  const EditProfileSheet({
    super.key,
    required this.nameController,
    required this.descController,
    this.pickedImagePath,
    required this.onImagePick,
    required this.onSave,
    this.initialImagePath,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late String? pickedImagePath;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    pickedImagePath = widget.initialImagePath ?? widget.pickedImagePath;
  }

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
              final path = await widget.onImagePick();
              if (path != null) {
                setState(() {
                  pickedImagePath = path;
                });
              }
            },
            child: CircleAvatar(
              radius: 40,
              backgroundImage: pickedImagePath != null && pickedImagePath!.isNotEmpty
                  ? pickedImagePath!.startsWith('http')
                  ? NetworkImage(pickedImagePath!)
                  : FileImage(File(pickedImagePath!)) as ImageProvider
                  : null,
              child: pickedImagePath == null || pickedImagePath!.isEmpty
                  ? const Icon(Icons.add_a_photo, size: 30)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.nameController,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          TextField(
            controller: widget.descController,
            decoration: const InputDecoration(labelText: "Description"),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
              setState(() {
                isSaving = true;
              });
              try {
                await widget.onSave();
              } finally {
                if (mounted) {
                  setState(() {
                    isSaving = false;
                  });
                }
              }
            },
            child: isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text("Save"),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
