import { describe, expect, it } from "vitest";

import {
  bitmaskFromDays,
  defaultGeofenceDraft,
  daysFromBitmask,
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
  it("round-trips a custom weekday bitmask", () => {
    const days = new Set([1, 3, 5]);
    expect(daysFromBitmask(bitmaskFromDays(days))).toEqual(days);
  });

  it("builds the native payload with both recipient sources", () => {
    const payload = toBridgeInput(
      {
        ...defaultGeofenceDraft,
        name: "회사",
        address: "서울시 중구",
        eventType: "both",
        repeatType: "custom",
        customDays: new Set([1, 2, 3, 4, 5]),
        deviceContactIds: new Set(["contact-1"]),
        serverRecipientKeys: new Set(["friendship-1"]),
      },
      recipients,
    );

    expect(payload).toMatchObject({
      name: "회사",
      address: "서울시 중구",
      eventType: "both",
      repeatType: "custom",
      customDaysBitmask: 62,
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
