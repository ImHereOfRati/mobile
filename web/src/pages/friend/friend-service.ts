import type { ApiClient, SliceResponse } from "@/api/api-client";

import type {
  FriendRequest,
  FriendRestriction,
  Friendship,
  UserSearchResult,
} from "./friend-model";

const pageQuery = (page: number, size = 20) => `page=${page}&size=${size}`;

export const friendService = {
  list(api: ApiClient, page: number) {
    return api.request<SliceResponse<Friendship>>(
      `/api/friendships?${pageQuery(page)}`,
    );
  },
  updateAlias(api: ApiClient, id: string, alias: string) {
    return api.request<Friendship>(`/api/friendships/${id}/alias`, {
      method: "PATCH",
      body: JSON.stringify({ alias }),
    });
  },
  delete(api: ApiClient, id: string) {
    return api.request<void>(`/api/friendships/${id}`, { method: "DELETE" });
  },
  block(api: ApiClient, id: string) {
    return api.request<void>(`/api/friendships/${id}/block`, {
      method: "POST",
    });
  },
  search(api: ApiClient, keyword: string, page = 0) {
    return api.request<SliceResponse<UserSearchResult>>(
      `/api/users?keyword=${encodeURIComponent(keyword)}&${pageQuery(page)}`,
    );
  },
  sendRequest(api: ApiClient, targetId: string, message: string) {
    return api.request<{ friendRequestId: string }>("/api/friends/requests", {
      method: "POST",
      body: JSON.stringify({ targetId, message }),
    });
  },
  requests(api: ApiClient, page: number) {
    return api.request<SliceResponse<FriendRequest>>(
      `/api/friends/requests?type=RECEIVED&${pageQuery(page)}`,
    );
  },
  accept(api: ApiClient, id: string) {
    return api.request<Friendship>(`/api/friends/requests/${id}/accept`, {
      method: "POST",
    });
  },
  reject(api: ApiClient, id: string) {
    return api.request<void>(`/api/friends/requests/${id}/reject`, {
      method: "POST",
    });
  },
  restrictions(api: ApiClient, page: number) {
    return api.request<SliceResponse<FriendRestriction>>(
      `/api/friends/restrictions?${pageQuery(page)}`,
    );
  },
  unblock(api: ApiClient, id: string) {
    return api.request<void>(`/api/friends/restrictions/${id}`, {
      method: "DELETE",
    });
  },
};
