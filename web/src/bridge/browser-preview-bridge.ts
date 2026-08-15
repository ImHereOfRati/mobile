import { createMockBridge } from "@imhere/bridge-contract";

const previewGeofence = {
  id: 1,
  name: "우리 집",
  address: "서울특별시 중구 세종대로 110",
  latitude: 37.5663,
  longitude: 126.9779,
  radiusMeters: 500,
  eventType: "both",
  repeatType: "daily",
  message: "집에 도착했어요.",
  active: true,
  awaitingDeparture: false,
  deviceContactIds: [],
  serverRecipients: [],
  createdAt: "2026-07-27T09:00:00Z",
  updatedAt: "2026-07-27T09:00:00Z",
};

const previewNotification = {
  id: 1,
  title: "도착 알림",
  body: "동수가 우리 집에 도착했어요.",
  senderAlias: "동수",
  createdAt: "2026-07-27T09:10:00Z",
};

const previewRecord = {
  id: 1,
  geofenceId: 1,
  geofenceName: "우리 집",
  eventType: "arrival",
  status: "completed",
  occurredAt: "2026-07-27T09:10:00Z",
  message: "집에 도착했어요.",
};

export function createBrowserPreviewBridge() {
  return createMockBridge({
    getAutoSendReadiness: async () => {
      return {
        ready: true,
        locationAlways: true,
        locationService: true,
        notification: true,
        batteryOptimization: true,
        missing: [],
      };
    },
    getAppInfo: async () => ({
      appVersion: "2.0.0",
      buildNumber: "42",
      platform: "android",
      locale: "ko-KR",
      theme: "light",
    }),
    getCurrentPosition: async () => ({
      latitude: 37.5663,
      longitude: 126.9779,
      accuracy: 12,
      capturedAt: "2026-07-27T09:00:00Z",
    }),
    getDeviceContacts: async () => [
      {
        id: "contact-1",
        displayName: "엄마",
        phoneNumbers: ["010-1234-5678"],
      },
      {
        id: "contact-2",
        displayName: "회사",
        phoneNumbers: ["02-1234-5678"],
      },
    ],
    getLocationServiceStatus: async () => ({ status: "enabled" }),
    queryGeofences: async () => ({ items: [previewGeofence] }),
    queryNotifications: async () => ({ items: [previewNotification] }),
    queryRecords: async () => ({ items: [previewRecord] }),
  });
}
