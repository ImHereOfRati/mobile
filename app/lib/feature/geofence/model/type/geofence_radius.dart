/// 장소 주변으로 감지할 반경. 웹과 같은 세 가지만 고른다.
enum GeofenceRadius {
  m250(250, '250m'),
  m500(500, '500m'),
  km1(1000, '1km');

  final int meters;
  final String label;

  const GeofenceRadius(this.meters, this.label);

  static GeofenceRadius fromMeters(num meters) =>
      GeofenceRadius.values.firstWhere(
        (radius) => radius.meters == meters.round(),
        orElse: () => km1,
      );
}
