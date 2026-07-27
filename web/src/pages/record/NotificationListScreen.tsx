import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { InfiniteLoadButton } from "@/pages/friend/InfiniteLoadButton";

import { formatActivityTime, type NativeNotification } from "./record-model";

export function NotificationListScreen() {
  const bridge = useBridge();
  const [items, setItems] = useState<NativeNotification[]>([]);
  const [cursor, setCursor] = useState<string>();
  const [status, setStatus] = useState("알림을 불러오는 중입니다.");

  const load = async (append = false) => {
    try {
      const page = await bridge.queryNotifications({
        limit: 20,
        ...(append && cursor ? { cursor } : {}),
      });
      setItems((current) =>
        append ? [...current, ...page.items] : page.items,
      );
      setCursor(page.nextCursor);
      setStatus(
        page.items.length === 0 && !append ? "받은 알림이 없어요." : "",
      );
    } catch {
      setStatus("알림을 불러오지 못했습니다.");
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
      description="기기에 안전하게 저장된 푸시 알림입니다."
      eyebrow="수신함"
      title="받은 알림"
    >
      {status && <p aria-live="polite">{status}</p>}
      <ul className="feature-page__list">
        {items.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <Link to={`/record/notifications/${item.id}`}>
              <h2>{item.title}</h2>
            </Link>
            <p>{item.body}</p>
            <small>{formatActivityTime(item.createdAt)}</small>
          </li>
        ))}
      </ul>
      <InfiniteLoadButton
        hasNext={cursor !== undefined}
        label="알림 더 보기"
        load={() => load(true)}
      />
    </RecordListLayout>
  );
}

export function RecordListLayout({
  back,
  eyebrow,
  title,
  description,
  children,
}: {
  back: string;
  children: React.ReactNode;
  description: string;
  eyebrow: string;
  title: string;
}) {
  return (
    <main className="feature-page" data-clarity-mask="true">
      <Link className="feature-page__back" to={back}>
        ← 기록
      </Link>
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">{eyebrow}</span>
          <h1>{title}</h1>
          <p>{description}</p>
        </div>
      </header>
      {children}
    </main>
  );
}
