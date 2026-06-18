import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/feature/user_permission/view_model/location_permission_gate.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

const String _emptyTitle = '깔끔';
const String _emptyDescription =
    '도착/출발할 때 소중한 사람에게 자동으로 연락해드려요.\n30초면 첫 알림을 만들 수 있어요.';
const String _createFirstAlert = '첫 알림 만들기';

/// 알림이 없을 때 첫 알림 생성을 유도하는 empty state.
class GeofenceEmptyState extends ConsumerWidget {
  const GeofenceEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 56.r,
              color: cs.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              _emptyTitle,
              style: AppTextStyles.gSansBold(50.sp, cs.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _emptyDescription,
              style: AppTextStyles.hannaAirRegular(16.sp, cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: () => _handleCreateTap(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _createFirstAlert,
                style: AppTextStyles.hannaAirBold(14, cs.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateTap(BuildContext context, WidgetRef ref) async {
    final gate = LocationPermissionGate(
      ref.read(locationPermissionServiceProvider),
    );
    final canEnroll = await gate.resolveForCreate();
    if (!context.mounted) return;

    if (canEnroll) {
      context.push(AppRoutes.geofenceEnroll);
    } else {
      await AppRoutes.pushLocationPermissionGuide(context);
    }
  }
}
