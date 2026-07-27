class AppVersionPolicy {
  const AppVersionPolicy._();

  static bool requiresUpdate({
    required String currentVersion,
    required String? minimumVersion,
  }) {
    final current = _parse(currentVersion);
    final minimum = _parse(minimumVersion);
    if (current == null || minimum == null) return false;
    for (var index = 0; index < 3; index++) {
      if (current[index] < minimum[index]) return true;
      if (current[index] > minimum[index]) return false;
    }
    return false;
  }

  static List<int>? _parse(String? raw) {
    if (raw == null) return null;
    final core = raw.trim().split(RegExp(r'[-+]')).first;
    final parts = core.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final values = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      values.add(value);
    }
    while (values.length < 3) {
      values.add(0);
    }
    return values;
  }
}
