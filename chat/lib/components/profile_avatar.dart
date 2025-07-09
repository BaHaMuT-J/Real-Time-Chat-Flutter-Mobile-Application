import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imagePath.isNotEmpty ? FileImage(File(imagePath)) : null,
      child: imagePath.isEmpty ? Icon(Icons.person, size: radius) : null,
    );
  }
}
