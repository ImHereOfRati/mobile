import { type FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";

import type { UserSearchResult } from "./friend-model";
import { friendService } from "./friend-service";

export function FriendAddScreen() {
  const api = useApiClient();
  const bridge = useBridge();
  const analytics = useAnalytics();
  const [keyword, setKeyword] = useState("");
  const [message, setMessage] = useState("ImHere에서 친구가 되어 주세요.");
  const [results, setResults] = useState<UserSearchResult[]>([]);
  const [contacts, setContacts] = useState<
    Awaited<ReturnType<typeof bridge.getDeviceContacts>>
  >([]);
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    void bridge
      .getDeviceContacts()
      .then(setContacts)
      .catch(() => setContacts([]));
  }, [bridge]);

  const search = async (event: FormEvent) => {
    event.preventDefault();
    if (!keyword.trim()) return;
    setLoading(true);
    setStatus("");
    try {
      const page = await friendService.search(api, keyword.trim());
      setResults(page.content);
      if (page.content.length === 0) setStatus("검색 결과가 없습니다.");
    } catch {
      setStatus("사용자를 검색하지 못했습니다.");
    } finally {
      setLoading(false);
    }
  };

  const send = async (user: UserSearchResult) => {
    setStatus("");
    try {
      await friendService.sendRequest(api, user.id, message.trim());
      await analytics.track("friend_request_sent", { source: "search" });
      setStatus(`${user.nickname}님에게 친구 요청을 보냈습니다.`);
      setResults((current) => current.filter((item) => item.id !== user.id));
    } catch {
      setStatus("친구 요청을 보내지 못했습니다.");
    }
  };

  return (
    <main className="feature-page" data-clarity-mask="true">
      <Link className="feature-page__back" to="/friend">
        ← 친구 목록
      </Link>
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">새 연결</span>
          <h1>친구 추가</h1>
          <p>이메일이나 닉네임으로 ImHere 사용자를 찾아보세요.</p>
        </div>
      </header>
      <form className="feature-form" onSubmit={search}>
        <label className="ds-field">
          <span className="ds-field__label">이메일 또는 닉네임</span>
          <input
            className="ds-field__input"
            onChange={(event) => setKeyword(event.target.value)}
            required
            value={keyword}
          />
        </label>
        <label className="ds-field">
          <span className="ds-field__label">요청 메시지</span>
          <textarea
            className="ds-field__input"
            maxLength={200}
            onChange={(event) => setMessage(event.target.value)}
            value={message}
          />
        </label>
        <button
          aria-busy={loading}
          className="ds-button ds-button--primary"
          disabled={loading}
          type="submit"
        >
          검색
        </button>
      </form>
      {status && <p aria-live="polite">{status}</p>}
      {results.length > 0 && (
        <section aria-labelledby="friend-search-results">
          <h2 id="friend-search-results">검색 결과</h2>
          <ul className="feature-page__list">
            {results.map((user) => (
              <li className="feature-page__list-card" key={user.id}>
                <div>
                  <h3>{user.nickname}</h3>
                  <p>{user.email}</p>
                </div>
                <button
                  className="ds-button ds-button--primary"
                  onClick={() => void send(user)}
                  type="button"
                >
                  요청 보내기
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}
      <section aria-labelledby="device-contact-heading">
        <div className="feature-page__section-header">
          <div>
            <h2 id="device-contact-heading">기기 연락처 가져오기</h2>
            <p>연락처를 선택하면 검색어에 전화번호를 채웁니다.</p>
          </div>
        </div>
        <ul className="feature-page__list">
          {contacts.slice(0, 20).map((contact) => (
            <li className="feature-page__list-card" key={contact.id}>
              <div className="feature-page__row">
                <div>
                  <h3>{contact.displayName}</h3>
                  <p>{contact.phoneNumbers.join(", ") || "전화번호 없음"}</p>
                </div>
                <button
                  className="ds-button ds-button--secondary"
                  disabled={!contact.phoneNumbers[0]}
                  onClick={() => setKeyword(contact.phoneNumbers[0] ?? "")}
                  type="button"
                >
                  검색에 사용
                </button>
              </div>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
