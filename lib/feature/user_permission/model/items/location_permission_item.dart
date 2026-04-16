import '../permission_item.dart';

class LocationPermissionItem extends PermissionItem {
  LocationPermissionItem({
    required super.title,
    required super.icon,
    required super.shortDesc,
    required super.detailedDesc,
    super.isRequired = true,
    super.isGranted,
  });

  @override
  LocationPermissionItem copyWith({bool? isGranted}) {
    return LocationPermissionItem(
      title: title,
      icon: icon,
      shortDesc: shortDesc,
      detailedDesc: detailedDesc,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}
