import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";

import type { FriendRestriction } from "./friend-model";
import { friendService } from "./friend-service";
import { InfiniteLoadButton } from "./InfiniteLoadButton";

export function FriendRestrictionScreen() {
  const api = useApiClient();
  const [items, setItems] = useState<FriendRestriction[]>([]);
  const [page, setPage] = useState(0);
  const [hasNext, setHasNext] = useState(false);
  const [status, setStatus] = useState("차단·거절 목록을 불러오는 중입니다.");

  const load = async (nextPage: number, append = false) => {
    try {
      const result = await friendService.restrictions(api, nextPage);
      setItems((current) =>
        append ? [...current, ...result.content] : result.content,
      );
      setPage(nextPage);
      setHasNext(result.hasNext);
      setStatus(
        result.content.length === 0 && !append ? "제한한 사용자가 없어요." : "",
      );
    } catch {
      setStatus("차단·거절 목록을 불러오지 못했습니다.");
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load(0));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api]);

  const unblock = async (item: FriendRestriction) => {
    if (!window.confirm(`${item.restricted.nickname}님의 제한을 해제할까요?`)) {
      return;
    }
    try {
      await friendService.unblock(api, item.id);
      setItems((current) => current.filter((value) => value.id !== item.id));
      setStatus("제한을 해제했습니다.");
    } catch {
      setStatus("제한을 해제하지 못했습니다.");
    }
  };

  return (
    <main className="feature-page" data-clarity-mask="true">
      <Link className="feature-page__back" to="/friend">
        ← 친구 목록
      </Link>
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">관계 관리</span>
          <h1>차단·거절 관리</h1>
          <p>다시 연결할 수 있도록 기존 제한을 해제할 수 있습니다.</p>
        </div>
      </header>
      {status && <p aria-live="polite">{status}</p>}
      <ul className="feature-page__list">
        {items.map((item) => (
          <li className="feature-page__list-card" key={item.id}>
            <div className="feature-page__row">
              <div>
                <h2>{item.restricted.nickname}</h2>
                <p>{item.restricted.email}</p>
              </div>
              <span className="feature-page__chip">
                {item.type === "BLOCK" ? "차단" : "거절"}
              </span>
            </div>
            <button
              className="ds-button ds-button--secondary"
              onClick={() => void unblock(item)}
              type="button"
            >
              제한 해제
            </button>
          </li>
        ))}
      </ul>
      <InfiniteLoadButton
        hasNext={hasNext}
        label="제한 목록 더 보기"
        load={() => load(page + 1, true)}
      />
    </main>
  );
}
