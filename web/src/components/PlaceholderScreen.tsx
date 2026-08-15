import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";

interface PlaceholderScreenProps {
  titleKey: string;
}

const geofences = [
  {
    title: "우리 집",
    address: "서울 성동구 왕십리로 83",
    event: "도착 알림",
    status: "활성",
  },
  {
    title: "강남 파이낸스센터",
    address: "서울 강남구 테헤란로 152",
    event: "출발 알림",
    status: "활성",
  },
  {
    title: "부모님 댁",
    address: "경기 수원시 팔달구 효원로 1",
    event: "도착 알림",
    status: "일시정지",
  },
] as const;

const friends = [
  { name: "김아름", description: "내 도착 알림을 받아요" },
  { name: "박하늘", description: "도착 소식을 함께 나눠요" },
] as const;

const friendCandidates = [
  { name: "정다운", id: "daun.jeong" },
  { name: "한이음", id: "ieum.han" },
] as const;

const records = [
  {
    time: "오후 7:42",
    title: "우리 집에 도착했어요",
    description: "김아름 외 1명에게 전송",
    kind: "도착",
    day: "오늘",
  },
  {
    time: "오후 6:18",
    title: "회사에서 출발했어요",
    description: "박하늘에게 전송",
    kind: "출발",
    day: "오늘",
  },
  {
    time: "오후 2:05",
    title: "부모님 댁에 도착했어요",
    description: "김아름에게 전송",
    kind: "도착",
    day: "어제",
  },
] as const;

