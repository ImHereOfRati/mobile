import type { ApiClient } from "@/api/api-client";

/**
 * 서버 알림함. 기기에 쌓이는 브릿지 알림(queryNotifications)과는 다른 저장소다.
 * 브릿지 쪽은 이 기기가 실제로 받은 푸시만 남지만, 서버 쪽은 발송 이력 전체를
 * 들고 있어 기기를 바꿔도 남아 있고 읽음 상태를 계정 단위로 공유한다.
 */
export interface ServerNotification {
  body: string;
  createdAt: string;
  id: number;
  isRead: boolean;
  senderAlias: string;
  title: string;
  type: string;
}

/** 서버가 클라이언트 발송을 허용하는 타입(NotificationType.CLIENT_ALLOWED). */
export type SendableNotificationType = "ARRIVAL" | "DEPARTURE" | "LOCATION_TARGET";

export interface SendNotificationInput {
  extraData?: Record<string, string>;
  notificationMethod: "FCM" | "SMS";
  targetIds: string[];
  type: SendableNotificationType;
}

export const notificationService = {
  list(api: ApiClient, page: number, size = 20, signal?: AbortSignal) {
    return api.request<ServerNotification[]>(
      `/api/notifications?page=${page}&size=${size}`,
      { signal },
    );
  },
  markAsRead(api: ApiClient, id: number) {
    return api.request<void>(`/api/notifications/${id}/read`, {
      method: "PATCH",
    });
  },
  // 서버는 요청을 큐에 넣고 202로 답한다. 성공 응답이 곧 전달 완료는 아니다.
  send(api: ApiClient, input: SendNotificationInput) {
    return api.request<string>("/api/notifications", {
      method: "POST",
      body: JSON.stringify({ extraData: {}, ...input }),
    });
  },
};
