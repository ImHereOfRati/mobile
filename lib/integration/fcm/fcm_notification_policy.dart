const String criticalChannelId = 'fcm_critical_channel';
const String highChannelId = 'fcm_high_channel';
const String normalChannelId = 'fcm_normal_channel';
const String silentChannelId = 'fcm_silent_channel';

String resolveFcmChannelId(String? type) {
  switch (type) {
    case 'ARRIVAL':
    case 'DEPARTURE':
      return criticalChannelId;
    case 'FRIEND_REQUEST_RECEIVED':
    case 'LOCATION_TARGET':
      return highChannelId;
    case 'FRIEND_REQUEST_ACCEPTED':
    case 'DELIVERY_FAILED_NOTICE':
      return normalChannelId;
    case 'TERMS_UPDATE_NOTICE':
      return silentChannelId;
    case 'DELIVERY_RESULT_NOTICE':
    default:
      return silentChannelId;
  }
}

/// FCM data에는 서버 route가 포함되지 않는다. 화면 경로는 앱이 type으로
/// 결정해야 서버와 웹 라우팅 계약이 분리된다.
String? resolveFcmNotificationPath(String? type) {
  switch (type) {
    case 'FRIEND_REQUEST_RECEIVED':
    case 'FRIEND_REQUEST_ACCEPTED':
      return '/friend/requests';
    case 'DELIVERY_RESULT_NOTICE':
    case 'DELIVERY_FAILED_NOTICE':
      return '/record/send-history';
    case 'LOCATION_TARGET':
    case 'ARRIVAL':
    case 'DEPARTURE':
      return '/record/notifications';
    case 'TERMS_UPDATE_NOTICE':
      return '/setting/agreements';
    default:
      return null;
  }
}
