/// 반경 관련 유틸리티 헬퍼 클래스
class RadiusHelper {
  static const int radius250m = 250;
  static const int radius500m = 500;
  static const int radius1km = 1000;

  static String getRadiusInfoMessage(int radius) {
    switch (radius) {
      case radius250m:
        return '정확한 위치에서 알림을 보내드려요!';
      case radius500m:
        return '적절한 범위에서 알림을 보내드려요!';
      case radius1km:
        return 'GPS가 정확하지 않아도 알람을 보낼 수 있어요!';
      default:
        return '';
    }
  }

  static List<int> get supportedRadiusValues => [
    radius250m,
    radius500m,
    radius1km,
  ];
}
