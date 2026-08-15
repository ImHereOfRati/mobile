import { useEffect, useState } from "react";
import { useApiClient } from "@/api/use-api-client";
import { InfiniteLoadButton } from "@/pages/friend/InfiniteLoadButton";

import {
  notificationService,
  type ServerNotification,
} from "./notification-service";
import { formatActivityTime } from "./record-model";

const PAGE_SIZE = 20;

export function ServerNotificationScreen() {
  const api = useApiClient();
  const [items, setItems] = useState<ServerNotification[]>([]);
  const [page, setPage] = useState(0);
  const [hasNext, setHasNext] = useState(false);
  const [status, setStatus] = useState("알림을 불러오는 중입니다.");

  const load = async (nextPage: number, append = false) => {
    try {
      const received = await notificationService.list(api, nextPage, PAGE_SIZE);
      setItems((current) => (append ? [...current, ...received] : received));
      setPage(nextPage);
      // 서버가 목록만 주고 다음 쪽 여부는 알려주지 않는다. 한 쪽을 가득 채워
      // 받았으면 더 있을 수 있다고 본다.
      setHasNext(received.length === PAGE_SIZE);
      setStatus(
        received.length === 0 && !append ? "계정에 쌓인 알림이 없어요." : "",
      );
    } catch {
      setStatus("알림을 불러오지 못했습니다.");
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load(0));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api]);

  const markAsRead = async (item: ServerNotification) => {
    try {
      await notificationService.markAsRead(api, item.id);
      setItems((current) =>
        current.map((value) =>
          value.id === item.id ? { ...value, isRead: true } : value,
        ),
      );
    } catch {
      setStatus("읽음으로 표시하지 못했습니다.");
    }
  };

  const unreadCount = items.filter((item) => !item.isRead).length;

  return (
    <main className="feature-page" data-clarity-mask="true">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">계정 알림</span>
          <h1>서버 알림함</h1>
          <p>
            기기에 남은 알림과 달리 계정에 쌓인 알림입니다. 기기를 바꿔도 그대로
            남습니다.
          </p>
        </div>
      </header>
      {status && <p aria-live="polite">{status}</p>}
      {unreadCount > 0 && (
        <p aria-live="polite">{`읽지 않은 알림 ${unreadCount}건`}</p>
      )}
      <ul className="feature-page__list">
        {items.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <div className="feature-page__row">
              <div>
                <h2>{item.title}</h2>
                <p>{item.body}</p>
                <p>
                  {`${item.senderAlias} · ${formatActivityTime(item.createdAt)}`}
                </p>
              </div>
              {!item.isRead && (
                <span className="feature-page__chip">안 읽음</span>
              )}
            </div>
            {!item.isRead && (
              <button
                className="ds-button ds-button--secondary"
                onClick={() => void markAsRead(item)}
                type="button"
              >
                읽음으로 표시
              </button>
            )}
          </li>
        ))}
      </ul>
      <InfiniteLoadButton
        hasNext={hasNext}
        label="알림 더 보기"
        load={() => load(page + 1, true)}
      />
    </main>
  );
}
