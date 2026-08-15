import {
  event,
  type InferSchema,
  method,
  schema as s,
  type Schema,
} from "./schema";

export const BRIDGE_VERSION = "1.3.0";
export const MINIMUM_BRIDGE_VERSION = "1.3.0";

export const Platform = s.enum("BridgePlatform", [
  "android",
  "ios",
  "browser",
] as const);
export const UserStatus = s.enum("UserStatus", [
  "pending",
  "active",
  "inactive",
] as const);
export const PermissionType = s.enum("PermissionType", [
  "locationWhenInUse",
  "locationAlways",
  "notification",
  "batteryOptimization",
  "contacts",
] as const);
export const PermissionStatus = s.enum("PermissionStatus", [
  "granted",
  "denied",
  "permanentlyDenied",
  "restricted",
  "serviceDisabled",
  "unknown",
] as const);
export const GeofenceEventType = s.enum("GeofenceEventType", [
  "arrival",
  "departure",
  "both",
] as const);
export const RepeatType = s.enum("RepeatType", [
  "none",
  "daily",
  "weekday",
  "weekend",
  "custom",
] as const);
export const ConnectivityType = s.enum("ConnectivityType", [
  "wifi",
  "mobile",
  "ethernet",
  "none",
  "other",
] as const);
export const AppTheme = s.enum("BridgeTheme", [
  "light",
  "dark",
  "system",
] as const);
export const HapticStyle = s.enum("HapticStyle", [
  "light",
  "medium",
  "heavy",
  "selection",
] as const);
export const StatusBarStyle = s.enum("StatusBarStyle", [
  "light",
  "dark",
] as const);
export const LocationServiceState = s.enum("LocationServiceState", [
  "enabled",
  "disabled",
  "unknown",
] as const);

export const HandshakeInfo = s.object("HandshakeInfo", {
  bridgeVersion: s.string,
  appVersion: s.string,
  platform: Platform,
  capabilities: s.array(s.string),
});

export const AuthState = s.object("AuthState", {
  authenticated: s.boolean,
  userStatus: s.nullable(UserStatus),
});

export const AccessToken = s.object("AccessToken", {
  accessToken: s.nullable(s.string),
  expiresAt: s.nullable(s.string),
});

export const AuthSession = s.object("AuthSession", {
  authState: AuthState,
  token: AccessToken,
});

export const TermConsent = s.object("TermConsent", {
  id: s.integer,
  agreed: s.boolean,
});

export const TermsActivationRequest = s.object("TermsActivationRequest", {
  consents: s.array(TermConsent),
});

export const PermissionRequest = s.object("PermissionRequest", {
  permission: PermissionType,
});

export const PermissionResult = s.object("PermissionResult", {
  permission: PermissionType,
  status: PermissionStatus,
});

export const AutoSendReadiness = s.object("AutoSendReadiness", {
  ready: s.boolean,
  locationAlways: s.boolean,
  locationService: s.boolean,
  notification: s.boolean,
  batteryOptimization: s.boolean,
  missing: s.array(PermissionType),
});

export const ServerRecipient = s.object("ServerRecipient", {
  friendRelationshipId: s.string,
  friendUserId: s.string,
  friendEmail: s.string,
  friendAlias: s.string,
});

export const GeofenceInput = s.object("GeofenceInput", {
  id: s.optional(s.integer),
  name: s.string,
  address: s.string,
  latitude: s.number,
  longitude: s.number,
  radiusMeters: s.integer,
  eventType: GeofenceEventType,
  repeatType: RepeatType,
  customDaysBitmask: s.optional(s.integer),
  message: s.string,
  active: s.boolean,
  deviceContactIds: s.array(s.string),
  serverRecipients: s.array(ServerRecipient),
});

export const Geofence = s.object("Geofence", {
  id: s.integer,
  name: s.string,
  address: s.string,
  latitude: s.number,
  longitude: s.number,
  radiusMeters: s.integer,
  eventType: GeofenceEventType,
  repeatType: RepeatType,
  customDaysBitmask: s.optional(s.integer),
  message: s.string,
  active: s.boolean,
  awaitingDeparture: s.boolean,
  deviceContactIds: s.array(s.string),
  serverRecipients: s.array(ServerRecipient),
});

