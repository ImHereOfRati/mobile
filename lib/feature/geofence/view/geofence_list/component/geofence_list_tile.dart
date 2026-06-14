import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

import 'geofence_tile.dart';

const String _loadingAddress = '주소 불러오는 중...';
const String _createNewAlert = '새 알림 만들기';

class GeofenceListTile extends StatelessWidget {
  final List<GeofenceEntity> geofences;
  final bool isAutoSendReady;
  final Function(GeofenceEntity, bool) onToggle;
  final Function(GeofenceEntity) onDelete;
  final Function(GeofenceEntity) onEdit;
  final VoidCallback? onCreateNew;

  const GeofenceListTile({
    super.key,
    required this.geofences,
    required this.isAutoSendReady,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = geofences.length + (onCreateNew != null ? 1 : 0);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == geofences.length) {
            return _buildCreateTile(context);
          }

          final g = geofences[index];
          return GeofenceTile(
            key: ValueKey('${g.id}_${g.isActive}'), // ID와 활성 상태를 조합한 키 사용
            homeName: g.name,
            address: g.address.isNotEmpty ? g.address : _loadingAddress,
            eventType: g.eventType,
            memberCount: _parseCount(g.contactIds) + g.serverRecipientCount,
            isToggleOn: g.isActive,
            isAutoSendReady: isAutoSendReady,
            onToggleChanged: (val) => onToggle(g, val),
            onLongPress: () => onDelete(g),
            onTap: () => onEdit(g),
          );
        }, childCount: itemCount),
      ),
    );
  }

  Widget _buildCreateTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: OutlinedButton.icon(
        onPressed: onCreateNew,
        icon: Icon(Icons.add_rounded, size: 18.r, color: cs.primary),
        label: Text(
          _createNewAlert,
          style: AppTextStyles.hannaAirBold(14, cs.primary),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          side: BorderSide(
            color: cs.primary.withValues(alpha: 0.4),
            width: 1.2.r,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  int _parseCount(String json) {
    try {
      return (jsonDecode(json) as List).length;
    } catch (_) {
      return 0;
    }
  }
}
