import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/view/component/auto_send_readiness_card.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

class UserPermissionPrepBody extends StatelessWidget {
  final AutoSendReadiness readiness;

  const UserPermissionPrepBody({super.key, required this.readiness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      children: [
        AutoSendReadinessCard(readiness: readiness, onTap: () {}),
        SizedBox(height: 20.h),
        Text('자동 전송이란?', style: Theme.of(context).textTheme.headlineSmall),
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
          description: '자동 전송을 사용하려면 도착 알림이 앱 밖에서도 위치를 확인할 수 있어야 해요.',
          statusLabel: readiness.locationStatusLabel,
          actionLabel: readiness.isLocationServiceDisabled ? '위치 서비스 켜기' : '위치 설정 열기',
          onTap: () => AppRoutes.pushLocationPermissionGuide(context),
        ),
        SizedBox(height: 12.h),
        PrepStatusTile(
          title: '배터리 최적화 제외',
          description: '앱이 꺼져 있어도 자동 전송이 중간에 끊기지 않게 준비해요.',
          statusLabel: Platform.isAndroid ? readiness.batteryStatusLabel : '해당 없음',
          actionLabel: Platform.isAndroid ? '배터리 설정 열기' : '확인',
          onTap: Platform.isAndroid
              ? () => AppRoutes.pushBatteryOptimizationGuide(context)
              : () => Navigator.of(context).maybePop(),
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

  const PrepStatusTile({
    super.key,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.actionLabel,
    required this.onTap,
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
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
              Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.primary,
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
            child: FilledButton.tonal(onPressed: onTap, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