export const GeofenceId = s.object("GeofenceId", {
  id: s.integer,
});

export const SetGeofenceActive = s.object("SetGeofenceActive", {
  id: s.integer,
  active: s.boolean,
});

export const UpdateGeofenceAddress = s.object("UpdateGeofenceAddress", {
  id: s.integer,
  address: s.string,
});

export const GeofenceSyncResult = s.object("GeofenceSyncResult", {
  registeredIds: s.array(s.integer),
  skippedIds: s.array(s.integer),
});

export const NativeGeofenceState = s.object("NativeGeofenceState", {
  id: s.integer,
  registered: s.boolean,
});

export const PageRequest = s.object("PageRequest", {
  cursor: s.optional(s.string),
  limit: s.integer,
});

export const GeofencePage = s.object("GeofencePage", {
  items: s.array(Geofence),
  nextCursor: s.optional(s.string),
});

export const DeliveryRecord = s.object("DeliveryRecord", {
  id: s.integer,
  geofenceId: s.integer,
  geofenceName: s.string,
  eventType: GeofenceEventType,
  status: s.string,
  occurredAt: s.string,
  message: s.string,
});

export const DeliveryRecordPage = s.object("DeliveryRecordPage", {
  items: s.array(DeliveryRecord),
  nextCursor: s.optional(s.string),
});

export const Notification = s.object("BridgeNotification", {
  id: s.integer,
  title: s.string,
  body: s.string,
  path: s.optional(s.string),
  senderAlias: s.optional(s.string),
  createdAt: s.string,
});

export const NotificationPage = s.object("NotificationPage", {
  items: s.array(Notification),
  nextCursor: s.optional(s.string),
});

export const RecordId = s.object("RecordId", {
  id: s.integer,
});

export const DeviceContact = s.object("DeviceContact", {
  id: s.string,
  displayName: s.string,
  phoneNumbers: s.array(s.string),
});

export const UpdateDeviceContact = s.object("UpdateDeviceContact", {
  id: s.string,
  displayName: s.string,
});

export const DeviceContactId = s.object("DeviceContactId", {
  id: s.string,
});

export const Position = s.object("Position", {
  latitude: s.number,
  longitude: s.number,
  accuracyMeters: s.number,
  capturedAt: s.string,
});

export const LocationServiceStatus = s.object("LocationServiceStatus", {
  status: LocationServiceState,
});

export const AppInfo = s.object("AppInfo", {
  appVersion: s.string,
  buildNumber: s.string,
  platform: Platform,
  locale: s.string,
  theme: AppTheme,
});

export const ExternalUrlRequest = s.object("ExternalUrlRequest", {
  url: s.string,
});

export const ShareRequest = s.object("ShareRequest", {
  text: s.string,
  title: s.optional(s.string),
});

export const HapticRequest = s.object("HapticRequest", {
  style: HapticStyle,
});

export const StatusBarRequest = s.object("StatusBarRequest", {
  style: StatusBarStyle,
});

export const AnalyticsEvent = s.object("AnalyticsEvent", {
  name: s.string,
  parameters: s.optional(s.json),
});

export const AnalyticsConsent = s.object("AnalyticsConsent", {
  granted: s.boolean,
});

export const PermissionChangedEvent = s.object("PermissionChangedEvent", {
  permission: PermissionType,
  status: PermissionStatus,
});

export const ConnectivityChangedEvent = s.object("ConnectivityChangedEvent", {
  connected: s.boolean,
  connectionType: ConnectivityType,
});

export const PushOpenedEvent = s.object("PushOpenedEvent", {
  path: s.string,
});

export const GeofenceTriggeredEvent = s.object("GeofenceTriggeredEvent", {
  geofenceId: s.integer,
  eventType: GeofenceEventType,
  occurredAt: s.string,
});

export const ThemeChangedEvent = s.object("ThemeChangedEvent", {
  theme: AppTheme,
});

