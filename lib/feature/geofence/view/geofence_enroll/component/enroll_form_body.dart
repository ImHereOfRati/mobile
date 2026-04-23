import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart';

import 'radius/enroll_radius_section.dart';
import 'fields/enroll_activate_toggle.dart';
import 'enroll_check_card.dart';
import 'fields/enroll_message_field.dart';
import 'fields/enroll_name_field.dart';
import 'recipient/enroll_recipient_section.dart';
import 'enroll_save_button.dart';

class EnrollFormBody extends ConsumerStatefulWidget {
  final VoidCallback onOpenRecipientSelect;
  final VoidCallback onSave;

  const EnrollFormBody({
    super.key,
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
          EnrollRadiusBlock(
            selected: state.radius,
            infoMessage: state.radiusInfoMessage,
            onChanged: notifier.updateRadius,
          ),
          h20Box,
          EnrollNameField(controller: _nameController),
          h20Box,
          EnrollMessageField(controller: _messageController),
          h20Box,
          EnrollActivateToggle(
            isActive: state.isActive,
            onChanged: notifier.updateIsActive,
          ),
          SizedBox(height: 12.h),
          const EnrollCheckCard(),
          h20Box,
          EnrollRecipientSection(
            recipients: state.selectedRecipients,
            onOpenSelect: widget.onOpenRecipientSelect,
          ),
          SizedBox(height: 24.h),
          EnrollSaveButton(onPressed: widget.onSave),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