function GeofenceContent() {
  return (
    <>
      <h2 className="content-title">알림</h2>
      <section className="screen-section" aria-labelledby="place-list-title">
        <div className="screen-section__heading">
          <h3 id="place-list-title">등록한 장소</h3>
          <span>{geofences.length}</span>
        </div>
        <div className="place-list">
          {geofences.map(({ title, address, event, status }) => (
            <article className="place-row" key={title}>
              <span
                className="place-row__marker"
                data-paused={status === "일시정지"}
                aria-hidden="true"
              />
              <div className="place-row__copy">
                <strong>{title}</strong>
                <p className="place-row__address">{address}</p>
                <span className="place-row__event">{event}</span>
              </div>
              <span data-paused={status === "일시정지"}>{status}</span>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}

function FriendContent() {
  return (
    <>
      <Link
        className="request-summary"
        to="/friend/requests"
        aria-label="새로운 친구 요청 1건 확인하기"
      >
        <span>친구 요청 1건</span>
        <strong>새로운 친구 요청이 왔어요</strong>
      </Link>

      <Link className="friend-discovery-link" to="/friend/add">
        <span>새로운 친구 찾기</span>
        <strong aria-hidden="true">›</strong>
      </Link>

      <section className="screen-section" aria-labelledby="friend-list-title">
        <div className="screen-section__heading">
          <h2 id="friend-list-title">안심 친구</h2>
          <span>{friends.length}</span>
        </div>
        <div className="friend-list">
          {friends.map(({ name, description }) => (
            <article className="friend-row" key={name}>
              <span className="friend-row__avatar" aria-hidden="true">
                {name.slice(0, 1)}
              </span>
              <div>
                <strong>{name}</strong>
                <p>{description}</p>
              </div>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}

function FriendDiscoveryContent() {
  const bridge = useBridge();
  const [query, setQuery] = useState("");
  const [contacts, setContacts] = useState<
    BridgeMethodResult<"getDeviceContacts"> | undefined
  >();
  const [requestedIds, setRequestedIds] = useState<string[]>([]);
  const [loadingContacts, setLoadingContacts] = useState(false);
  const [contactError, setContactError] = useState<string | null>(null);
  const visibleCandidates = useMemo(() => {
    const normalizedQuery = query.trim().toLocaleLowerCase();
    if (normalizedQuery === "") return [];
    return friendCandidates.filter(({ name, id }) =>
      `${name} ${id}`.toLocaleLowerCase().includes(normalizedQuery),
    );
  }, [query]);

  async function loadContacts() {
    setLoadingContacts(true);
    setContactError(null);
    try {
      setContacts(await bridge.getDeviceContacts());
    } catch {
      setContactError(
        "연락처를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.",
      );
    } finally {
      setLoadingContacts(false);
    }
  }

  return (
    <>
      <section
        className="friend-discovery-intro"
        aria-labelledby="friend-discovery-title"
      >
        <span>ImHere 친구</span>
        <h2 id="friend-discovery-title">이름이나 아이디로 찾아보세요</h2>
      </section>

      <label className="screen-search">
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <circle cx="11" cy="11" r="6.5" />
          <path d="m16 16 4 4" />
        </svg>
        <span className="visually-hidden">ImHere 친구 검색</span>
        <input
          value={query}
          placeholder="이름 또는 ImHere 아이디"
          onChange={(event) => setQuery(event.target.value)}
        />
      </label>

      {query.trim() === "" ? null : (
        <section className="candidate-list" aria-label="친구 검색 결과">
          {visibleCandidates.length === 0 ? (
            <p>일치하는 ImHere 친구가 없어요.</p>
          ) : (
            visibleCandidates.map(({ name, id }) => (
              <article key={id}>
                <span aria-hidden="true">{name.slice(0, 1)}</span>
                <div>
                  <strong>{name}</strong>
                  <p>@{id}</p>
                </div>
                <button
                  type="button"
                  disabled={requestedIds.includes(id)}
                  onClick={() => setRequestedIds((current) => [...current, id])}
                >
                  {requestedIds.includes(id) ? "보냄" : "요청"}
                </button>
              </article>
            ))
          )}
        </section>
      )}

      <div className="discovery-divider">
        <span>또는</span>
      </div>

      <button
        className="contact-import-button"
        type="button"
        aria-busy={loadingContacts}
        disabled={loadingContacts}
        onClick={() => void loadContacts()}
      >
        {loadingContacts ? "연락처 불러오는 중" : "연락처에서 가져오기"}
      </button>

      {contactError === null ? null : (
        <p className="discovery-feedback" role="alert">
          {contactError}
        </p>
      )}
      {contacts === undefined ? null : contacts.length === 0 ? (
        <p className="discovery-feedback">가져올 수 있는 연락처가 없어요.</p>
      ) : (
        <section className="contact-list" aria-label="기기 연락처">
          {contacts.map((contact) => (
            <article key={contact.id}>
              <strong>{contact.displayName}</strong>
              <p>{contact.phoneNumbers[0] ?? "전화번호 없음"}</p>
            </article>
          ))}
        </section>
      )}
    </>
  );
}

function FriendRequestsContent() {
  const [requestState, setRequestState] = useState<
    "pending" | "accepted" | "rejected"
  >("pending");

  return (
    <section className="received-request" aria-labelledby="received-request">
      <span className="received-request__eyebrow">받은 요청</span>
      <div className="received-request__person">
        <span aria-hidden="true">이</span>
        <div>
          <h2 id="received-request">이준호</h2>
          <p>@junho.lee</p>
        </div>
      </div>
      {requestState === "pending" ? (
        <>
          <p className="received-request__message">
            안심 소식을 함께 나누고 싶어 해요.
          </p>
          <div className="received-request__actions">
            <button type="button" onClick={() => setRequestState("accepted")}>
              수락
            </button>
            <button type="button" onClick={() => setRequestState("rejected")}>
              거절
            </button>
          </div>
        </>
      ) : (
        <p className="received-request__result" role="status">
          {requestState === "accepted"
            ? "안심 친구가 되었어요."
            : "친구 요청을 거절했어요."}
        </p>
      )}
    </section>
  );
}

function RecordContent() {
  const [filter, setFilter] = useState("전체");
  const visibleRecords = records.filter(
    ({ kind }) => filter === "전체" || filter === kind,
  );
  const days = [...new Set(visibleRecords.map(({ day }) => day))];

  return (
    <>
      <header className="content-heading">
        <h2 className="content-title">기록</h2>
        <p>도착과 출발 알림을 시간순으로 확인할 수 있어요.</p>
      </header>

      <div className="screen-filters" aria-label="기록 필터">
        {["전체", "도착", "출발"].map((item) => (
          <button
            key={item}
            type="button"
            aria-pressed={filter === item}
            onClick={() => setFilter(item)}
          >
            {item}
          </button>
        ))}
      </div>

      <div className="timeline">
        {days.map((day) => (
          <section key={day} aria-labelledby={`record-${day}`}>
            <h3 id={`record-${day}`}>{day}</h3>
            {visibleRecords
              .filter((record) => record.day === day)
              .map((record) => (
                <article className="timeline-row" key={record.title}>
                  <time>{record.time}</time>
                  <span aria-hidden="true" />
                  <div>
                    <strong>{record.title}</strong>
                    <p>{record.description}</p>
                  </div>
                </article>
              ))}
          </section>
        ))}
      </div>
    </>
  );
}

function SettingContent() {
  return (
    <>
      <section className="account-summary" aria-label="내 계정">
        <span className="account-summary__avatar" aria-hidden="true">
          김
        </span>
        <div>
          <strong>김아름</strong>
          <p>Google 계정으로 연결됨</p>
        </div>
      </section>

      <section className="settings-group" aria-labelledby="setting-alerts">
        <h2 id="setting-alerts">알림 및 권한</h2>
        <div className="settings-list">
          <article>
            <div>
              <strong>알림 설정</strong>
              <p>푸시 알림과 전송 결과</p>
            </div>
            <span>켜짐</span>
          </article>
          <article>
            <div>
              <strong>권한 관리</strong>
              <p>위치와 배터리 사용</p>
            </div>
            <span>확인 필요</span>
          </article>
        </div>
      </section>

      <section className="settings-group" aria-labelledby="setting-account">
        <h2 id="setting-account">계정</h2>
        <div className="settings-list">
          <article>
            <div>
              <strong>계정 및 보안</strong>
              <p>로그인 정보와 연결 관리</p>
            </div>
            <span aria-hidden="true">›</span>
          </article>
          <article>
            <div>
              <strong>서비스 정보</strong>
              <p>약관, 개인정보 처리방침, 버전</p>
            </div>
            <span aria-hidden="true">›</span>
          </article>
        </div>
      </section>
    </>
  );
}

function getScreenContent(section: string, screen: string) {
  if (section === "friend") {
    if (screen === "add") return <FriendDiscoveryContent />;
    if (screen === "requests") return <FriendRequestsContent />;
    return <FriendContent />;
  }
  if (section === "record") return <RecordContent />;
  if (section === "setting") return <SettingContent />;
  return <GeofenceContent />;
}

export function PlaceholderScreen({ titleKey }: PlaceholderScreenProps) {
  const { t } = useTranslation();
  const [, sectionKey = "geofence", screenKey = "list"] = titleKey.split(".");

  return (
    <section className={`content-screen content-screen--${sectionKey}`}>
      <h1 className="visually-hidden">{t(titleKey)}</h1>
      {getScreenContent(sectionKey, screenKey)}
    </section>
  );
}
