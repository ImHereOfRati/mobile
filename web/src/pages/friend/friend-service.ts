import type { ApiClient, SliceResponse } from "@/api/api-client";

import type {
  FriendRequest,
  FriendRequestViewType,
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
  friendship(api: ApiClient, id: string) {
    return api.request<Friendship>(`/api/friendships/${id}`);
  },
  // 상대 기준 관계 조회. 관계 id가 아니라 상대 userId로 묻기 때문에 검색 결과처럼
  // 관계를 아직 모르는 화면에서 쓸 수 있고, 서버는 참·거짓만 돌려준다.
  isFriend(api: ApiClient, targetUserId: string) {
    return api.request<boolean>(`/api/friendships/target/${targetUserId}`);
  },
  isRestricted(api: ApiClient, targetUserId: string) {
    return api.request<boolean>(
      `/api/friends/restrictions/target/${targetUserId}`,
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
  block(api: ApiClient, targetUserId: string) {
    return api.request<FriendRestriction>("/api/friends/restrictions", {
      method: "POST",
      body: JSON.stringify({ targetUserId }),
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
  requests(api: ApiClient, page: number, type: FriendRequestViewType) {
    return api.request<SliceResponse<FriendRequest>>(
      `/api/friends/requests?type=${type}&${pageQuery(page)}`,
    );
  },
  requestDetail(api: ApiClient, id: string) {
    return api.request<FriendRequest>(`/api/friends/requests/${id}`);
  },
  // 받은 요청은 삭제, 보낸 요청은 취소로 서버 경로가 갈린다. 거절과 달리
  // 둘 다 상대에게 제한을 남기지 않고 요청 자체만 없앤다.
  deleteReceived(api: ApiClient, id: string) {
    return api.request<void>(`/api/friends/requests/${id}`, {
      method: "DELETE",
    });
  },
  cancelSent(api: ApiClient, id: string) {
    return api.request<void>(`/api/friends/requests/${id}/sent`, {
      method: "DELETE",
    });
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
  unblock(api: ApiClient, targetUserId: string) {
    return api.request<void>(
      `/api/friends/restrictions/blocked-users/${targetUserId}`,
      { method: "DELETE" },
    );
  },
};
