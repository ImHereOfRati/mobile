import 'package:iamhere/feature/setting/model/type/setting_status.dart';

abstract class SettingStatusServiceInterface {
  Future<SettingStatus> load();

  /// 시스템 권한 요청을 띄운다. 결과는 [load]로 다시 읽는다.
  Future<void> requestPermission(SettingPermission permission);

  /// 열지 못하면 예외를 던진다.
  Future<void> openAppSettings();
}
