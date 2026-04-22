import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/view/geofence_list/component/geofence_list_tile.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/shared/base/snack_bar/app_snack_bar.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';
import 'package:iamhere/shared/component/view_component/app_confirm_dialog.dart';
import 'package:iamhere/shared/component/view_component/loading_body.dart';
import 'package:iamhere/shared/component/view_component/sliver_message_view.dart';

const String _enrollFailure = '등록 실패: ';
const String _deleteDialogTitle = '지오펜스 삭제';
const String _deleteDialogSuffix = ' 지오펜스를 삭제하시겠습니까?';
const String _errorPrefix = '오류 발생: ';
const String _emptyListMessage = '등록된 지오펜스가 없습니다';

class GeofenceListBody extends ConsumerStatefulWidget {
  const GeofenceListBody({super.key});

  @override
  ConsumerState<GeofenceListBody> createState() => _GeofenceListBodyState();
}

class _GeofenceListBodyState extends ConsumerState<GeofenceListBody> {
  @override
  Widget build(BuildContext context) {
    final geofencesAsync = ref.watch(geofenceListViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return geofencesAsync.when(
      loading: () => const LoadingBody(),
      error: (err, _) => SliverMessageView(
        message: '$_errorPrefix$err',
        style: AppTextStyles.hannaAirRegular(16, cs.error),
      ),
      data: (geofences) {
        if (geofences.isEmpty) {
          return SliverMessageView(
            message: _emptyListMessage,
            style: AppTextStyles.hannaAirRegular(16, cs.onSurfaceVariant),
          );
        }

        return GeofenceListTile(
          geofences: geofences,
          onToggle: _handleToggle,
          onDelete: _handleDelete,
        );
      },
    );
  }

  void _handleToggle(GeofenceEntity geofence, bool newValue) async {
    if (geofence.id == null) return;
    if (newValue && !(await _ensureAlwaysPermission())) return;

    try {
      await ref
          .read(geofenceListViewModelProvider.notifier)
          .toggleActive(geofence.id!, newValue);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '$_enrollFailure$e');
    }
  }

  Future<bool> _ensureAlwaysPermission() async {
    final service = ref.read(locationPermissionServiceProvider);
    final isAlwaysPermission =
        await service.checkPermissionStatus() == PermissionState.grantedAlways;

    if (isAlwaysPermission) {
      return true;
    }

    if (!mounted) return false;

    return await AppRoutes.pushLocationPermissionGuide(context);
  }

  Future<void> _handleDelete(GeofenceEntity geofence) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: _deleteDialogTitle,
        content: '${geofence.name}$_deleteDialogSuffix',
        confirmText: '삭제',
        confirmTextColor: cs.error,
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(geofenceListViewModelProvider.notifier).delete(geofence.id!);
  }
}
