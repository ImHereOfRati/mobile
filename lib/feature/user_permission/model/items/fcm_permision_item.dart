import 'package:iamhere/feature/user_permission/model/permission_item.dart';

class FcmAlertPermissionItem extends PermissionItem {
  FcmAlertPermissionItem({
    required super.title,
    required super.icon,
    required super.shortDesc,
    required super.detailedDesc,
    super.isRequired = false,
    super.isGranted,
  });

  @override
  FcmAlertPermissionItem copyWith({bool? isGranted}) {
    return FcmAlertPermissionItem(
      title: title,
      icon: icon,
      shortDesc: shortDesc,
      detailedDesc: detailedDesc,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}
