import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";

import type { FriendRequest } from "./friend-model";
import { friendService } from "./friend-service";
import { InfiniteLoadButton } from "./InfiniteLoadButton";

export function FriendRequestScreen() {
  const api = useApiClient();
  const [requests, setRequests] = useState<FriendRequest[]>([]);
  const [page, setPage] = useState(0);
  const [hasNext, setHasNext] = useState(false);
  const [status, setStatus] = useState("받은 요청을 불러오는 중입니다.");

  const load = async (nextPage: number, append = false) => {
    try {
      const result = await friendService.requests(api, nextPage);
      setRequests((current) =>
        append ? [...current, ...result.content] : result.content,
      );
      setPage(nextPage);
      setHasNext(result.hasNext);
      setStatus(
        result.content.length === 0 && !append ? "받은 요청이 없어요." : "",
      );
    } catch {
      setStatus("받은 요청을 불러오지 못했습니다.");
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load(0));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api]);

  const respond = async (request: FriendRequest, accept: boolean) => {
    try {
      await (accept
        ? friendService.accept(api, request.id)
        : friendService.reject(api, request.id));
      setRequests((current) =>
        current.filter((item) => item.id !== request.id),
      );
      setStatus(
        accept ? "친구 요청을 수락했습니다." : "친구 요청을 거절했습니다.",
      );
    } catch {
      setStatus("친구 요청을 처리하지 못했습니다.");
    }
  };

  return (
    <main className="feature-page">
      <Link className="feature-page__back" to="/friend">
        ← 친구 목록
      </Link>
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">받은 요청</span>
          <h1>친구 요청</h1>
          <p>요청 메시지를 확인하고 수락하거나 거절하세요.</p>
        </div>
      </header>
      {status && <p aria-live="polite">{status}</p>}
      <ul className="feature-page__list">
        {requests.map((request) => (
          <li className="feature-page__list-card" key={request.id}>
            <div>
              <h2>{request.requester.nickname}</h2>
              <p>{request.requester.email}</p>
              <p>{request.message}</p>
            </div>
            <div className="feature-page__actions">
              <button
                className="ds-button ds-button--primary"
                onClick={() => void respond(request, true)}
                type="button"
              >
                수락
              </button>
              <button
                className="ds-button ds-button--secondary"
                onClick={() => void respond(request, false)}
                type="button"
              >
                거절
              </button>
            </div>
          </li>
        ))}
      </ul>
      <InfiniteLoadButton
        hasNext={hasNext}
        label="요청 더 보기"
        load={() => load(page + 1, true)}
      />
    </main>
  );
}
