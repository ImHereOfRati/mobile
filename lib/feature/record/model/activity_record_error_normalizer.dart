class ActivityRecordErrorNormalizer {
  const ActivityRecordErrorNormalizer._();

  static String normalize(String raw) {
    final message = raw.trim();
    if (message.isEmpty) return '';

    final lower = message.toLowerCase();

    if (lower.contains('timeout')) {
      return '응답 시간이 초과되었습니다. 잠시 후 다시 시도합니다.';
    }
    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return '네트워크 연결이 불안정합니다. 연결 복구 후 다시 시도합니다.';
    }
    if (lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('unauthorized')) {
      return '로그인 정보가 만료되었거나 권한이 없습니다.';
    }
    if (lower.contains('429')) {
      return '요청이 많아 잠시 후 다시 시도합니다.';
    }
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('server')) {
      return '알림 서버 오류로 전송이 지연되고 있습니다.';
    }
    if (lower.contains('firebase') || lower.contains('fcm')) {
      return '푸시 알림 전송 중 오류가 발생했습니다.';
    }
    if (lower.contains('sms')) {
      return '문자 발송 중 오류가 발생했습니다.';
    }
    if (lower.contains('all delivery attempts failed')) {
      return '모든 발송 수단에서 전송에 실패했습니다.';
    }

    return '알림 전송 중 오류가 발생했습니다.';
  }
}
