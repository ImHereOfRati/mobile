import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

import 'enroll_recipient_chip.dart';

const String sectionRecipient = '어떤 친구에게 알려줄까요?';
const String addRecipient = '추가하기';
const String noRecipient = '아직 선택된 친구가 없어요';

class EnrollRecipientSection extends StatelessWidget {
  final List<Recipient> recipients;
  final VoidCallback onOpenSelect;

  const EnrollRecipientSection({
    super.key,
    required this.recipients,
    required this.onOpenSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionRecipient,
              style: AppTextStyles.gSansBold(15, cs.onSurface),
            ),
            GestureDetector(onTap: onOpenSelect, child: _addText(cs)),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 80.h),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: recipients.isEmpty ? _emptyBody(cs) : _chipsBody(),
        ),
      ],
    );
  }

  Widget _addText(ColorScheme cs) =>
      Text(addRecipient, style: AppTextStyles.hannaAirBold(13, cs.primary));

  Widget _emptyBody(ColorScheme cs) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(height: 20.h),
      Text(
        noRecipient,
        style: AppTextStyles.hannaAirRegular(
          13,
          cs.onSurface.withValues(alpha: 0.4),
        ),
      ),
      SizedBox(height: 4.h),
      GestureDetector(onTap: onOpenSelect, child: _addText(cs)),
      SizedBox(height: 20.h),
    ],
  );

  Widget _chipsBody() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
    child: Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      children: recipients
          .map((r) => EnrollRecipientChip(recipient: r))
          .toList(),
    ),
  );
}
