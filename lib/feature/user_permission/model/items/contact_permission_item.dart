import 'package:iamhere/feature/user_permission/model/permission_item.dart';

class ContactPermissionItem extends PermissionItem {
  ContactPermissionItem({
    required super.title,
    required super.icon,
    required super.shortDesc,
    required super.detailedDesc,
    super.isRequired = true,
    super.isGranted,
  });

  @override
  ContactPermissionItem copyWith({bool? isGranted}) {
    return ContactPermissionItem(
      title: title,
      icon: icon,
      shortDesc: shortDesc,
      detailedDesc: detailedDesc,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}
