import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';

class SelectedChipRow extends StatelessWidget {
  final Set<String> selectedKeys;
  final List<Recipient> all;
  final void Function(String) onToggle;

  const SelectedChipRow({
    super.key,
    required this.selectedKeys,
    required this.all,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final selected = all.where((r) => selectedKeys.contains(r.selectionKey)).toList();

    return AnimatedContainer(
      height: selected.isEmpty ? 0 : 52.h,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: selected.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: selected.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (_, i) => InputChip(
                label: Text(selected[i].displayName),
                onDeleted: () => onToggle(selected[i].selectionKey),
                deleteIcon: Icon(Icons.close, size: 16.sp),
              ),
            ),
    );
  }
}
