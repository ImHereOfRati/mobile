import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/view/component/user_permission_prep_components.dart';

class UserPermissionPrepOverlay extends ConsumerWidget {
  final AutoSendReadiness readiness;

  const UserPermissionPrepOverlay({super.key, required this.readiness});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Prevent dismissal by tapping outside
        child: Container(
          color: Colors.black54,
          child: Dialog(
            child: Scaffold(body: UserPermissionPrepBody(readiness: readiness)),
          ),
        ),
      ),
    );
  }
}
