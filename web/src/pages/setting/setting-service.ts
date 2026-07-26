import type { ApiClient } from "@/api/api-client";

export interface UserMe {
  email: string;
  id: string;
  isActive?: boolean;
  nickname: string;
  oAuth2Provider: string;
  userStatus?: string;
}

export const settingService = {
  me(api: ApiClient) {
    return api.request<UserMe>("/api/users/my");
  },
  changeNickname(api: ApiClient, nickname: string) {
    return api.request<UserMe>("/api/users/my", {
      method: "PATCH",
      body: JSON.stringify({ nickname }),
    });
  },
  withdraw(api: ApiClient) {
    return api.request<void>("/api/users/my/withdrawal", {
      method: "DELETE",
    });
  },
};

export const SUPPORT_URL =
  "https://dsko.notion.site/37c2776ec1898041b254ee2870657dcc?pvs=105";
