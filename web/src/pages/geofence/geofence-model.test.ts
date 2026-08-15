import { describe, expect, it } from "vitest";

import {
  defaultGeofenceDraft,
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
