import 'dart:convert';

class RecordTimeFormatter {
  const RecordTimeFormatter._();

  static String formatRecipients(String recipientsJson) {
    try {
      final list = jsonDecode(recipientsJson) as List<dynamic>;
      if (list.isEmpty) return '수신자';
      if (list.length == 1) return list.first as String;
      return '${list.first} 외 ${list.length - 1}명';
    } catch (_) {
      return '수신자';
    }
  }

  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${dt.month}월 ${dt.day}일';
  }

  static String formatActivityLabel({
    required String locationName,
    required String deliveryEventType,
  }) {
    switch (deliveryEventType) {
      case 'departure':
        return '$locationName 출발 감지';
      case 'arrival':
        return '$locationName 도착 감지';
      default:
        return '$locationName 감지';
    }
  }
}
