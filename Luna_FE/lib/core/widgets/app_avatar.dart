import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.label,
    this.imageUrl,
    this.radius = 24,
    super.key,
  });

  final String label;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: CircleAvatar(
      radius: radius,
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: imageUrl == null
          ? Text(label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase())
          : null,
    ),
  );
}
