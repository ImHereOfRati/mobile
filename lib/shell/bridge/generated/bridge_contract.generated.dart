// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: web/packages/bridge-contract/src/contract.ts
// Run: pnpm bridge:generate
// ignore_for_file: prefer_if_null_operators, prefer_null_aware_operators

const bridgeContractVersion = '1.3.0';
const minimumBridgeContractVersion = '1.3.0';

const bridgeMethodNames = <String>[
  'getCapabilities',
  'getAuthState',
  'getAccessToken',
  'refreshAccessToken',
  'signInWithKakao',
  'signInWithGoogle',
  'activateWithTerms',
  'signOut',
  'withdraw',
  'getPermissionStatus',
  'requestPermission',
  'openAppSettings',
  'getAutoSendReadiness',
  'registerGeofence',
  'unregisterGeofence',
  'setGeofenceActive',
  'updateGeofenceAddress',
  'syncGeofences',
  'getNativeGeofenceState',
  'queryGeofences',
  'queryRecords',
  'queryNotifications',
  'deleteRecord',
  'deleteAllRecords',
  'deleteAllNotifications',
  'getDeviceContacts',
  'pickDeviceContact',
  'updateDeviceContact',
  'deleteDeviceContact',
  'getCurrentPosition',
  'getLocationServiceStatus',
  'getAppInfo',
  'openExternalUrl',
  'share',
  'haptic',
  'setStatusBarStyle',
  'exitApp',
  'setAnalyticsConsent',
  'logEvent',
];

const bridgeEventNames = <String>[
  'onAppResumed',
  'onPermissionChanged',
  'onConnectivityChanged',
  'onPushOpened',
  'onGeofenceTriggered',
  'onThemeChanged',
  'onAndroidBackPressed',
];

class HandshakeInfo {
  const HandshakeInfo({
    required this.bridgeVersion,
    required this.appVersion,
    required this.platform,
    required this.capabilities,
  });

  final String bridgeVersion;
  final String appVersion;
  final BridgePlatform platform;
  final List<String> capabilities;

  factory HandshakeInfo.fromJson(Map<String, Object?> json) {
    return HandshakeInfo(
      bridgeVersion: json['bridgeVersion'] as String,
      appVersion: json['appVersion'] as String,
      platform: BridgePlatform.values.byName(json['platform'] as String),
      capabilities: (json['capabilities'] as List<Object?>).map((item) => item as String).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bridgeVersion': bridgeVersion,
      'appVersion': appVersion,
      'platform': platform.name,
      'capabilities': capabilities.map((item) => item).toList(),
    };
  }
}

enum BridgePlatform {
  android,
  ios,
  browser,
}

class AuthState {
  const AuthState({
    required this.authenticated,
    required this.userStatus,
  });

  final bool authenticated;
  final UserStatus? userStatus;

