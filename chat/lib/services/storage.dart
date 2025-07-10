import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(File file, String uid) async {
    final dirRef = _storage.ref().child('profile_images/$uid');

    // Upload new file
    final fileId = const Uuid().v4();
    final newRef = dirRef.child('$fileId.jpg');

    await newRef.putFile(file);
    final downloadUrl = await newRef.getDownloadURL();

    // Delete old files asynchronously, skipping the new one
    _deleteOldFiles(dirRef, excludeFileName: '$fileId.jpg');

    return downloadUrl;
  }

  void _deleteOldFiles(Reference dirRef, {required String excludeFileName}) async {
    try {
      final existingFiles = await dirRef.listAll();
      for (final item in existingFiles.items) {
        if (item.name != excludeFileName) {
          debugPrint('Deleting old file: ${item.fullPath}');
          item.delete(); // fire-and-forget
        }
      }
    } catch (e) {
      debugPrint('Error deleting old files: $e');
    }
  }
}
