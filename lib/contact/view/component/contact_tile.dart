import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/util/phone_number_formatter.dart';

/// 친구 목록 한 행. status가 null이면 우측 상태 텍스트 미표시.
class ContactTile extends StatelessWidget {
  final String contactName;
  final String phoneNumber;
  final String? status; // e.g. '내 기기', 'Imhere', '탈퇴한 회원'
  final VoidCallback? onDelete;

  const ContactTile({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    this.status,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isMyDevice = status == '내 기기';
    final bool isImhere = status == 'Imhere';
    final bool isDeactivated = status == '탈퇴한 회원';

    Color statusColor;
    if (isImhere) {
      statusColor = cs.primary;
    } else if (isDeactivated) {
      statusColor = cs.onSurface.withValues(alpha: 0.38);
    } else {
      statusColor = cs.onSurface.withValues(alpha: 0.55);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactName,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDeactivated
                        ? cs.onSurface.withValues(alpha: 0.38)
                        : cs.onSurface,
                  ),
                ),
                if (isMyDevice && phoneNumber.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    convertToPhoneNumber(phoneNumber),
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 12.sp,
                      color: cs.primary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (status != null)
            Text(
              status!,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                color: statusColor,
                fontWeight: isImhere ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}
