import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/enroll_form_body.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/enroll_inline_map.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/shared/base/snack_bar/app_snack_bar.dart';

import '../map_select/map_select_view.dart';
import '../map_select/component/map_select_widgets.dart';
import '../recipient_select/recipient_select_view.dart';

const String _enrollSuccess = '지오펜스가 등록되었습니다';
const String _enrollFailure = '등록 실패: ';

class GeofenceEnrollView extends ConsumerStatefulWidget {
  const GeofenceEnrollView({super.key});

  @override
  ConsumerState<GeofenceEnrollView> createState() => _GeofenceEnrollViewState();
}

class _GeofenceEnrollViewState extends ConsumerState<GeofenceEnrollView> {
  final GlobalKey<EnrollInlineMapState> _mapRef = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(geofenceEnrollViewModelProvider);

    return SingleChildScrollView(
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
    try {
      await ref.read(geofenceEnrollViewModelProvider.notifier).saveGeofence();
      ref.read(geofenceListViewModelProvider.notifier).refresh();
      if (mounted) {
        AppSnackBar.showSuccess(context, _enrollSuccess);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '$_enrollFailure${e.toString()}');
      }
    }
  }
}
