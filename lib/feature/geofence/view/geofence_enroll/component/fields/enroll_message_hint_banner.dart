import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';

const String _smsNote = '운영 발송 미리보기\nSMS만 45자 제한이 적용됩니다.';

class EnrollMessageHintBanner extends StatelessWidget {
  final String locationName;
  final String locationAddress;
  final String senderName;

  const EnrollMessageHintBanner({
    super.key,
    required this.locationName,
    required this.locationAddress,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintTitle(cs),
          SizedBox(height: 8.h),
          Builder(
            builder: (context) {
              final location = composeFullLocation(locationName, locationAddress);
              final preview = composeSmsPreview(
                location: location,
                senderName: senderName,
              );
              final body = composeSmsBody(
                location: location,
                senderName: senderName,
              );
              final isOverLimit = body.length > smsBodyMaxLength;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isOverLimit
                            ? cs.error.withValues(alpha: 0.5)
                            : cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      preview,
                      style: AppTextStyles.hannaAirRegular(12, cs.onSurface),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'SMS 본문 ${body.length}/$smsBodyMaxLength',
                    style: AppTextStyles.hannaAirRegular(
                      11,
                      isOverLimit
                          ? cs.error
                          : cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  if (isOverLimit) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'SMS 본문이 45자를 넘으면 저장할 수 없어요.',
                      style: AppTextStyles.hannaAirRegular(11, cs.error),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Row _hintTitle(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.sms_outlined, size: 16.r, color: cs.tertiary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            _smsNote,
            style: AppTextStyles.hannaAirBold(12, cs.tertiary),
          ),
        ),
      ],
    );
  }

}
