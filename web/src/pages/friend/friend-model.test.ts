import { describe, expect, it } from "vitest";

import { getNameGroup, groupFriends, mergeFriends } from "./friend-model";

describe("friend grouping", () => {
  it("derives Korean initial consonants and fallback groups", () => {
    expect(getNameGroup("김하나")).toBe("ㄱ");
    expect(getNameGroup("박둘")).toBe("ㅂ");
    expect(getNameGroup("alice")).toBe("A");
    expect(getNameGroup("7번")).toBe("0-9");
  });

  it("merges server friendships and device contacts before grouping", () => {
    const users = mergeFriends(
      [
        {
          id: "friendship-1",
          friendAlias: "가족",
          friend: {
            id: "friend-1",
            email: "friend@example.com",
            nickname: "친구",
            oAuth2Provider: "KAKAO",
          },
          owner: {
            id: "me",
            email: "me@example.com",
            nickname: "나",
            oAuth2Provider: "KAKAO",
          },
          createdAt: "2026-07-26T00:00:00Z",
          updatedAt: "2026-07-26T00:00:00Z",
        },
      ],
      [{ id: "contact-1", displayName: "나연", phoneNumbers: ["01012345678"] }],
    );

    expect(users.map((item) => item.kind)).toEqual(["server", "device"]);
    expect([...groupFriends(users).keys()]).toEqual(["ㄱ", "ㄴ"]);
  });
});
