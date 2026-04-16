import 'package:flutter/material.dart';

class PermissionItem {
  final String title;
  final IconData icon;
  final String shortDesc;
  final String detailedDesc;
  final bool isRequired;
  final bool isGranted;

  const PermissionItem({
    required this.title,
    required this.icon,
    required this.shortDesc,
    required this.detailedDesc,
    required this.isRequired,
    this.isGranted = false,
  });

  PermissionItem copyWith({bool? isGranted}) {
    return PermissionItem(
      title: title,
      icon: icon,
      shortDesc: shortDesc,
      detailedDesc: detailedDesc,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}
