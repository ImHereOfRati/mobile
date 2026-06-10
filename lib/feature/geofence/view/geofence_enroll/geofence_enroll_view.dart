import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/feature/user_permission/view_model/auto_send_readiness_provider.dart';
import 'package:iamhere/feature/user_permission/view_model/location_permission_gate.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';

import '../map_select/component.dart';
import '../map_select/map_select_view.dart';
import '../recipient_select/recipient_select_view.dart';

const String _enrollFailure = '저장 실패: ';

class GeofenceEnrollView extends ConsumerStatefulWidget {
  final GeofenceEntity? geofence;
  final List<ServerRecipient>? serverRecipients;

  const GeofenceEnrollView({super.key, this.geofence, this.serverRecipients});

  @override
  ConsumerState<GeofenceEnrollView> createState() => _GeofenceEnrollViewState();
}

class _GeofenceEnrollViewState extends ConsumerState<GeofenceEnrollView> {
  final GlobalKey<EnrollInlineMapState> _mapRef = GlobalKey();

  /// '알림 더 만들기'로 폼을 초기화할 때 폼/컨트롤러를 새로 만들기 위한 키.
  int _formEpoch = 0;

  @override
  void initState() {
    super.initState();
    if (widget.geofence != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(geofenceEnrollViewModelProvider.notifier)
            .initializeWithGeofence(
              widget.geofence!,
              widget.serverRecipients ?? [],
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(geofenceEnrollViewModelProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: EnrollFormBody(
          key: ValueKey(_formEpoch),
          mapSection: EnrollInlineMap(
            key: _mapRef,
            initialSelectedLocation: formState.selectedLocation,
            onLocationPicked: (latlng) => ref
                .read(geofenceEnrollViewModelProvider.notifier)
                .updateLocation(latlng),
            onOpenMapSelect: _openMapSelect,
          ),
          onOpenRecipientSelect: _openRecipientSelect,
          onSave: _save,
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
    if (formState.isActive) {
      final gate =
          LocationPermissionGate(ref.read(locationPermissionServiceProvider));
      if (!await gate.ensureAlways(context)) return;
    }

    try {
      await ref.read(geofenceEnrollViewModelProvider.notifier).saveGeofence();
      ref.read(geofenceListViewModelProvider.notifier).refresh();
      if (mounted) {
        _showCompleteSheet();
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

  void _showCompleteSheet() {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    final readiness = ref.read(autoSendReadinessProvider);
    final isReady = readiness.isReady;

    showModalBottomSheet(
      context: context,
      builder: (_) => EnrollCompleteSheet(
        locationName: formState.name,
        eventType: formState.eventType,
        recipients: formState.selectedRecipients,
        isAutoSendReady: isReady,
        onEnableAutoSend: () {
          Navigator.pop(context); // Close bottom sheet
          AppRoutes.pushUserPermission(context);
        },
        onCreateAnother: () {
          Navigator.pop(context);
          ref.read(geofenceEnrollViewModelProvider.notifier).resetForm();
          setState(() => _formEpoch++);
        },
        onBackToMain: () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.pop(context); // Close enrollment view
        },
      ),
    );
  }
}
