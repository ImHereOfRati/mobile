import 'package:flutter/material.dart';
import 'package:iamhere/core/router/app_routes.dart';

enum MemberState {
  newUser,
  existingUser;

  void navigate(BuildContext context) {
    final routes = <MemberState, void Function(BuildContext)>{
      MemberState.newUser: AppRoutes.goToTermsConsent,
      MemberState.existingUser: AppRoutes.goToGeofence,
    };

    routes[this]?.call(context);
  }
}
