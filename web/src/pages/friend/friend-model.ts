import type { BridgeMethodResult } from "@imhere/bridge-contract";

type DeviceContact = BridgeMethodResult<"getDeviceContacts">[number];

export interface FriendUser {
  email: string;
  id: string;
  nickname: string;
  oAuth2Provider: string;
}

export interface Friendship {
  createdAt: string;
  friend: FriendUser;
  friendAlias: string;
  id: string;
  owner: FriendUser;
  updatedAt: string;
}

/** 서버 FriendRequestViewType. 받은 요청과 보낸 요청은 같은 목록 API를 공유한다. */
export type FriendRequestViewType = "RECEIVED" | "SENT";

export interface FriendRequest {
  createdAt: string;
  id: string;
  message: string;
  receiver: FriendUser;
  requester: FriendUser;
  updatedAt: string;
}

export interface FriendRestriction {
  createdAt: string;
  expiredAt?: string;
  id: string;
  restricted: FriendUser;
  restrictor: FriendUser;
  type: string;
  updatedAt: string;
}

export type UserSearchResult = FriendUser;

export type UnifiedFriend =
  | {
      description: string;
      displayName: string;
      id: string;
      kind: "server";
      relationship: Friendship;
    }
  | {
      contact: DeviceContact;
      description: string;
      displayName: string;
      id: string;
      kind: "device";
    };

const initials = [
  "ㄱ",
  "ㄲ",
  "ㄴ",
  "ㄷ",
  "ㄸ",
  "ㄹ",
  "ㅁ",
  "ㅂ",
  "ㅃ",
  "ㅅ",
  "ㅆ",
  "ㅇ",
  "ㅈ",
  "ㅉ",
  "ㅊ",
  "ㅋ",
  "ㅌ",
  "ㅍ",
  "ㅎ",
] as const;

export function getNameGroup(name: string) {
  const first = name.trim().charAt(0);
  if (first.length === 0) return "#";
  const code = first.charCodeAt(0);
  if (code >= 0xac00 && code <= 0xd7a3) {
    return initials[Math.floor((code - 0xac00) / 588)] ?? "#";
  }
  if (/[a-z]/i.test(first)) return first.toUpperCase();
  if (/\d/.test(first)) return "0-9";
  return "#";
}

export function mergeFriends(
  relationships: Friendship[],
  contacts: DeviceContact[],
) {
  const items: UnifiedFriend[] = [
    ...relationships.map((relationship): UnifiedFriend => ({
      id: relationship.id,
      kind: "server",
      displayName:
        relationship.friendAlias.trim() || relationship.friend.nickname,
      description: relationship.friend.email,
      relationship,
    })),
    ...contacts.map((contact): UnifiedFriend => ({
      id: `device:${contact.id}`,
      kind: "device",
      displayName: contact.displayName,
      description: contact.phoneNumbers.join(", "),
      contact,
    })),
  ];

  return items.sort((left, right) =>
    left.displayName.localeCompare(right.displayName, "ko"),
  );
}

export function groupFriends(items: UnifiedFriend[]) {
  return items.reduce<Map<string, UnifiedFriend[]>>((groups, item) => {
    const key = getNameGroup(item.displayName);
    groups.set(key, [...(groups.get(key) ?? []), item]);
    return groups;
  }, new Map());
}