export const bridgeContract = {
  version: BRIDGE_VERSION,
  minimumVersion: MINIMUM_BRIDGE_VERSION,
  methods: {
    getCapabilities: method(null, HandshakeInfo),
    getAuthState: method(null, AuthState),
    getAccessToken: method(null, AccessToken),
    refreshAccessToken: method(null, AccessToken),
    signInWithKakao: method(null, AuthSession),
    signInWithGoogle: method(null, AuthSession),
    activateWithTerms: method(TermsActivationRequest, AuthSession),
    signOut: method(null, null),
    withdraw: method(null, null),
    getPermissionStatus: method(PermissionRequest, PermissionResult),
    requestPermission: method(PermissionRequest, PermissionResult),
    openAppSettings: method(null, null),
    getAutoSendReadiness: method(null, AutoSendReadiness),
    registerGeofence: method(GeofenceInput, Geofence),
    unregisterGeofence: method(GeofenceId, null),
    setGeofenceActive: method(SetGeofenceActive, Geofence),
    updateGeofenceAddress: method(UpdateGeofenceAddress, Geofence),
    syncGeofences: method(null, GeofenceSyncResult),
    getNativeGeofenceState: method(GeofenceId, NativeGeofenceState),
    queryGeofences: method(PageRequest, GeofencePage),
    queryRecords: method(PageRequest, DeliveryRecordPage),
    queryNotifications: method(PageRequest, NotificationPage),
    deleteRecord: method(RecordId, null),
    deleteAllRecords: method(null, null),
    deleteAllNotifications: method(null, null),
    getDeviceContacts: method(null, s.array(DeviceContact)),
    pickDeviceContact: method(null, s.nullable(DeviceContact)),
    updateDeviceContact: method(UpdateDeviceContact, DeviceContact),
    deleteDeviceContact: method(DeviceContactId, null),
    getCurrentPosition: method(null, Position),
    getLocationServiceStatus: method(null, LocationServiceStatus),
    getAppInfo: method(null, AppInfo),
    openExternalUrl: method(ExternalUrlRequest, null),
    share: method(ShareRequest, null),
    haptic: method(HapticRequest, null),
    setStatusBarStyle: method(StatusBarRequest, null),
    exitApp: method(null, null),
    setAnalyticsConsent: method(AnalyticsConsent, null),
    logEvent: method(AnalyticsEvent, null),
  },
  events: {
    onAppResumed: event(null),
    onPermissionChanged: event(PermissionChangedEvent),
    onConnectivityChanged: event(ConnectivityChangedEvent),
    onPushOpened: event(PushOpenedEvent),
    onGeofenceTriggered: event(GeofenceTriggeredEvent),
    onThemeChanged: event(ThemeChangedEvent),
    onAndroidBackPressed: event(null),
  },
} as const;

export type BridgeContract = typeof bridgeContract;
export type BridgeMethodName = keyof BridgeContract["methods"];
export type BridgeEventName = keyof BridgeContract["events"];

type ParamsSchema<Name extends BridgeMethodName> =
  BridgeContract["methods"][Name]["params"];

type ResultSchema<Name extends BridgeMethodName> =
  BridgeContract["methods"][Name]["result"];

type PayloadSchema<Name extends BridgeEventName> =
  BridgeContract["events"][Name]["payload"];

export type BridgeMethodArgs<Name extends BridgeMethodName> =
  ParamsSchema<Name> extends Schema
    ? [params: InferSchema<ParamsSchema<Name>>]
    : [];

export type BridgeMethodResult<Name extends BridgeMethodName> =
  ResultSchema<Name> extends Schema ? InferSchema<ResultSchema<Name>> : void;

export type BridgeEventPayload<Name extends BridgeEventName> =
  PayloadSchema<Name> extends Schema ? InferSchema<PayloadSchema<Name>> : void;

type BridgeMethodFunction<Name extends BridgeMethodName> = (
  ...args: BridgeMethodArgs<Name>
) => Promise<BridgeMethodResult<Name>>;

export type BridgeApi = {
  [Name in BridgeMethodName]: BridgeMethodFunction<Name>;
};

export const BRIDGE_CAPABILITIES = [
  ...Object.keys(bridgeContract.methods).map((name) => `method:${name}`),
  ...Object.keys(bridgeContract.events).map((name) => `event:${name}`),
] as const;
