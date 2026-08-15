import { useEffect, useState } from "react";
import { useApiClient } from "@/api/use-api-client";

import type { FriendRequest, FriendRequestViewType } from "./friend-model";
import { friendService } from "./friend-service";
import { InfiniteLoadButton } from "./InfiniteLoadButton";

const TABS: { label: string; value: FriendRequestViewType }[] = [
  { value: "RECEIVED", label: "받은 요청" },
  { value: "SENT", label: "보낸 요청" },
];

const EMPTY_TEXT: Record<FriendRequestViewType, string> = {
  RECEIVED: "받은 요청이 없어요.",
  SENT: "보낸 요청이 없어요.",
};

export function FriendRequestScreen() {
  const api = useApiClient();
  const [view, setView] = useState<FriendRequestViewType>("RECEIVED");
  const [requests, setRequests] = useState<FriendRequest[]>([]);
  const [page, setPage] = useState(0);
  const [hasNext, setHasNext] = useState(false);
  const [detail, setDetail] = useState<FriendRequest>();
  const [status, setStatus] = useState("받은 요청을 불러오는 중입니다.");

  const load = async (
    nextPage: number,
    nextView: FriendRequestViewType,
    append = false,
  ) => {
    try {
      const result = await friendService.requests(api, nextPage, nextView);
      setRequests((current) =>
        append ? [...current, ...result.content] : result.content,
      );
      setPage(nextPage);
      setHasNext(result.hasNext);
      setStatus(
        result.content.length === 0 && !append ? EMPTY_TEXT[nextView] : "",
      );
    } catch {
      setStatus("친구 요청을 불러오지 못했습니다.");
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load(0, view));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api, view]);

  const changeView = (nextView: FriendRequestViewType) => {
    if (nextView === view) return;
    setDetail(undefined);
    setRequests([]);
    setView(nextView);
  };

  const drop = (id: string) =>
    setRequests((current) => current.filter((item) => item.id !== id));

  const respond = async (request: FriendRequest, accept: boolean) => {
    try {
      await (accept
        ? friendService.accept(api, request.id)
        : friendService.reject(api, request.id));
      drop(request.id);
      setStatus(
        accept ? "친구 요청을 수락했습니다." : "친구 요청을 거절했습니다.",
      );
    } catch {
      setStatus("친구 요청을 처리하지 못했습니다.");
    }
  };

  // 삭제·취소는 거절과 다르다. 거절은 상대를 제한 목록에 남기지만 이쪽은
  // 요청 자체만 지운다. 되돌릴 수 없어 확인을 받는다.
  const discard = async (request: FriendRequest) => {
    const isSent = view === "SENT";
    const label = isSent ? "취소" : "삭제";
    const counterpart = isSent ? request.receiver : request.requester;
    if (!window.confirm(`${counterpart.nickname}님과의 요청을 ${label}할까요?`))
      return;
    try {
      await (isSent
        ? friendService.cancelSent(api, request.id)
        : friendService.deleteReceived(api, request.id));
      drop(request.id);
      if (detail?.id === request.id) setDetail(undefined);
      setStatus(`요청을 ${label}했습니다.`);
    } catch {
      setStatus(`요청을 ${label}하지 못했습니다.`);
    }
  };

  const openDetail = async (request: FriendRequest) => {
    if (detail?.id === request.id) {
      setDetail(undefined);
      return;
    }
    try {
      setDetail(await friendService.requestDetail(api, request.id));
    } catch {
      setStatus("요청 상세를 불러오지 못했습니다.");
    }
  };

  return (
    <main className="feature-page" data-clarity-mask="true">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">관계 관리</span>
          <h1>친구 요청</h1>
          <p>받은 요청에 답하고, 보낸 요청을 취소할 수 있습니다.</p>
        </div>
      </header>
      <div className="feature-page__actions" role="tablist">
        {TABS.map((tab) => (
          <button
            aria-selected={view === tab.value}
            className={
              view === tab.value
                ? "ds-button ds-button--primary"
                : "ds-button ds-button--secondary"
            }
            key={tab.value}
            onClick={() => changeView(tab.value)}
            role="tab"
            type="button"
          >
            {tab.label}
          </button>
        ))}
      </div>
      {status && <p aria-live="polite">{status}</p>}
      <ul className="feature-page__list">
        {requests.map((request) => {
          const counterpart =
            view === "SENT" ? request.receiver : request.requester;
          const opened = detail?.id === request.id;
          return (
            <li className="feature-page__list-card" key={request.id}>
              <div>
                <h2>{counterpart.nickname}</h2>
                <p>{counterpart.email}</p>
                <p>{request.message}</p>
              </div>
              {opened && detail && (
                <p className="setting-note">
                  {`보낸 사람 ${detail.requester.nickname} · 받는 사람 ${detail.receiver.nickname}`}
                  <br />
                  {`요청 ${detail.createdAt.slice(0, 16).replace("T", " ")}`}
                </p>
              )}
              <div className="feature-page__actions">
                {view === "RECEIVED" && (
                  <>
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
                  </>
                )}
                <button
                  className="ds-button ds-button--secondary"
                  onClick={() => void openDetail(request)}
                  type="button"
                >
                  {opened ? "상세 닫기" : "상세 보기"}
                </button>
                <button
                  className="ds-button ds-button--danger"
                  onClick={() => void discard(request)}
                  type="button"
                >
                  {view === "SENT" ? "요청 취소" : "요청 삭제"}
                </button>
              </div>
            </li>
          );
        })}
      </ul>
      <InfiniteLoadButton
        hasNext={hasNext}
        label="요청 더 보기"
        load={() => load(page + 1, view, true)}
      />
    </main>
  );
}
