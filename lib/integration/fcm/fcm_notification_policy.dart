const String criticalChannelId = 'fcm_critical_channel';
const String highChannelId = 'fcm_high_channel';
const String normalChannelId = 'fcm_normal_channel';
const String silentChannelId = 'fcm_silent_channel';

String resolveFcmChannelId(String? type) {
  switch (type) {
    case 'ARRIVAL':
    case 'ARRIVAL_CONFIRMATION':
    case 'DEPARTURE':
      return criticalChannelId;
    case 'FRIEND_REQUEST_RECEIVED':
    case 'LOCATION_TARGET':
      return highChannelId;
    case 'FRIEND_REQUEST_ACCEPTED':
    case 'DELIVERY_FAILED_NOTICE':
      return normalChannelId;
    case 'TERMS_UPDATE_NOTICE':
    case 'DELIVERY_RESULT_NOTICE':
    default:
      return silentChannelId;
  }
}
