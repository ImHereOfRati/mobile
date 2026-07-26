import type { BridgeMethodResult, NativeBridge } from "@imhere/bridge-contract";

export type Geofence = BridgeMethodResult<"queryGeofences">["items"][number];
export type EventType = Geofence["eventType"];
export type RepeatType = Geofence["repeatType"];
export type ServerRecipient = Geofence["serverRecipients"][number];

export interface RecipientOption {
  description: string;
  key: string;
  label: string;
  source: "device" | "server";
  value: string | ServerRecipient;
}

export interface GeofenceDraft {
  active: boolean;
  address: string;
  customDays: Set<number>;
  deviceContactIds: Set<string>;
  eventType: EventType;
  id?: number;
  latitude: number;
  longitude: number;
  message: string;
  name: string;
  radiusMeters: 250 | 500 | 1000;
  repeatType: RepeatType;
  serverRecipientKeys: Set<string>;
}

export const defaultGeofenceDraft: GeofenceDraft = {
  active: true,
  address: "",
  customDays: new Set(),
  deviceContactIds: new Set(),
  eventType: "arrival",
  latitude: 37.5665,
  longitude: 126.978,
  message: "안녕하세요! {location}에 도착했습니다.",
  name: "",
  radiusMeters: 500,
  repeatType: "none",
  serverRecipientKeys: new Set(),
};

export function draftFromGeofence(geofence: Geofence): GeofenceDraft {
  return {
    active: geofence.active,
    address: geofence.address,
    customDays: daysFromBitmask(geofence.customDaysBitmask),
    deviceContactIds: new Set(geofence.deviceContactIds),
    eventType: geofence.eventType,
    id: geofence.id,
    latitude: geofence.latitude,
    longitude: geofence.longitude,
    message: geofence.message,
    name: geofence.name,
    radiusMeters: geofence.radiusMeters as 250 | 500 | 1000,
    repeatType: geofence.repeatType,
    serverRecipientKeys: new Set(
      geofence.serverRecipients.map(
        (recipient) => recipient.friendRelationshipId,
      ),
    ),
  };
}

export function validateGeofenceDraft(draft: GeofenceDraft) {
  const errors: Record<string, string> = {};
  if (draft.name.trim().length === 0)
    errors.name = "장소 이름을 입력해 주세요.";
  if (draft.address.trim().length === 0)
    errors.address = "지도에서 장소를 선택해 주세요.";
  if (draft.message.trim().length === 0)
    errors.message = "알림 메시지를 입력해 주세요.";
  if (
    draft.deviceContactIds.size === 0 &&
    draft.serverRecipientKeys.size === 0
  ) {
    errors.recipients = "알림을 받을 사람을 한 명 이상 선택해 주세요.";
  }
  if (draft.repeatType === "custom" && draft.customDays.size === 0) {
    errors.customDays = "반복할 요일을 한 개 이상 선택해 주세요.";
  }
  return errors;
}

export function toBridgeInput(
  draft: GeofenceDraft,
  recipients: RecipientOption[],
): Parameters<NativeBridge["registerGeofence"]>[0] {
  return {
    ...(draft.id === undefined ? {} : { id: draft.id }),
    name: draft.name.trim(),
    address: draft.address.trim(),
    latitude: draft.latitude,
    longitude: draft.longitude,
    radiusMeters: draft.radiusMeters,
    eventType: draft.eventType,
    repeatType: draft.repeatType,
    ...(draft.repeatType === "custom"
      ? { customDaysBitmask: bitmaskFromDays(draft.customDays) }
      : {}),
    message: draft.message.trim(),
    active: draft.active,
    deviceContactIds: [...draft.deviceContactIds],
    serverRecipients: recipients.flatMap((recipient) => {
      if (
        recipient.source !== "server" ||
        !draft.serverRecipientKeys.has(recipient.key)
      ) {
        return [];
      }
      return [recipient.value as ServerRecipient];
    }),
  };
}

export function bitmaskFromDays(days: ReadonlySet<number>) {
  return [...days].reduce((mask, day) => mask | (1 << day), 0);
}

export function daysFromBitmask(bitmask?: number) {
  const days = new Set<number>();
  if (bitmask === undefined) return days;
  for (let day = 0; day < 7; day += 1) {
    if ((bitmask & (1 << day)) !== 0) days.add(day);
  }
  return days;
}
