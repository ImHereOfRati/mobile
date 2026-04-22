class GeofenceBasicInfo {
  final String name;
  final String address;
  final String message;

  const GeofenceBasicInfo({
    this.name = '',
    this.address = '',
    this.message = '안녕하세요! {location}에 도착했습니다.',
  });

  GeofenceBasicInfo copyWith({
    String? name,
    String? address,
    String? message,
  }) {
    return GeofenceBasicInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      message: message ?? this.message,
    );
  }
}
