import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/view/component/auto_send_readiness_card.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

class UserPermissionPrepBody extends StatelessWidget {
  final AutoSendReadiness readiness;
  final VoidCallback onContinue;

  const UserPermissionPrepBody({
    super.key,
    required this.readiness,
    required this.onContinue,
  });

  Widget _buildTopBanner(ColorScheme cs) {
    if (readiness.isReady) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSecondaryContainer, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '지금 설정해야 자동 전송을 쓸 수 있어요',
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      children: [
        _buildTopBanner(cs),
        AutoSendReadinessCard(readiness: readiness),
        SizedBox(height: 20.h),
        Text('자동 알림이란?', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 8.h),
        Text(
          '앱이 닫혀 있거나 화면이 꺼져 있어도 도착한 순간을 감지해 자동으로 알려주는 기능이에요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.78),
          ),
        ),
        SizedBox(height: 20.h),
        PrepStatusTile(
          title: '위치 항상 허용',
          description: '자동 알림을 사용하려면 도착 알림이 앱 밖에서도 위치를 확인할 수 있어야 해요.',
          statusLabel: readiness.locationStatusLabel,
          actionLabel: readiness.isLocationServiceDisabled
              ? '위치 서비스 켜기'
              : '위치 설정 열기',
          onTap: () => AppRoutes.pushLocationPermissionGuide(context),
          isReady: !readiness.needsAlwaysLocation && !readiness.isLocationServiceDisabled,
        ),
        SizedBox(height: 12.h),
        PrepStatusTile(
          title: '배터리 최적화 제외',
          description: '앱이 꺼져 있어도 자동 알림이 중간에 끊기지 않게 준비해요.',
          statusLabel: Platform.isAndroid
              ? readiness.batteryStatusLabel
              : '해당 없음',
          actionLabel: Platform.isAndroid ? '배터리 설정 열기' : '확인',
          onTap: Platform.isAndroid
              ? () => AppRoutes.pushBatteryOptimizationGuide(context)
              : () => Navigator.of(context).maybePop(),
          isReady: !readiness.needsBatteryOptimization || !Platform.isAndroid,
        ),
        SizedBox(height: 20.h),
        FilledButton(
          onPressed: readiness.isReady ? onContinue : null,
          child: Text(
            readiness.isReady ? '준비 완료 후 계속하기' : '자동 전송 준비를 먼저 완료해 주세요',
          ),
        ),
      ],
    );
  }
}

class PrepStatusTile extends StatelessWidget {
  final String title;
  final String description;
  final String statusLabel;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isReady;

  const PrepStatusTile({
    super.key,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.actionLabel,
    required this.onTap,
    this.isReady = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isReady ? cs.primary : cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.76),
            ),
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
