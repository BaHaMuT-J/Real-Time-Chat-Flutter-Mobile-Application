import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatefulWidget {
  final String imagePath;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    this.radius = 20,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool get isNetworkImage => widget.imagePath.startsWith('http');
  bool get isLocalFile => widget.imagePath.isNotEmpty && !isNetworkImage;

  @override
  Widget build(BuildContext context) {
    debugPrint('Profile Avatar imagePath: ${widget.imagePath}');

    if (isLocalFile) {
      final file = File(widget.imagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingCircle();
          }
          if (snapshot.data == true) {
            return CircleAvatar(
              radius: widget.radius,
              backgroundImage: FileImage(file),
            );
          } else {
            return _placeholderCircle();
          }
        },
      );
    } else if (isNetworkImage) {
      return ClipOval(
        child: SizedBox(
          width: widget.radius * 2,
          height: widget.radius * 2,
          child: Image.network(
            widget.imagePath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _loadingCircle();
            },
            errorBuilder: (context, error, stackTrace) => _placeholderCircle(),
          ),
        ),
      );
    } else {
      return _placeholderCircle();
    }
  }

  Widget _loadingCircle() => CircleAvatar(
    radius: widget.radius,
    child: const CircularProgressIndicator(strokeWidth: 2),
  );

  Widget _placeholderCircle() => CircleAvatar(
    radius: widget.radius,
    child: Icon(Icons.person, size: widget.radius),
  );
}
