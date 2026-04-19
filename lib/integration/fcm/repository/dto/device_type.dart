import 'dart:io';

enum DeviceType {
  ios("IOS"),
  aos("AOS");

  final String _description;

  String get description => _description;
  const DeviceType(this._description);

  static DeviceType getDeviceType() {
    if (Platform.isAndroid) {
      return aos;
    }

    return ios;
  }
}
