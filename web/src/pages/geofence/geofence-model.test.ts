import { describe, expect, it } from "vitest";

import {
  defaultGeofenceMessage,
  defaultGeofenceDraft,
  resolveDraftMessage,
  toBridgeInput,
  type RecipientOption,
} from "./geofence-model";

const recipients: RecipientOption[] = [
  {
    key: "friendship-1",
    label: "민지",
    description: "minji@example.com",
    source: "server",
    value: {
      friendRelationshipId: "friendship-1",
      friendUserId: "friend-1",
      friendEmail: "minji@example.com",
      friendAlias: "민지",
    },
  },
  {
    key: "contact-1",
    label: "가족",
    description: "010-1234-5678",
    source: "device",
    value: "contact-1",
  },
];

describe("geofence model", () => {
  it("builds the editable notification message from the place name", () => {
    expect(defaultGeofenceMessage("서울시청", "arrival")).toBe(
      "안녕하세요! 서울시청에 도착했습니다.",
    );
    expect(defaultGeofenceMessage("서울시청", "departure")).toBe(
      "안녕하세요! 서울시청에서 출발했습니다.",
    );
  });

  it("keeps the typed message when only server recipients are selected", () => {
    expect(
      resolveDraftMessage({
        ...defaultGeofenceDraft,
        name: "회사",
        message: "직접 입력한 알림",
        serverRecipientKeys: new Set(["friendship-1"]),
      }),
    ).toBe("직접 입력한 알림");
  });

  it("fills the locked message from the place name for device recipients", () => {
    expect(
      resolveDraftMessage({
        ...defaultGeofenceDraft,
        name: "회사",
        message: "",
        deviceContactIds: new Set(["contact-1"]),
      }),
    ).toBe("안녕하세요! 회사에 도착했습니다.");
  });

  it("builds a one-shot native payload with both recipient sources", () => {
    const payload = toBridgeInput(
      {
        ...defaultGeofenceDraft,
        name: "회사",
        address: "서울시 중구",
        eventType: "both",
        deviceContactIds: new Set(["contact-1"]),
        serverRecipientKeys: new Set(["friendship-1"]),
      },
      recipients,
    );

    expect(payload).toMatchObject({
      name: "회사",
      address: "서울시 중구",
      eventType: "both",
      repeatType: "none",
      deviceContactIds: ["contact-1"],
      serverRecipients: [
        {
          friendRelationshipId: "friendship-1",
          friendEmail: "minji@example.com",
        },
      ],
    });
  });
});
