import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useBridge } from "@/bridge/bridge-context";

import {
  groupFriends,
  mergeFriends,
  type Friendship,
  type UnifiedFriend,
} from "./friend-model";
import { friendService } from "./friend-service";
import { InfiniteLoadButton } from "./InfiniteLoadButton";

export function FriendListScreen() {
  const api = useApiClient();
  const bridge = useBridge();
  const [relationships, setRelationships] = useState<Friendship[]>([]);
  const [contacts, setContacts] = useState<
    Awaited<ReturnType<typeof bridge.getDeviceContacts>>
  >([]);
  const [hasNext, setHasNext] = useState(false);
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const load = async (nextPage: number, append = false) => {
    setError("");
    try {
      const [friendPage, deviceContacts] = await Promise.all([
        friendService.list(api, nextPage),
        nextPage === 0 ? bridge.getDeviceContacts() : Promise.resolve(contacts),
      ]);
      setRelationships((current) =>
        append ? [...current, ...friendPage.content] : friendPage.content,
      );
      if (nextPage === 0) setContacts(deviceContacts);
      setPage(nextPage);
      setHasNext(friendPage.hasNext);
    } catch {
      setError("친구 목록을 불러오지 못했습니다.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load(0));
    // The first request is intentionally bound to the current bridge/API pair.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api, bridge]);

  const groups = useMemo(
    () => groupFriends(mergeFriends(relationships, contacts)),
    [contacts, relationships],
  );

  const mutateRelationship = async (
    item: Extract<UnifiedFriend, { kind: "server" }>,
    action: "alias" | "delete" | "block",
  ) => {
    try {
      if (action === "alias") {
        const alias = window
          .prompt("새 별명을 입력하세요.", item.displayName)
          ?.trim();
        if (!alias) return;
        const updated = await friendService.updateAlias(
          api,
          item.relationship.id,
          alias,
        );
        setRelationships((current) =>
          current.map((value) => (value.id === updated.id ? updated : value)),
        );
        return;
      }
      const label = action === "delete" ? "삭제" : "차단";
      if (!window.confirm(`${item.displayName}님을 ${label}할까요?`)) return;
      await (action === "delete"
        ? friendService.delete(api, item.relationship.id)
        : friendService.block(api, item.relationship.id));
      setRelationships((current) =>
        current.filter((value) => value.id !== item.relationship.id),
      );
    } catch {
      setError("친구 정보를 변경하지 못했습니다.");
    }
  };

  return (
    <main className="feature-page">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">연락처</span>
          <h1>친구</h1>
          <p>ImHere 친구와 기기 연락처를 한곳에서 확인하세요.</p>
        </div>
        <Link className="ds-button ds-button--primary" to="/friend/add">
          친구 추가
        </Link>
      </header>

      <nav aria-label="친구 관리" className="feature-page__actions">
        <Link className="ds-button ds-button--secondary" to="/friend/requests">
          받은 친구 요청
        </Link>
        <Link
          className="ds-button ds-button--secondary"
          to="/friend/restrictions"
        >
          차단·거절 관리
        </Link>
      </nav>

      {error && (
        <p className="feature-page__error" role="alert">
          {error}
        </p>
      )}
      {loading ? (
        <p aria-live="polite">친구 목록을 불러오는 중입니다.</p>
      ) : groups.size === 0 ? (
        <section className="feature-page__list-card">
          <h2>아직 등록된 친구가 없어요</h2>
          <p>닉네임이나 이메일로 친구를 찾아 요청을 보내보세요.</p>
        </section>
      ) : (
        [...groups].map(([group, items]) => (
          <section aria-labelledby={`friend-group-${group}`} key={group}>
            <h2 id={`friend-group-${group}`}>{group}</h2>
            <ul className="feature-page__list">
              {items.map((item) => (
                <li className="feature-page__list-card" key={item.id}>
                  <div className="feature-page__row">
                    <div>
                      <h3>{item.displayName}</h3>
                      <p>{item.description || "전화번호 없음"}</p>
                    </div>
                    <span className="feature-page__chip">
                      {item.kind === "server" ? "ImHere" : "기기"}
                    </span>
                  </div>
                  {item.kind === "server" && (
                    <div className="feature-page__actions">
                      <button
                        className="ds-button ds-button--secondary"
                        onClick={() => void mutateRelationship(item, "alias")}
                        type="button"
                      >
                        별명 수정
                      </button>
                      <button
                        className="ds-button ds-button--secondary"
                        onClick={() => void mutateRelationship(item, "delete")}
                        type="button"
                      >
                        삭제
                      </button>
                      <button
                        className="ds-button ds-button--danger"
                        onClick={() => void mutateRelationship(item, "block")}
                        type="button"
                      >
                        차단
                      </button>
                    </div>
                  )}
                </li>
              ))}
            </ul>
          </section>
        ))
      )}
      <InfiniteLoadButton
        hasNext={hasNext}
        label="친구 더 보기"
        load={() => load(page + 1, true)}
      />
    </main>
  );
}
