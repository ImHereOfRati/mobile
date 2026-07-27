import type { BridgeMethodResult, NativeBridge } from "@imhere/bridge-contract";

import type { ApiClient, SliceResponse } from "@/api/api-client";
import {
  MapProxyService,
  reverseGeocodeLabel,
} from "@/map/map-proxy-service";

import type { Geofence, RecipientOption } from "./geofence-model";

interface FriendUser {
  email: string;
  id: string;
  nickname: string;
  oAuth2Provider: string;
}

interface Friendship {
  friend: FriendUser;
  friendAlias: string;
  id: string;
}

export async function loadGeofences(bridge: NativeBridge) {
  const result = await bridge.queryGeofences({ limit: 100 });
  return result.items;
}

export async function fillMissingGeofenceAddresses(
  bridge: NativeBridge,
  mapService: MapProxyService,
  geofences: Geofence[],
) {
  return Promise.all(
    geofences.map(async (geofence) => {
      if (geofence.address.trim() !== "") return geofence;
      let address = `${geofence.latitude.toFixed(4)}, ${geofence.longitude.toFixed(4)}`;
      try {
        const result = await mapService.reverseGeocode(
          geofence.latitude,
          geofence.longitude,
        );
        address = reverseGeocodeLabel(
          result,
          geofence.latitude,
          geofence.longitude,
        );
      } catch {
        // Coordinate fallback keeps migrated records usable while offline.
      }
      return bridge.updateGeofenceAddress({ id: geofence.id, address });
    }),
  );
}

export async function findGeofence(
  bridge: NativeBridge,
  id: number,
): Promise<Geofence | undefined> {
  return (await loadGeofences(bridge)).find((item) => item.id === id);
}

export async function loadRecipientOptions(
  api: ApiClient,
  bridge: NativeBridge,
) {
  const [friendsResult, contactsResult] = await Promise.allSettled([
    api.request<SliceResponse<Friendship>>("/api/friendships?page=0&size=100"),
    bridge.getDeviceContacts(),
  ]);
  const friends =
    friendsResult.status === "fulfilled" ? friendsResult.value.content : [];
  const contacts =
    contactsResult.status === "fulfilled" ? contactsResult.value : [];

  const serverOptions: RecipientOption[] = friends.map((friendship) => ({
    key: friendship.id,
    label: friendship.friendAlias || friendship.friend.nickname,
    description: friendship.friend.email,
    source: "server",
    value: {
      friendRelationshipId: friendship.id,
      friendEmail: friendship.friend.email,
      friendAlias: friendship.friendAlias || friendship.friend.nickname,
    },
  }));
  const knownPhones = new Set<string>();
  const deviceOptions: RecipientOption[] = contacts.flatMap((contact) => {
    const phone = contact.phoneNumbers[0]?.replace(/\D/g, "");
    if (phone === undefined || phone.length === 0 || knownPhones.has(phone)) {
      return [];
    }
    knownPhones.add(phone);
    return [
      {
        key: contact.id,
        label: contact.displayName,
        description: contact.phoneNumbers.join(", "),
        source: "device",
        value: contact.id,
      },
    ];
  });
  return [...serverOptions, ...deviceOptions];
}

export type AutoSendReadiness = BridgeMethodResult<"getAutoSendReadiness">;
