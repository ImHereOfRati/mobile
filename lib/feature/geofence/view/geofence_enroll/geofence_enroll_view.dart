import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/enroll_form_body.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/map/enroll_inline_map.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/shared/base/snack_bar/app_snack_bar.dart';

import '../map_select/map_select_view.dart';
import '../map_select/component/map_select_widgets.dart';
import '../recipient_select/recipient_select_view.dart';

const String _enrollSuccess = '지오펜스가 저장되었습니다';
const String _enrollFailure = '저장 실패: ';

class GeofenceEnrollView extends ConsumerStatefulWidget {
  final GeofenceEntity? geofence;
  final List<ServerRecipient>? serverRecipients;

  const GeofenceEnrollView({
    super.key,
    this.geofence,
    this.serverRecipients,
  });

  @override
  ConsumerState<GeofenceEnrollView> createState() => _GeofenceEnrollViewState();
}

class _GeofenceEnrollViewState extends ConsumerState<GeofenceEnrollView> {
  final GlobalKey<EnrollInlineMapState> _mapRef = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.geofence != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(geofenceEnrollViewModelProvider.notifier).initializeWithGeofence(
              widget.geofence!,
              widget.serverRecipients ?? [],
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(geofenceEnrollViewModelProvider);
    final isEditMode = widget.geofence != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '지오펜스 수정' : '지오펜스 등록'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EnrollInlineMap(
              key: _mapRef,
              initialSelectedLocation: formState.selectedLocation,
              onLocationPicked: (latlng) => ref
                  .read(geofenceEnrollViewModelProvider.notifier)
                  .updateLocation(latlng),
              onOpenMapSelect: _openMapSelect,
            ),
            EnrollFormBody(
              onOpenRecipientSelect: _openRecipientSelect,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapSelect() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    final result = await Navigator.of(context).push<MapSelectResult>(
      MaterialPageRoute(
        builder: (_) =>
            MapSelectView(initialLocation: formState.selectedLocation),
      ),
    );
    if (result != null) {
      _mapRef.currentState?.moveTo(result.location);
      ref
          .read(geofenceEnrollViewModelProvider.notifier)
          .updateAddress(result.address);
    }
  }

  Future<void> _openRecipientSelect() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    final result = await Navigator.of(context).push<List<Recipient>>(
      MaterialPageRoute(
        builder: (_) => RecipientSelectView(
          initialSelectedKeys: formState.selectedRecipients
              .map((r) => r.selectionKey)
              .toList(),
        ),
      ),
    );
    if (result != null) {
      ref
          .read(geofenceEnrollViewModelProvider.notifier)
          .updateRecipients(result);
    }
  }

  Future<void> _save() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    if (formState.isActive && !await _ensureAlwaysPermission()) return;

    try {
      await ref.read(geofenceEnrollViewModelProvider.notifier).saveGeofence();
      ref.read(geofenceListViewModelProvider.notifier).refresh();
      if (mounted) {
        AppSnackBar.showSuccess(context, _enrollSuccess);
        Navigator.of(context).pop();
      }
    } on MissingBackgroundLocationException {
      // 권한 사전 체크 후에도 사용자가 도중에 권한을 회수한 드문 케이스.
      if (!mounted) return;
      await AppRoutes.pushLocationPermissionGuide(context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '$_enrollFailure${e.toString()}');
      }
    }
  }

  Future<bool> _ensureAlwaysPermission() async {
    final service = ref.read(locationPermissionServiceProvider);
    final isAlways =
        await service.checkPermissionStatus() == PermissionState.grantedAlways;
    if (isAlways) return true;
    if (!mounted) return false;
    return await AppRoutes.pushLocationPermissionGuide(context);
  }
}
