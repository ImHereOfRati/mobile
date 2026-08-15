import type { BridgeMethodResult, NativeBridge } from "@imhere/bridge-contract";

export type Geofence = BridgeMethodResult<"queryGeofences">["items"][number];
export type EventType = Geofence["eventType"];
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
  deviceContactIds: Set<string>;
  eventType: EventType;
  id?: number;
  latitude: number;
  longitude: number;
  message: string;
  name: string;
  radiusMeters: 250 | 500 | 1000;
  serverRecipientKeys: Set<string>;
}

export const defaultGeofenceDraft: GeofenceDraft = {
  active: true,
  address: "",
  deviceContactIds: new Set(),
  eventType: "arrival",
  latitude: 37.5665,
  longitude: 126.978,
  // {location}은 그대로 두면 사용자에게 토큰이 노출된다. 치환 결과를 기본값으로
  // 두고, 토큰을 쓸 수 있다는 안내는 입력칸 헬퍼 문구가 맡는다.
  message: defaultGeofenceMessage("", "arrival"),
  name: "",
  radiusMeters: 1000,
  serverRecipientKeys: new Set(),
};

export function defaultGeofenceMessage(name: string, eventType: EventType) {
  const location = name.trim() || "장소";
  if (eventType === "departure") {
    return `안녕하세요! ${location}에서 출발했습니다.`;
  }
  return `안녕하세요! ${location}에 도착했습니다.`;
}

/** 서버가 거부하는 SMS 본문 길이. 접두어와 개행까지 포함해서 센다. */
export const smsBodyMaxLength = 45;

const smsBodyPrefix = "[ImHere]\n";

/**
 * 네이티브 `composeSmsBody`(location_label_formatter.dart)와 같은 규칙으로
 * 실제 발송될 SMS 본문을 만든다. 길이 검증에만 쓴다.
 */
export function composeSmsBody(draft: GeofenceDraft) {
  const location = draft.name.trim();
  const message = draft.message.trim();
  const fallback = `${location.length === 0 ? "장소" : location} ${
    draft.eventType === "departure" ? "출발" : "도착"
  }`;
  const body =
    message.length === 0
      ? fallback
      : message.replaceAll("{location}", location);
  return `${smsBodyPrefix}${body}`;
}

/**
 * 서버 한도를 넘기는 방향의 편집인지 판단한다. 이미 한도를 넘긴 상태에서
 * 줄이는 편집까지 막으면 고칠 방법이 없으므로, 길어지는 경우만 막는다.
 */
export function exceedsSmsLimit(current: GeofenceDraft, next: GeofenceDraft) {
  if (next.deviceContactIds.size === 0) return false;
  const nextLength = composeSmsBody(next).length;
  if (nextLength <= smsBodyMaxLength) return false;
  return nextLength > composeSmsBody(current).length;
}

export function draftFromGeofence(geofence: Geofence): GeofenceDraft {
  return {
    active: geofence.active,
    address: geofence.address,
    deviceContactIds: new Set(geofence.deviceContactIds),
    eventType: geofence.eventType === "departure" ? "departure" : "arrival",
    id: geofence.id,
    latitude: geofence.latitude,
    longitude: geofence.longitude,
    message: geofence.message,
    name: geofence.name,
    radiusMeters: geofence.radiusMeters as 250 | 500 | 1000,
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
  if (draft.message.trim().length === 0) {
    errors.message = "알림 메시지를 입력해 주세요.";
  } else if (draft.deviceContactIds.size > 0) {
    // 기기 연락처는 서버 SMS로 나가고, 서버가 45자를 넘으면 거부한다.
    const length = composeSmsBody(draft).length;
    if (length > smsBodyMaxLength) {
      errors.message = `문자 본문이 ${smsBodyMaxLength}자를 넘었어요. (현재 ${length}자, 머리말 ${smsBodyPrefix.length}자 포함)`;
    }
  }
  if (
    draft.deviceContactIds.size === 0 &&
    draft.serverRecipientKeys.size === 0
  ) {
    errors.recipients = "알림을 받을 사람을 한 명 이상 선택해 주세요.";
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
    repeatType: "none",
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
