enum RepeatType {
  none('반복 안 함'),
  daily('매일'),
  weekday('평일'),
  weekend('주말'),
  custom('직접 설정');

  final String displayName;

  const RepeatType(this.displayName);
}

class RepeatSchedule {
  final RepeatType type;
  final Set<int>? customDays; // 0=Sunday, 1=Monday, ..., 6=Saturday (only used when type == custom)

  const RepeatSchedule({
    this.type = RepeatType.none,
    this.customDays,
  });

  /// Convert custom days set to bitmask (for storage/API)
  int? get customDaysBitmask {
    if (customDays == null || customDays!.isEmpty) return null;
    int mask = 0;
    for (int day in customDays!) {
      mask |= (1 << day);
    }
    return mask;
  }

  /// Create RepeatSchedule from bitmask
  factory RepeatSchedule.fromBitmask(int bitmask) {
    final days = <int>{};
    for (int i = 0; i < 7; i++) {
      if ((bitmask & (1 << i)) != 0) {
        days.add(i);
      }
    }
    return RepeatSchedule(
      type: RepeatType.custom,
      customDays: days,
    );
  }

  RepeatSchedule copyWith({
    RepeatType? type,
    Set<int>? customDays,
  }) {
    return RepeatSchedule(
      type: type ?? this.type,
      customDays: customDays ?? this.customDays,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatSchedule &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _setsEqual(customDays, other.customDays);

  bool _setsEqual(Set<int>? a, Set<int>? b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.every(b.contains);
  }

  @override
  int get hashCode => type.hashCode ^ (customDays?.fold<int>(0, (a, b) => a ^ b.hashCode) ?? 0);
}