  factory AuthState.fromJson(Map<String, Object?> json) {
    return AuthState(
      authenticated: json['authenticated'] as bool,
      userStatus: json['userStatus'] == null ? null : UserStatus.values.byName(json['userStatus'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'authenticated': authenticated,
      'userStatus': userStatus == null ? null : userStatus!.name,
    };
  }
}

enum UserStatus {
  pending,
  active,
  inactive,
}

class AccessToken {
  const AccessToken({
    required this.accessToken,
    required this.expiresAt,
  });

  final String? accessToken;
  final String? expiresAt;

  factory AccessToken.fromJson(Map<String, Object?> json) {
    return AccessToken(
      accessToken: json['accessToken'] == null ? null : json['accessToken'] as String,
      expiresAt: json['expiresAt'] == null ? null : json['expiresAt'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'accessToken': accessToken == null ? null : accessToken!,
      'expiresAt': expiresAt == null ? null : expiresAt!,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.authState,
    required this.token,
  });

  final AuthState authState;
  final AccessToken token;

  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      authState: AuthState.fromJson(json['authState'] as Map<String, Object?>),
      token: AccessToken.fromJson(json['token'] as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'authState': authState.toJson(),
      'token': token.toJson(),
    };
  }
}

class TermsActivationRequest {
  const TermsActivationRequest({
    required this.consents,
  });

  final List<TermConsent> consents;

  factory TermsActivationRequest.fromJson(Map<String, Object?> json) {
    return TermsActivationRequest(
      consents: (json['consents'] as List<Object?>).map((item) => TermConsent.fromJson(item as Map<String, Object?>)).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'consents': consents.map((item) => item.toJson()).toList(),
    };
  }
}

class TermConsent {
  const TermConsent({
    required this.id,
    required this.agreed,
  });

  final int id;
  final bool agreed;

  factory TermConsent.fromJson(Map<String, Object?> json) {
    return TermConsent(
      id: (json['id'] as num).toInt(),
      agreed: json['agreed'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'agreed': agreed,
    };
  }
}

class PermissionRequest {
  const PermissionRequest({
    required this.permission,
  });

  final PermissionType permission;

  factory PermissionRequest.fromJson(Map<String, Object?> json) {
    return PermissionRequest(
      permission: PermissionType.values.byName(json['permission'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'permission': permission.name,
    };
  }
}

enum PermissionType {
  locationWhenInUse,
  locationAlways,
  notification,
  batteryOptimization,
  contacts,
}

class PermissionResult {
  const PermissionResult({
    required this.permission,
    required this.status,
  });

  final PermissionType permission;
  final PermissionStatus status;

  factory PermissionResult.fromJson(Map<String, Object?> json) {
    return PermissionResult(
      permission: PermissionType.values.byName(json['permission'] as String),
      status: PermissionStatus.values.byName(json['status'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'permission': permission.name,
      'status': status.name,
    };
  }
}

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  serviceDisabled,
  unknown,
}

class AutoSendReadiness {
  const AutoSendReadiness({
    required this.ready,
    required this.locationAlways,
    required this.locationService,
    required this.notification,
    required this.batteryOptimization,
    required this.missing,
  });

  final bool ready;
  final bool locationAlways;
  final bool locationService;
  final bool notification;
  final bool batteryOptimization;
  final List<PermissionType> missing;

  factory AutoSendReadiness.fromJson(Map<String, Object?> json) {
    return AutoSendReadiness(
      ready: json['ready'] as bool,
      locationAlways: json['locationAlways'] as bool,
      locationService: json['locationService'] as bool,
      notification: json['notification'] as bool,
      batteryOptimization: json['batteryOptimization'] as bool,
      missing: (json['missing'] as List<Object?>).map((item) => PermissionType.values.byName(item as String)).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ready': ready,
      'locationAlways': locationAlways,
      'locationService': locationService,
      'notification': notification,
      'batteryOptimization': batteryOptimization,
      'missing': missing.map((item) => item.name).toList(),
    };
  }
}

class GeofenceInput {
  const GeofenceInput({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.eventType,
    required this.repeatType,
    this.customDaysBitmask,
    required this.message,
    required this.active,
    required this.deviceContactIds,
    required this.serverRecipients,
  });

  final int? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final GeofenceEventType eventType;
  final RepeatType repeatType;
  final int? customDaysBitmask;
  final String message;
  final bool active;
  final List<String> deviceContactIds;
  final List<ServerRecipient> serverRecipients;

  factory GeofenceInput.fromJson(Map<String, Object?> json) {
    return GeofenceInput(
      id: json['id'] == null ? null : (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toInt(),
      eventType: GeofenceEventType.values.byName(json['eventType'] as String),
      repeatType: RepeatType.values.byName(json['repeatType'] as String),
      customDaysBitmask: json['customDaysBitmask'] == null ? null : (json['customDaysBitmask'] as num).toInt(),
      message: json['message'] as String,
      active: json['active'] as bool,
      deviceContactIds: (json['deviceContactIds'] as List<Object?>).map((item) => item as String).toList(),
      serverRecipients: (json['serverRecipients'] as List<Object?>).map((item) => ServerRecipient.fromJson(item as Map<String, Object?>)).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id!,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'eventType': eventType.name,
      'repeatType': repeatType.name,
      if (customDaysBitmask != null) 'customDaysBitmask': customDaysBitmask!,
      'message': message,
      'active': active,
      'deviceContactIds': deviceContactIds.map((item) => item).toList(),
      'serverRecipients': serverRecipients.map((item) => item.toJson()).toList(),
    };
  }
}

enum GeofenceEventType {
  arrival,
  departure,
  both,
}

enum RepeatType {
  none,
  daily,
  weekday,
  weekend,
  custom,
}

class ServerRecipient {
  const ServerRecipient({
    required this.friendRelationshipId,
    required this.friendUserId,
    required this.friendEmail,
    required this.friendAlias,
  });

  final String friendRelationshipId;
  final String friendUserId;
  final String friendEmail;
  final String friendAlias;

  factory ServerRecipient.fromJson(Map<String, Object?> json) {
    return ServerRecipient(
      friendRelationshipId: json['friendRelationshipId'] as String,
      friendUserId: json['friendUserId'] as String,
      friendEmail: json['friendEmail'] as String,
      friendAlias: json['friendAlias'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'friendRelationshipId': friendRelationshipId,
      'friendUserId': friendUserId,
      'friendEmail': friendEmail,
      'friendAlias': friendAlias,
    };
  }
}

class Geofence {
  const Geofence({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.eventType,
    required this.repeatType,
    this.customDaysBitmask,
    required this.message,
    required this.active,
    required this.awaitingDeparture,
    required this.deviceContactIds,
    required this.serverRecipients,
  });

  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final GeofenceEventType eventType;
  final RepeatType repeatType;
  final int? customDaysBitmask;
  final String message;
  final bool active;
  final bool awaitingDeparture;
  final List<String> deviceContactIds;
  final List<ServerRecipient> serverRecipients;

  factory Geofence.fromJson(Map<String, Object?> json) {
    return Geofence(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toInt(),
      eventType: GeofenceEventType.values.byName(json['eventType'] as String),
      repeatType: RepeatType.values.byName(json['repeatType'] as String),
      customDaysBitmask: json['customDaysBitmask'] == null ? null : (json['customDaysBitmask'] as num).toInt(),
      message: json['message'] as String,
      active: json['active'] as bool,
      awaitingDeparture: json['awaitingDeparture'] as bool,
      deviceContactIds: (json['deviceContactIds'] as List<Object?>).map((item) => item as String).toList(),
      serverRecipients: (json['serverRecipients'] as List<Object?>).map((item) => ServerRecipient.fromJson(item as Map<String, Object?>)).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'eventType': eventType.name,
      'repeatType': repeatType.name,
      if (customDaysBitmask != null) 'customDaysBitmask': customDaysBitmask!,
      'message': message,
      'active': active,
      'awaitingDeparture': awaitingDeparture,
      'deviceContactIds': deviceContactIds.map((item) => item).toList(),
      'serverRecipients': serverRecipients.map((item) => item.toJson()).toList(),
    };
  }
}

class GeofenceId {
  const GeofenceId({
    required this.id,
  });

  final int id;

  factory GeofenceId.fromJson(Map<String, Object?> json) {
    return GeofenceId(
      id: (json['id'] as num).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
    };
  }
}

class SetGeofenceActive {
  const SetGeofenceActive({
    required this.id,
    required this.active,
  });

  final int id;
  final bool active;

  factory SetGeofenceActive.fromJson(Map<String, Object?> json) {
    return SetGeofenceActive(
      id: (json['id'] as num).toInt(),
      active: json['active'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'active': active,
    };
  }
}

class UpdateGeofenceAddress {
  const UpdateGeofenceAddress({
    required this.id,
    required this.address,
  });

  final int id;
  final String address;

  factory UpdateGeofenceAddress.fromJson(Map<String, Object?> json) {
    return UpdateGeofenceAddress(
      id: (json['id'] as num).toInt(),
      address: json['address'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'address': address,
    };
  }
}

class GeofenceSyncResult {
  const GeofenceSyncResult({
    required this.registeredIds,
    required this.skippedIds,
  });

  final List<int> registeredIds;
  final List<int> skippedIds;

  factory GeofenceSyncResult.fromJson(Map<String, Object?> json) {
    return GeofenceSyncResult(
      registeredIds: (json['registeredIds'] as List<Object?>).map((item) => (item as num).toInt()).toList(),
      skippedIds: (json['skippedIds'] as List<Object?>).map((item) => (item as num).toInt()).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'registeredIds': registeredIds.map((item) => item).toList(),
      'skippedIds': skippedIds.map((item) => item).toList(),
    };
  }
}

class NativeGeofenceState {
  const NativeGeofenceState({
    required this.id,
    required this.registered,
  });

  final int id;
  final bool registered;

  factory NativeGeofenceState.fromJson(Map<String, Object?> json) {
    return NativeGeofenceState(
      id: (json['id'] as num).toInt(),
      registered: json['registered'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'registered': registered,
    };
  }
}

class PageRequest {
  const PageRequest({
    this.cursor,
    required this.limit,
  });

  final String? cursor;
  final int limit;

  factory PageRequest.fromJson(Map<String, Object?> json) {
    return PageRequest(
      cursor: json['cursor'] == null ? null : json['cursor'] as String,
      limit: (json['limit'] as num).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (cursor != null) 'cursor': cursor!,
      'limit': limit,
    };
  }
}

class GeofencePage {
  const GeofencePage({
    required this.items,
    this.nextCursor,
  });

  final List<Geofence> items;
  final String? nextCursor;

  factory GeofencePage.fromJson(Map<String, Object?> json) {
    return GeofencePage(
      items: (json['items'] as List<Object?>).map((item) => Geofence.fromJson(item as Map<String, Object?>)).toList(),
      nextCursor: json['nextCursor'] == null ? null : json['nextCursor'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'items': items.map((item) => item.toJson()).toList(),
      if (nextCursor != null) 'nextCursor': nextCursor!,
    };
  }
}

class DeliveryRecordPage {
  const DeliveryRecordPage({
    required this.items,
    this.nextCursor,
  });

  final List<DeliveryRecord> items;
  final String? nextCursor;

  factory DeliveryRecordPage.fromJson(Map<String, Object?> json) {
    return DeliveryRecordPage(
      items: (json['items'] as List<Object?>).map((item) => DeliveryRecord.fromJson(item as Map<String, Object?>)).toList(),
      nextCursor: json['nextCursor'] == null ? null : json['nextCursor'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'items': items.map((item) => item.toJson()).toList(),
      if (nextCursor != null) 'nextCursor': nextCursor!,
    };
  }
}

class DeliveryRecord {
  const DeliveryRecord({
    required this.id,
    required this.geofenceId,
    required this.geofenceName,
    required this.eventType,
    required this.status,
    required this.occurredAt,
    required this.message,
  });

  final int id;
  final int geofenceId;
  final String geofenceName;
  final GeofenceEventType eventType;
  final String status;
  final String occurredAt;
  final String message;

  factory DeliveryRecord.fromJson(Map<String, Object?> json) {
    return DeliveryRecord(
      id: (json['id'] as num).toInt(),
      geofenceId: (json['geofenceId'] as num).toInt(),
      geofenceName: json['geofenceName'] as String,
      eventType: GeofenceEventType.values.byName(json['eventType'] as String),
      status: json['status'] as String,
      occurredAt: json['occurredAt'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'geofenceId': geofenceId,
      'geofenceName': geofenceName,
      'eventType': eventType.name,
      'status': status,
      'occurredAt': occurredAt,
      'message': message,
    };
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    this.nextCursor,
  });

  final List<BridgeNotification> items;
  final String? nextCursor;

  factory NotificationPage.fromJson(Map<String, Object?> json) {
    return NotificationPage(
      items: (json['items'] as List<Object?>).map((item) => BridgeNotification.fromJson(item as Map<String, Object?>)).toList(),
      nextCursor: json['nextCursor'] == null ? null : json['nextCursor'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'items': items.map((item) => item.toJson()).toList(),
      if (nextCursor != null) 'nextCursor': nextCursor!,
    };
  }
}

class BridgeNotification {
  const BridgeNotification({
    required this.id,
    required this.title,
    required this.body,
    this.path,
    this.senderAlias,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String? path;
  final String? senderAlias;
  final String createdAt;

  factory BridgeNotification.fromJson(Map<String, Object?> json) {
    return BridgeNotification(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
      path: json['path'] == null ? null : json['path'] as String,
      senderAlias: json['senderAlias'] == null ? null : json['senderAlias'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'body': body,
      if (path != null) 'path': path!,
      if (senderAlias != null) 'senderAlias': senderAlias!,
      'createdAt': createdAt,
    };
  }
}

class RecordId {
  const RecordId({
    required this.id,
  });

  final int id;

  factory RecordId.fromJson(Map<String, Object?> json) {
    return RecordId(
      id: (json['id'] as num).toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
    };
  }
}

class DeviceContact {
  const DeviceContact({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
  });

  final String id;
  final String displayName;
  final List<String> phoneNumbers;

  factory DeviceContact.fromJson(Map<String, Object?> json) {
    return DeviceContact(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      phoneNumbers: (json['phoneNumbers'] as List<Object?>).map((item) => item as String).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'displayName': displayName,
      'phoneNumbers': phoneNumbers.map((item) => item).toList(),
    };
  }
}

class UpdateDeviceContact {
  const UpdateDeviceContact({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory UpdateDeviceContact.fromJson(Map<String, Object?> json) {
    return UpdateDeviceContact(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'displayName': displayName,
    };
  }
}

class DeviceContactId {
  const DeviceContactId({
    required this.id,
  });

  final String id;

  factory DeviceContactId.fromJson(Map<String, Object?> json) {
    return DeviceContactId(
      id: json['id'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
    };
  }
}

class Position {
  const Position({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String capturedAt;

  factory Position.fromJson(Map<String, Object?> json) {
    return Position(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      capturedAt: json['capturedAt'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'capturedAt': capturedAt,
    };
  }
}

class LocationServiceStatus {
  const LocationServiceStatus({
    required this.status,
  });

  final LocationServiceState status;

  factory LocationServiceStatus.fromJson(Map<String, Object?> json) {
    return LocationServiceStatus(
      status: LocationServiceState.values.byName(json['status'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'status': status.name,
    };
  }
}

enum LocationServiceState {
  enabled,
  disabled,
  unknown,
}

class AppInfo {
  const AppInfo({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.locale,
    required this.theme,
  });

  final String appVersion;
  final String buildNumber;
  final BridgePlatform platform;
  final String locale;
  final BridgeTheme theme;

  factory AppInfo.fromJson(Map<String, Object?> json) {
    return AppInfo(
      appVersion: json['appVersion'] as String,
      buildNumber: json['buildNumber'] as String,
      platform: BridgePlatform.values.byName(json['platform'] as String),
      locale: json['locale'] as String,
      theme: BridgeTheme.values.byName(json['theme'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform.name,
      'locale': locale,
      'theme': theme.name,
    };
  }
}

enum BridgeTheme {
  light,
  dark,
  system,
}

class ExternalUrlRequest {
  const ExternalUrlRequest({
    required this.url,
  });

  final String url;

  factory ExternalUrlRequest.fromJson(Map<String, Object?> json) {
    return ExternalUrlRequest(
      url: json['url'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'url': url,
    };
  }
}

class ShareRequest {
  const ShareRequest({
    required this.text,
    this.title,
  });

  final String text;
  final String? title;

  factory ShareRequest.fromJson(Map<String, Object?> json) {
    return ShareRequest(
      text: json['text'] as String,
      title: json['title'] == null ? null : json['title'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'text': text,
      if (title != null) 'title': title!,
    };
  }
}

class HapticRequest {
  const HapticRequest({
    required this.style,
  });

  final HapticStyle style;

  factory HapticRequest.fromJson(Map<String, Object?> json) {
    return HapticRequest(
      style: HapticStyle.values.byName(json['style'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'style': style.name,
    };
  }
}

enum HapticStyle {
  light,
  medium,
  heavy,
  selection,
}

class StatusBarRequest {
  const StatusBarRequest({
    required this.style,
  });

  final StatusBarStyle style;

  factory StatusBarRequest.fromJson(Map<String, Object?> json) {
    return StatusBarRequest(
      style: StatusBarStyle.values.byName(json['style'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'style': style.name,
    };
  }
}

enum StatusBarStyle {
  light,
  dark,
}

class AnalyticsConsent {
  const AnalyticsConsent({
    required this.granted,
  });

  final bool granted;

  factory AnalyticsConsent.fromJson(Map<String, Object?> json) {
    return AnalyticsConsent(
      granted: json['granted'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'granted': granted,
    };
  }
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    this.parameters,
  });

  final String name;
  final Object? parameters;

  factory AnalyticsEvent.fromJson(Map<String, Object?> json) {
    return AnalyticsEvent(
      name: json['name'] as String,
      parameters: json['parameters'] == null ? null : json['parameters'],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      if (parameters != null) 'parameters': parameters!,
    };
  }
}

class PermissionChangedEvent {
  const PermissionChangedEvent({
    required this.permission,
    required this.status,
  });

  final PermissionType permission;
  final PermissionStatus status;

  factory PermissionChangedEvent.fromJson(Map<String, Object?> json) {
    return PermissionChangedEvent(
      permission: PermissionType.values.byName(json['permission'] as String),
      status: PermissionStatus.values.byName(json['status'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'permission': permission.name,
      'status': status.name,
    };
  }
}

class ConnectivityChangedEvent {
  const ConnectivityChangedEvent({
    required this.connected,
    required this.connectionType,
  });

  final bool connected;
  final ConnectivityType connectionType;

  factory ConnectivityChangedEvent.fromJson(Map<String, Object?> json) {
    return ConnectivityChangedEvent(
      connected: json['connected'] as bool,
      connectionType: ConnectivityType.values.byName(json['connectionType'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'connected': connected,
      'connectionType': connectionType.name,
    };
  }
}

enum ConnectivityType {
  wifi,
  mobile,
  ethernet,
  none,
  other,
}

class PushOpenedEvent {
  const PushOpenedEvent({
    required this.path,
  });

  final String path;

  factory PushOpenedEvent.fromJson(Map<String, Object?> json) {
    return PushOpenedEvent(
      path: json['path'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'path': path,
    };
  }
}

class GeofenceTriggeredEvent {
  const GeofenceTriggeredEvent({
    required this.geofenceId,
    required this.eventType,
    required this.occurredAt,
  });

  final int geofenceId;
  final GeofenceEventType eventType;
  final String occurredAt;

  factory GeofenceTriggeredEvent.fromJson(Map<String, Object?> json) {
    return GeofenceTriggeredEvent(
      geofenceId: (json['geofenceId'] as num).toInt(),
      eventType: GeofenceEventType.values.byName(json['eventType'] as String),
      occurredAt: json['occurredAt'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'geofenceId': geofenceId,
      'eventType': eventType.name,
      'occurredAt': occurredAt,
    };
  }
}

class ThemeChangedEvent {
  const ThemeChangedEvent({
    required this.theme,
  });

  final BridgeTheme theme;

  factory ThemeChangedEvent.fromJson(Map<String, Object?> json) {
    return ThemeChangedEvent(
      theme: BridgeTheme.values.byName(json['theme'] as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'theme': theme.name,
    };
  }
}
