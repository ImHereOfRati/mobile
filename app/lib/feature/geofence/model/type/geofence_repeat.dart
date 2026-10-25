enum GeofenceRepeat {
  none('한 번만'),
  daily('매일'),
  weekday('평일'),
  weekend('주말'),
  custom('요일 선택');

  const GeofenceRepeat(this.label);

  final String label;

  static GeofenceRepeat fromName(String name) =>
      GeofenceRepeat.values.where((value) => value.name == name).firstOrNull ??
      GeofenceRepeat.none;

  bool allows(DateTime localTime, int customDaysBitmask) => switch (this) {
    GeofenceRepeat.none || GeofenceRepeat.daily => true,
    GeofenceRepeat.weekday => localTime.weekday <= DateTime.friday,
    GeofenceRepeat.weekend => localTime.weekday >= DateTime.saturday,
    GeofenceRepeat.custom =>
      customDaysBitmask & (1 << (localTime.weekday - 1)) != 0,
  };
}
