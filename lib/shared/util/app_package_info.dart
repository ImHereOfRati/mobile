import 'package:package_info_plus/package_info_plus.dart';

/// `PackageInfo.fromPlatform()` 을 프로세스당 한 번만 호출하도록 캐싱한다.
/// 네이티브 `getPackageName` 중복 호출을 방지한다.
class AppPackageInfo {
  AppPackageInfo._();

  static Future<PackageInfo>? _cached;

  static Future<PackageInfo> get instance {
    return _cached ??= PackageInfo.fromPlatform();
  }
}
