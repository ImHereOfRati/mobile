class LocalDatabaseProperties {
  static const String databaseName = "im_here.db";
  static const String contactTableName = 'contacts';
  static const String geofenceTableName = 'geofence';
  static const String geofenceServerRecipientTableName =
      'geofence_server_recipient';
  static const String recordTableName = 'records';
  static const String notificationTableName = 'notifications';

  // 기타 비즈니스 상수
  static const double defaultRadius = 300.0;
  static const String defaultMessage = '';
  static const String defaultContactIds = '[]';
  static const int defaultIsActive = 0;
}
