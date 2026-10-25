/// 장소 검색 결과 한 건. 주소를 좌표로 바꾼 뒤의 값이다.
class PlaceSearchResultDto {
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  const PlaceSearchResultDto({
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
