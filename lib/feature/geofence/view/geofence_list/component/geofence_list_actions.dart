import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/component/dialog/app_confirm_dialog.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository_provider.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/geofence_enroll_view.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/feature/user_permission/view_model/location_permission_gate.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

const String enrollFailurePrefix = '등록 실패: ';
const String deleteDialogTitle = '도착 알림 삭제';
const String deleteDialogSuffix = ' 알림을 삭제하시겠습니까?';

LocationPermissionGate _permissionGate(WidgetRef ref) {
  return LocationPermissionGate(ref.read(locationPermissionServiceProvider));
}

Future<void> handleCreateNew(BuildContext context, WidgetRef ref) async {
  final canEnroll = await _permissionGate(ref).resolveForCreate();
  if (!context.mounted) return;
  if (canEnroll) {
    context.push(AppRoutes.geofenceEnroll);
  } else {
    await AppRoutes.pushLocationPermissionGuide(context);
  }
}

Future<void> handleEdit(BuildContext context, WidgetRef ref, GeofenceEntity geofence) async {
  final srvRepo = ref.read(geofenceServerRecipientLocalRepositoryProvider);
  final srvRecipients = await srvRepo.findByGeofenceId(geofence.id!);
  if (!context.mounted) return;

  final serverRecipients = srvRecipients
      .map(
        (s) => ServerRecipient(
          friendRelationshipId: s.friendRelationshipId,
          friendEmail: s.friendEmail,
          friendAlias: s.friendAlias,
        ),
      )
      .toList();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => GeofenceEnrollView(
      geofence: geofence,
      serverRecipients: serverRecipients,
    ),
  );
  ref.read(geofenceListViewModelProvider.notifier).refresh();
}

Future<void> handleToggle(BuildContext context, WidgetRef ref, GeofenceEntity geofence, bool newValue) async {
  if (geofence.id == null) return;
  if (newValue && !(await _permissionGate(ref).ensureAlways(context))) return;

  try {
    await ref.read(geofenceListViewModelProvider.notifier).toggleActive(geofence.id!, newValue);
  } catch (e) {
    if (context.mounted) AppSnackBar.showError(context, '$enrollFailurePrefix$e');
  }
}

Future<void> handleDelete(BuildContext context, WidgetRef ref, GeofenceEntity geofence) async {
  final cs = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmDialog(
      title: deleteDialogTitle,
      content: '${geofence.name}$deleteDialogSuffix',
      confirmText: '삭제',
      confirmTextColor: cs.error,
    ),
  );

  if (confirmed != true || !context.mounted) return;
  await ref.read(geofenceListViewModelProvider.notifier).delete(geofence.id!);
}
