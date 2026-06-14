import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart';
import 'actions/enroll_action_section.dart';
import 'details/enroll_details_section.dart';
import 'location/enroll_location_section.dart';
import 'recipient/enroll_recipient_section.dart';
import 'event/enroll_event_section.dart';

class EnrollFormBody extends ConsumerStatefulWidget {
  final Widget mapSection;
  final VoidCallback onOpenRecipientSelect;
  final VoidCallback onSave;

  const EnrollFormBody({
    super.key,
    required this.mapSection,
    required this.onOpenRecipientSelect,
    required this.onSave,
  });

  @override
  ConsumerState<EnrollFormBody> createState() => _EnrollFormBodyState();
}

class _EnrollFormBodyState extends ConsumerState<EnrollFormBody> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onName);
    _messageController.addListener(_onMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(geofenceEnrollViewModelProvider);
      if (state.name.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = state.name;
      }
      if (state.message.isNotEmpty && _messageController.text.isEmpty) {
        _messageController.text = state.message;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onName() => ref
      .read(geofenceEnrollViewModelProvider.notifier)
      .updateName(_nameController.text);

  void _onMessage() => ref
      .read(geofenceEnrollViewModelProvider.notifier)
      .updateMessage(_messageController.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(geofenceEnrollViewModelProvider);
    final notifier = ref.read(geofenceEnrollViewModelProvider.notifier);
    final h20Box = SizedBox(height: 20.h);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EnrollRecipientSection(
            recipients: state.selectedRecipients,
            onOpenSelect: widget.onOpenRecipientSelect,
          ),
          h20Box,
          EnrollEventSection(
            selectedType: state.eventType,
            onChanged: notifier.updateEventType,
          ),
          h20Box,
          EnrollLocationSection(
            mapSection: widget.mapSection,
            selectedRadius: state.radius,
            radiusInfoMessage: state.radiusInfoMessage,
            onRadiusChanged: notifier.updateRadius,
          ),
          h20Box,
          EnrollDetailsSection(
            nameController: _nameController,
            messageController: _messageController,
            eventType: state.eventType,
            isActive: state.isActive,
            onActiveChanged: notifier.updateIsActive,
          ),
          h20Box,
          EnrollActionSection(onSave: widget.onSave),
        ],
      ),
    );
  }
}
