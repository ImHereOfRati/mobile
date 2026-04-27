import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

import 'geofence_tile.dart';

const String _loadingAddress = '주소 불러오는 중...';

class GeofenceListTile extends StatelessWidget {
  final List<GeofenceEntity> geofences;
  final Function(GeofenceEntity, bool) onToggle;
  final Function(GeofenceEntity) onDelete;
  final Function(GeofenceEntity) onEdit;

  const GeofenceListTile({
    super.key,
    required this.geofences,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final g = geofences[index];
          return GeofenceTile(
            key: ValueKey('${g.id}_${g.isActive}'), // ID와 활성 상태를 조합한 키 사용
            homeName: g.name,
            address: g.address.isNotEmpty ? g.address : _loadingAddress,
            memberCount: _parseCount(g.contactIds),
            isToggleOn: g.isActive,
            onToggleChanged: (val) => onToggle(g, val),
            onLongPress: () => onDelete(g),
            onTap: () => onEdit(g),
          );
        }, childCount: geofences.length),
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
