import 'package:flutter/material.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

enum MemberState {
  newUser,
  existingUser,
  pending;

  void navigate(BuildContext context) {
    final routes = <MemberState, void Function(BuildContext)>{
      MemberState.newUser: AppRoutes.goToTermsConsent,
      MemberState.existingUser: AppRoutes.goToGeofence,
      MemberState.pending: AppRoutes.goToTermsConsent,
    };

    routes[this]?.call(context);
  }
}
