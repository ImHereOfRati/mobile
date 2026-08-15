import { type FormEvent, useState } from "react";

import { useApiClient } from "@/api/use-api-client";
import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";
import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { Button } from "@/design-system";

import type { UserSearchResult } from "./friend-model";
import { friendService } from "./friend-service";

type RelationState = "friend" | "none" | "restricted";

const RELATION_LABEL: Record<RelationState, string> = {
  friend: "이미 친구",
  restricted: "차단·거절함",
  none: "",
};

type DeviceContact = BridgeMethodResult<"getDeviceContacts">[number];

interface FriendFinderProps {
  onContactSelected?: (contact: DeviceContact) => void;
}

export function FriendFinder({ onContactSelected }: FriendFinderProps) {
  const api = useApiClient();
  const analytics = useAnalytics();
  const bridge = useBridge();
  const [keyword, setKeyword] = useState("");
  const [message, setMessage] = useState("ImHere에서 친구가 되어 주세요.");
  const [results, setResults] = useState<UserSearchResult[]>([]);
  const [selectedUser, setSelectedUser] = useState<UserSearchResult | null>(
    null,
  );
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);
  const [relations, setRelations] = useState(new Map<string, RelationState>());
  const [contactsLoading, setContactsLoading] = useState(false);

  /**
   * 검색 결과만으로는 이미 친구인지, 내가 차단한 상대인지 알 수 없다. 서버에
   * 상대 기준으로 되물어 이름 옆에 상태를 붙인다. 실패한 항목은 그냥 상태
   * 표시가 없는 채로 두고 검색 자체를 막지 않는다.
   */
  const resolveRelations = async (users: UserSearchResult[]) => {
    const entries = await Promise.all(
      users.map(async (user): Promise<[string, RelationState]> => {
        const [friend, restricted] = await Promise.allSettled([
          friendService.isFriend(api, user.id),
          friendService.isRestricted(api, user.id),
        ]);
        // 서버는 참·거짓만 준다. truthy 검사로 두면 형태가 다른 응답까지
        // 관계 있음으로 읽혀 선택 버튼이 잠긴다.
        if (friend.status === "fulfilled" && friend.value === true) {
          return [user.id, "friend"];
        }
        if (restricted.status === "fulfilled" && restricted.value === true) {
          return [user.id, "restricted"];
        }
        return [user.id, "none"];
      }),
    );
    setRelations(new Map(entries));
  };

  const search = async (event: FormEvent) => {
    event.preventDefault();
    if (!keyword.trim()) return;
    setLoading(true);
    setStatus("");
    setSelectedUser(null);
    setRelations(new Map());
    try {
      const page = await friendService.search(api, keyword.trim());
      setResults(page.content);
      if (page.content.length === 0) setStatus("검색 결과가 없습니다.");
      else await resolveRelations(page.content);
    } catch {
      setStatus("사용자를 검색하지 못했습니다.");
    } finally {
      setLoading(false);
    }
  };

  const send = async (event: FormEvent) => {
    event.preventDefault();
    if (selectedUser === null) return;

    setStatus("");
    setLoading(true);
    try {
      await friendService.sendRequest(api, selectedUser.id, message.trim());
      await analytics.track("friend_request_sent", { source: "search" });
      setStatus(`${selectedUser.nickname}님에게 친구 요청을 보냈습니다.`);
      setResults((current) =>
        current.filter((item) => item.id !== selectedUser.id),
      );
      setSelectedUser(null);
    } catch {
      setStatus("친구 요청을 보내지 못했습니다.");
    } finally {
      setLoading(false);
    }
  };

  const importContacts = async () => {
    setContactsLoading(true);
    setStatus("");
    try {
      const selected = await bridge.pickDeviceContact();
      if (selected === null) {
        setStatus("연락처 선택을 취소했습니다.");
        return;
      }
      onContactSelected?.(selected);
      setStatus(`${selected.displayName} 연락처를 추가했습니다.`);
    } catch {
      setStatus("연락처를 가져오지 못했습니다. 권한을 확인해주세요.");
    } finally {
      setContactsLoading(false);
    }
  };

  return (
    <div className="friend-finder" data-clarity-mask="true">
      {selectedUser === null ? (
        <form className="friend-finder__form" onSubmit={search}>
          <label className="ds-field">
            <span className="ds-field__label">닉네임 또는 이메일</span>
            <input
              className="ds-field__input"
              onChange={(event) => setKeyword(event.target.value)}
              placeholder="닉네임 또는 이메일"
              required
              value={keyword}
            />
          </label>
          <Button loading={loading} type="submit">
            검색
          </Button>
          <Button
            loading={contactsLoading}
            onClick={() => void importContacts()}
            type="button"
            variant="secondary"
          >
            연락처로 추가
          </Button>
        </form>
      ) : (
        <form className="friend-finder__form" onSubmit={send}>
          <div className="friend-finder__selection">
            <div>
              <strong>{selectedUser.nickname}</strong>
              <span>{selectedUser.email}</span>
            </div>
            <Button
              disabled={loading}
              onClick={() => {
                setSelectedUser(null);
                setStatus("");
              }}
              variant="ghost"
            >
              다시 선택
            </Button>
          </div>
          <label className="ds-field">
            <span className="ds-field__label">요청 메시지</span>
            <textarea
              className="ds-field__input"
              maxLength={200}
              onChange={(event) => setMessage(event.target.value)}
              value={message}
            />
          </label>
          <Button loading={loading} type="submit">
            친구 요청 보내기
          </Button>
        </form>
      )}
      {status && (
        <p className="friend-finder__status" aria-live="polite">
          {status}
        </p>
      )}
      {selectedUser === null && results.length > 0 && (
        <section
          className="friend-finder__results"
          aria-labelledby="friend-search-results"
        >
          <h2 id="friend-search-results">검색 결과</h2>
          <ul className="feature-page__list">
            {results.map((user) => {
              const relation = relations.get(user.id) ?? "none";
              return (
                <li
                  className="feature-page__list-card friend-finder__result"
                  key={user.id}
                >
                  <div>
                    <h3>{user.nickname}</h3>
                    <p>{user.email}</p>
                    {relation !== "none" && (
                      <span className="feature-page__chip">
                        {RELATION_LABEL[relation]}
                      </span>
                    )}
                  </div>
                  <Button
                    disabled={relation !== "none"}
                    onClick={() => {
                      setSelectedUser(user);
                      setStatus("");
                    }}
                    variant="secondary"
                  >
                    선택
                  </Button>
                </li>
              );
            })}
          </ul>
        </section>
      )}
    </div>
  );
}
