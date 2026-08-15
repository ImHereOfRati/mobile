import { describe, expect, it } from "vitest";

import {
  composeSmsBody,
  defaultGeofenceMessage,
  defaultGeofenceDraft,
  exceedsSmsLimit,
  toBridgeInput,
  validateGeofenceDraft,
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

  it("never shows the raw {location} token in the default message", () => {
    expect(defaultGeofenceDraft.message).toBe(
      "안녕하세요! 장소에 도착했습니다.",
    );
  });

  it("blocks only the edits that grow an over-limit SMS body", () => {
    const base = {
      ...defaultGeofenceDraft,
      name: "회사",
      deviceContactIds: new Set(["contact-1"]),
      message: "가".repeat(36),
    };

    expect(exceedsSmsLimit(base, { ...base, message: "가".repeat(37) })).toBe(
      true,
    );
    // 줄이는 편집은 이미 한도를 넘긴 상태에서도 통과해야 한다.
    const overLimit = { ...base, message: "가".repeat(50) };
    expect(
      exceedsSmsLimit(overLimit, { ...overLimit, message: "가".repeat(49) }),
    ).toBe(false);
    // 장소 이름도 {location} 치환과 자동 생성 문구를 통해 본문을 늘린다.
    const withToken = { ...base, message: "{location} 도착" };
    expect(
      exceedsSmsLimit(withToken, { ...withToken, name: "가".repeat(33) }),
    ).toBe(false);
    expect(
      exceedsSmsLimit(withToken, { ...withToken, name: "가".repeat(34) }),
    ).toBe(true);
    // 기기 연락처가 없으면 길이를 재지 않는다.
    expect(
      exceedsSmsLimit(base, {
        ...base,
        deviceContactIds: new Set<string>(),
        message: "가".repeat(200),
      }),
    ).toBe(false);
  });

  it("composes the SMS body exactly like the native formatter", () => {
    expect(
      composeSmsBody({
        ...defaultGeofenceDraft,
        name: "회사",
        message: "{location} 도착",
      }),
    ).toBe("[ImHere]\n회사 도착");
    expect(
      composeSmsBody({
        ...defaultGeofenceDraft,
        name: "회사",
        message: "  ",
        eventType: "departure",
      }),
    ).toBe("[ImHere]\n회사 출발");
  });

  it("rejects an SMS body over the server limit only for device recipients", () => {
    const draft = {
      ...defaultGeofenceDraft,
      name: "회사",
      address: "서울시 중구",
      message: "가".repeat(40),
      serverRecipientKeys: new Set(["friendship-1"]),
    };
    expect(validateGeofenceDraft(draft).message).toBeUndefined();

    const smsDraft = {
      ...draft,
      deviceContactIds: new Set(["contact-1"]),
    };
    expect(validateGeofenceDraft(smsDraft).message).toBe(
      "문자 본문이 45자를 넘었어요. (현재 49자, 머리말 9자 포함)",
    );
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
