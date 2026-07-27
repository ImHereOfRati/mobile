import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useBridge } from "@/bridge/bridge-context";
import type { FriendRequest } from "@/pages/friend/friend-model";
import { friendService } from "@/pages/friend/friend-service";

import {
  formatActivityTime,
  formatDeliveryStatus,
  type DeliveryRecord,
  type NativeNotification,
} from "./record-model";

export function RecordOverviewScreen() {
  const api = useApiClient();
  const bridge = useBridge();
  const [notifications, setNotifications] = useState<NativeNotification[]>([]);
  const [records, setRecords] = useState<DeliveryRecord[]>([]);
  const [requests, setRequests] = useState<FriendRequest[]>([]);
  const [status, setStatus] = useState("활동 기록을 불러오는 중입니다.");

  const refresh = async () => {
    const [notificationResult, recordResult, requestResult] =
      await Promise.allSettled([
        bridge.queryNotifications({ limit: 3 }),
        bridge.queryRecords({ limit: 3 }),
        friendService.requests(api, 0),
      ]);
    setNotifications(
      notificationResult.status === "fulfilled"
        ? notificationResult.value.items
        : [],
    );
    setRecords(
      recordResult.status === "fulfilled" ? recordResult.value.items : [],
    );
    setRequests(
      requestResult.status === "fulfilled"
        ? requestResult.value.content.slice(0, 3)
        : [],
    );
    setStatus(
      [notificationResult, recordResult, requestResult].every(
        (result) => result.status === "rejected",
      )
        ? "활동 기록을 불러오지 못했습니다."
        : "",
    );
  };

  useEffect(() => {
    void Promise.resolve().then(refresh);
    return bridge.events.subscribe("onAppResumed", () => {
      void refresh();
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api, bridge]);

  return (
    <main className="feature-page" data-clarity-mask="true">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">최근 활동</span>
          <h1>기록</h1>
          <p>받은 알림, 친구 요청, 자동 전송 결과를 확인하세요.</p>
        </div>
        <button
          className="ds-button ds-button--secondary"
          onClick={() => void refresh()}
          type="button"
        >
          새로고침
        </button>
      </header>
      {status && <p aria-live="polite">{status}</p>}

      <ActivitySection
        empty="최근 받은 알림이 없어요."
        link="/record/notifications"
        title="받은 알림"
      >
        {notifications.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <h3>{item.title}</h3>
            <p>{item.body}</p>
            <small>{formatActivityTime(item.createdAt)}</small>
          </li>
        ))}
      </ActivitySection>

      <ActivitySection
        empty="대기 중인 친구 요청이 없어요."
        link="/record/friend-requests"
        title="친구 요청"
      >
        {requests.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <h3>{item.requester.nickname}</h3>
            <p>{item.message}</p>
            <small>{formatActivityTime(item.createdAt)}</small>
          </li>
        ))}
      </ActivitySection>

      <ActivitySection
        empty="자동 전송 기록이 없어요."
        link="/record/send-history"
        title="전송 기록"
      >
        {records.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <h3>{item.geofenceName}</h3>
            <p>{item.message}</p>
            <div className="feature-page__meta">
              <span className="feature-page__chip">
                {formatDeliveryStatus(item.status)}
              </span>
              <small>{formatActivityTime(item.occurredAt)}</small>
            </div>
          </li>
        ))}
      </ActivitySection>
    </main>
  );
}

function ActivitySection({
  title,
  link,
  empty,
  children,
}: {
  children: React.ReactNode;
  empty: string;
  link: string;
  title: string;
}) {
  const hasChildren = Array.isArray(children)
    ? children.length > 0
    : !!children;
  return (
    <section aria-labelledby={`activity-${link}`}>
      <div className="feature-page__section-header">
        <h2 id={`activity-${link}`}>{title}</h2>
        <Link to={link}>전체 보기</Link>
      </div>
      {hasChildren ? (
        <ul className="feature-page__list">{children}</ul>
      ) : (
        <p>{empty}</p>
      )}
    </section>
  );
}
