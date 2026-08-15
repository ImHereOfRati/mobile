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
  // 계정 삭제는 서버에만 있는 상태라 여기서 직접 부른다. 기기에 남은 토큰은
  // 성공한 뒤 bridge.signOut()으로 지운다 — 브릿지의 withdraw가 하던 것과 같은
  // 두 단계인데, 어느 쪽이 실패했는지 화면에서 구분할 수 있게 나눠 둔다.
  withdraw(api: ApiClient) {
    return api.request<void>("/api/users/my/withdrawal", { method: "DELETE" });
  },
};

export const SUPPORT_URL =
  "https://dsko.notion.site/37c2776ec1898041b254ee2870657dcc?pvs=105";
