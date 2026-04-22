import '../permission_item.dart';

class BatteryOptimizationPermissionItem extends PermissionItem {
  BatteryOptimizationPermissionItem({
    required super.title,
    required super.icon,
    required super.shortDesc,
    required super.detailedDesc,
    super.isRequired = false,
    super.isGranted,
  });

  @override
  BatteryOptimizationPermissionItem copyWith({bool? isGranted}) {
    return BatteryOptimizationPermissionItem(
      title: title,
      icon: icon,
      shortDesc: shortDesc,
      detailedDesc: detailedDesc,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}
