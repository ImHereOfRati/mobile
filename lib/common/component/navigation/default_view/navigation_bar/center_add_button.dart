import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

import 'center_add_action_resolver.dart';

class CenterAddButton extends ConsumerWidget {
  const CenterAddButton({
    super.key,
    required this.onAuthorizedTap,
    required this.onUnauthorizedTap,
  });

  static const _permissionRequiredMessage =
      '추가를 위해 위치 권한이 필요해요';

  final void Function(BuildContext context) onAuthorizedTap;
  final Future<void> Function(BuildContext context) onUnauthorizedTap;

  static const _actionResolver = CenterAddActionResolver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context, ref),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, size: 22.r, color: cs.onPrimary),
          ),
          SizedBox(height: 2.h),
          Text('추가', style: AppTextStyles.smallGreyDescription(cs)),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final service = ref.read(locationPermissionServiceProvider);
    final status = await service.checkPermissionStatus();
    if (!context.mounted) return;

    switch (_actionResolver.resolve(status)) {
      case CenterAddAction.enroll:
        onAuthorizedTap(context);
      case CenterAddAction.showPermissionGuide:
        AppSnackBar.showError(context, _permissionRequiredMessage);
        await onUnauthorizedTap(context);
    }
  }
}
