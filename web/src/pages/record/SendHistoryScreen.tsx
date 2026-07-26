import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { InfiniteLoadButton } from "@/pages/friend/InfiniteLoadButton";

import { RecordListLayout } from "./NotificationListScreen";
import { formatActivityTime, type DeliveryRecord } from "./record-model";

export function SendHistoryScreen() {
  const bridge = useBridge();
  const [items, setItems] = useState<DeliveryRecord[]>([]);
  const [cursor, setCursor] = useState<string>();
  const [status, setStatus] = useState("전송 기록을 불러오는 중입니다.");

  const load = async (append = false) => {
    try {
      const page = await bridge.queryRecords({
        limit: 20,
        ...(append && cursor ? { cursor } : {}),
      });
      setItems((current) =>
        append ? [...current, ...page.items] : page.items,
      );
      setCursor(page.nextCursor);
      setStatus(
        page.items.length === 0 && !append ? "전송 기록이 없어요." : "",
      );
    } catch {
      setStatus("전송 기록을 불러오지 못했습니다.");
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load());
    return bridge.events.subscribe("onAppResumed", () => void load());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bridge]);

  return (
    <RecordListLayout
      back="/record"
      description="네이티브 자동 전송 파이프라인이 남긴 결과입니다."
      eyebrow="자동 알림"
      title="전송 기록"
    >
      {status && <p aria-live="polite">{status}</p>}
      <ul className="feature-page__list">
        {items.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <Link to={`/record/send-history/${item.id}`}>
              <h2>{item.geofenceName}</h2>
            </Link>
            <p>{item.message}</p>
            <div className="feature-page__meta">
              <span className="feature-page__chip">{item.status}</span>
              <span>{formatActivityTime(item.occurredAt)}</span>
            </div>
          </li>
        ))}
      </ul>
      <InfiniteLoadButton
        hasNext={cursor !== undefined}
        label="전송 기록 더 보기"
        load={() => load(true)}
      />
    </RecordListLayout>
  );
}
