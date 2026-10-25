abstract final class DateTimeFormatter {
  /// `2026.10.25 15:07`. 기기의 현지 시각으로 보여 준다.
  static String dateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year}.${_two(local.month)}.${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// 서버가 준 ISO 문자열을 [dateTime]으로 바꾼다. 해석할 수 없으면 원문을 돌려준다.
  static String dateTimeFromIso(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : dateTime(parsed);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
