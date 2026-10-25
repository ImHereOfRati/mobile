enum SettingPermission {
  notification,
  locationAlways,
  batteryOptimization,
  contacts,
}

class LastDelivery {
  final String geofenceName;
  final DateTime occurredAt;

  const LastDelivery({required this.geofenceName, required this.occurredAt});
}

class SettingStatus {
  final Map<SettingPermission, bool> permissions;
  final LastDelivery? lastDelivery;
  final String? appVersion;

  const SettingStatus({
    required this.permissions,
    required this.lastDelivery,
    required this.appVersion,
  });

  bool isGranted(SettingPermission permission) =>
      permissions[permission] ?? false;
}
