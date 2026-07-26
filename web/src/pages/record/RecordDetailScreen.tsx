import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";

import {
  formatActivityTime,
  type DeliveryRecord,
  type NativeNotification,
} from "./record-model";

export function RecordDetailScreen({
  kind,
}: {
  kind: "notification" | "record";
}) {
  const bridge = useBridge();
  const params = useParams();
  const id = Number(params.recordId);
  const [item, setItem] = useState<
    DeliveryRecord | NativeNotification | undefined
  >();
  const [status, setStatus] = useState("상세 기록을 불러오는 중입니다.");

  useEffect(() => {
    void Promise.resolve().then(async () => {
      try {
        const page =
          kind === "notification"
            ? await bridge.queryNotifications({ limit: 100 })
            : await bridge.queryRecords({ limit: 100 });
        const found = page.items.find((value) => value.id === id);
        setItem(found);
        setStatus(found ? "" : "기록을 찾지 못했습니다.");
      } catch {
        setStatus("상세 기록을 불러오지 못했습니다.");
      }
    });
  }, [bridge, id, kind]);

  const back =
    kind === "notification" ? "/record/notifications" : "/record/send-history";
  return (
    <main className="feature-page">
      <Link className="feature-page__back" to={back}>
        ← 목록으로
      </Link>
      {status && <p aria-live="polite">{status}</p>}
      {item && (
        <article className="feature-page__list-card">
          <span className="feature-page__eyebrow">
            {kind === "notification" ? "받은 알림" : "전송 기록"}
          </span>
          <h1>{"title" in item ? item.title : item.geofenceName}</h1>
          <p>{"body" in item ? item.body : item.message}</p>
          <dl>
            <dt>시간</dt>
            <dd>
              {formatActivityTime(
                "createdAt" in item ? item.createdAt : item.occurredAt,
              )}
            </dd>
            {"senderNickname" in item && item.senderNickname && (
              <>
                <dt>보낸 사람</dt>
                <dd>{item.senderNickname}</dd>
              </>
            )}
            {"status" in item && (
              <>
                <dt>상태</dt>
                <dd>{item.status}</dd>
              </>
            )}
          </dl>
        </article>
      )}
    </main>
  );
}
