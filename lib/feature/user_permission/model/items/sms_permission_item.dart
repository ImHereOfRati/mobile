import 'package:iamhere/feature/user_permission/model/permission_item.dart';

class SmsPermissionItem extends PermissionItem {
  SmsPermissionItem({
    required super.title,
    required super.icon,
    required super.shortDesc,
    required super.detailedDesc,
    super.isRequired = true,
    super.isGranted,
  });

  @override
  SmsPermissionItem copyWith({bool? isGranted}) {
    return SmsPermissionItem(
      title: title,
      icon: icon,
      shortDesc: shortDesc,
      detailedDesc: detailedDesc,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}
