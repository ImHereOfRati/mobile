import {
  useCallback,
  useEffect,
  useMemo,
  useReducer,
  useRef,
  useState,
} from "react";

import { JourneyMap, type JourneyMapHandle } from "@/landing/JourneyMap";
import {
  destinationById,
  destinations,
  initialLandingFlowState,
  landingFlowReducer,
} from "@/landing/landing-flow";

type DemoEvent = {
  id: number;
  type: "depart" | "arrive";
  title: string;
  message: string;
  time: string;
};

type Toast = {
  id: number;
  type?: "arrive";
  title: string;
  message: string;
};

function InstallDialog({ onClose }: { onClose: () => void }) {
  return (
    <div
      className="install-dialog-backdrop"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <section
        className="install-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="install-dialog-title"
      >
        <div className="install-dialog__header">
          <span>체험 완료</span>
          <button
            className="install-dialog__close"
            type="button"
            aria-label="설치 팝업 닫기"
            onClick={onClose}
          >
            ×
          </button>
        </div>
        <h2 id="install-dialog-title">ImHere 설치</h2>
        <div className="download-actions">
          <a
            href="https://play.google.com/store/apps/details?id=com.kdongsu5509.iamhere"
            target="_blank"
            rel="noopener noreferrer"
          >
            <span aria-hidden="true">▶</span>
            <span>
              <small>Google Play</small>
              <strong>다운로드</strong>
            </span>
          </a>
          <button type="button" disabled aria-label="App Store 출시 예정">
            <span aria-hidden="true">●</span>
            <span>
              <small>App Store</small>
              <strong>출시 예정</strong>
            </span>
          </button>
        </div>
      </section>
    </div>
  );
}

function nowLabel() {
  return new Intl.DateTimeFormat("ko-KR", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date());
}

export function LandingPage() {
  const [flow, dispatch] = useReducer(
    landingFlowReducer,
    initialLandingFlowState,
  );
  const [departureEnabled, setDepartureEnabled] = useState(true);
  const [arrivalEnabled, setArrivalEnabled] = useState(true);
  const [events, setEvents] = useState<DemoEvent[]>([]);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [showDownload, setShowDownload] = useState(false);
  const mapRef = useRef<JourneyMapHandle>(null);
  const nextIdRef = useRef(1);
  const destination = destinationById(flow.destination);

  useEffect(() => {
    if (!showDownload) return;

    const previousOverflow = document.body.style.overflow;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setShowDownload(false);
    };
    document.body.style.overflow = "hidden";
    document.addEventListener("keydown", closeOnEscape);
    window.setTimeout(() => {
      document
        .querySelector<HTMLButtonElement>(".install-dialog__close")
        ?.focus();
    }, 0);

    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", closeOnEscape);
    };
  }, [showDownload]);

  const pushToast = useCallback(
    (title: string, message: string, type?: "arrive") => {
      const id = nextIdRef.current;
      nextIdRef.current += 1;
      setToasts([{ id, title, message, type }]);
      window.setTimeout(() => {
        setToasts((current) => current.filter((toast) => toast.id !== id));
      }, 4_200);
    },
    [],
  );

  const addEvent = useCallback(
    (type: DemoEvent["type"], title: string, message: string) => {
      const id = nextIdRef.current;
      nextIdRef.current += 1;
      setEvents((current) => [
        { id, type, title, message, time: nowLabel() },
        ...current,
      ]);
      pushToast(title, message, type === "arrive" ? "arrive" : undefined);
    },
    [pushToast],
  );

  const acceptFriend = () => {
    dispatch({ type: "accept-friend" });
    pushToast("친구 연결", "철수 연결 완료");
  };

  const savePlace = () => {
    dispatch({ type: "save-place" });
    pushToast(
      "장소·알림 대상 설정",
      `${destination.label} · 철수 · ${flow.radius}m`,
    );
  };

  const toggleRun = () => {
    if (flow.progress >= 1) {
      mapRef.current?.resetRoute();
    }
    dispatch({ type: "toggle-run" });
    if (!flow.running) {
      document
        .querySelector(".map-stage")
        ?.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  };

  const resetRoute = () => {
    mapRef.current?.resetRoute();
    dispatch({ type: "reset-route" });
  };

  const handleDeparture = useCallback(() => {
    if (!departureEnabled) return;
    addEvent("depart", "출발", "광화문");
  }, [addEvent, departureEnabled]);

  const handleArrival = useCallback(() => {
    dispatch({ type: "arrive" });
    if (arrivalEnabled) {
      addEvent("arrive", "도착", `${destination.label} · ${flow.radius}m`);
    }
    pushToast("체험 완료", "앱에서 계속", "arrive");
    setShowDownload(true);
  }, [addEvent, arrivalEnabled, destination.label, flow.radius, pushToast]);

  const liveStatus = useMemo(() => {
    if (!flow.friendAccepted) return "친구 연결 전";
    if (!flow.placeConfigured) return "장소 선택 전";
    if (flow.progress >= 1) return `${destination.label} 도착`;
    if (flow.running) return `${destination.label} 이동 중`;
    if (flow.progress > 0) return "일시 정지";
    return "출발 준비";
  }, [
    destination.label,
    flow.friendAccepted,
    flow.placeConfigured,
    flow.progress,
    flow.running,
  ]);

  const distanceLabel = useMemo(() => {
    if (!flow.friendAccepted) return "대기 중";
    if (!flow.placeConfigured) return "친구 연결됨";
    if (flow.progress >= 1) return "도착";
    if (flow.progress === 0) return "출발 전";
    const totalDistance = flow.destination === "cityhall" ? 1_280 : 930;
    const remaining = Math.max(
      0,
      Math.round((1 - flow.progress) * totalDistance),
    );
    return remaining >= 1_000
      ? `${(remaining / 1_000).toFixed(1)}km 남음`
      : `${remaining}m 남음`;
  }, [
    flow.destination,
    flow.friendAccepted,
    flow.placeConfigured,
    flow.progress,
  ]);

  const progressWidth =
    flow.step === "friend"
      ? "33.333%"
      : flow.step === "place"
        ? "66.666%"
        : "100%";

  return (
    <div className={flow.completed ? "landing is-complete" : "landing"}>
      <header className="topbar">
        <a className="brand" href="/" aria-label="ImHere 홈">
          <strong>ImHere</strong>
        </a>
      </header>

      <main>
        <section className="product-intro" aria-labelledby="product-title">
          <div>
            <p className="eyebrow">위치 기반 서비스</p>
            <h1 id="product-title">ImHere</h1>
            <ul className="product-points">
              <li>위치 기반</li>
              <li>안심 귀가</li>
              <li>자동 알림</li>
            </ul>
            <a className="product-cta" href="#experience">
              체험
              <span aria-hidden="true">↓</span>
            </a>
          </div>
        </section>

        <section
          className="experience"
          id="experience"
          aria-labelledby="experience-title"
        >
          <header className="experience-heading">
            <p className="eyebrow">3단계 체험</p>
            <h2 id="experience-title">철수에게 귀가 알림을 보내보세요</h2>
          </header>

          <div className="workspace">
            <aside className="panel setup-panel" aria-label="체험 설정">
              <h3>알림 설정</h3>
              <div className="progress-track" aria-hidden="true">
                <div
                  className="progress-fill"
                  style={{ width: progressWidth }}
                />
              </div>

              <section
                className={`setup-step ${
                  flow.step === "friend" ? "is-active" : "is-complete"
                }`}
              >
                <span className="step-number">
                  {flow.friendAccepted ? "✓" : "1"}
                </span>
                <h2>친구 연결</h2>
                {flow.step === "friend" ? (
                  <div className="step-body">
                    <div className="request-card">
                      <div className="request-person">
                        <span className="friend-avatar">철</span>
                        <span>
                          <strong>철수</strong>
                          <small>귀가 알림 요청</small>
                        </span>
                      </div>
                      <div className="button-row">
                        <button
                          className="button button--quiet"
                          type="button"
                          onClick={() =>
                            pushToast("친구 연결 필요", "수락 후 계속")
                          }
                        >
                          나중에
                        </button>
                        <button
                          className="button button--primary"
                          type="button"
                          onClick={acceptFriend}
                        >
                          수락하기
                        </button>
                      </div>
                    </div>
                  </div>
                ) : (
                  <strong className="step-summary">철수와 연결되었어요</strong>
                )}
              </section>

              <section
                className={`setup-step ${
                  flow.step === "place"
                    ? "is-active"
                    : flow.placeConfigured
                      ? "is-complete"
                      : ""
                }`}
              >
                <span className="step-number">
                  {flow.placeConfigured ? "✓" : "2"}
                </span>
                <h2>장소·알림 대상 선택</h2>
                {flow.step === "place" ? (
                  <div className="step-body">
                    <div className="place-options" role="radiogroup">
                      {destinations.map((place) => (
                        <button
                          key={place.id}
                          className={
                            flow.destination === place.id ? "is-selected" : ""
                          }
                          type="button"
                          role="radio"
                          aria-checked={flow.destination === place.id}
                          onClick={() =>
                            dispatch({
                              type: "select-destination",
                              destination: place.id,
                            })
                          }
                        >
                          <span aria-hidden="true">
                            {place.id === "cityhall"
                              ? "▦"
                              : place.id === "station"
                                ? "▣"
                                : "▤"}
                          </span>
                          {place.shortLabel}
                        </button>
                      ))}
                    </div>
                    <div
                      className="recipient-picker"
                      role="radiogroup"
                      aria-labelledby="recipient-picker-label"
                    >
                      <span
                        className="recipient-picker__label"
                        id="recipient-picker-label"
                      >
                        알림 대상
                      </span>
                      <button
                        className={flow.recipientSelected ? "is-selected" : ""}
                        type="button"
                        role="radio"
                        aria-checked={flow.recipientSelected}
                        onClick={() => dispatch({ type: "select-recipient" })}
                      >
                        <span className="friend-avatar" aria-hidden="true">
                          철
                        </span>
                        <span className="recipient-picker__copy">
                          <strong>철수</strong>
                          <small>연결된 친구</small>
                        </span>
                        <span className="recipient-picker__state">
                          {flow.recipientSelected ? "선택됨" : "선택"}
                        </span>
                      </button>
                    </div>
                    <div className="setting-box">
                      <label className="field-label" htmlFor="radius-range">
                        <span>알림 반경</span>
                        <strong>{flow.radius}m</strong>
                      </label>
                      <input
                        id="radius-range"
                        type="range"
                        min="100"
                        max="300"
                        step="50"
                        value={flow.radius}
                        onChange={(event) =>
                          dispatch({
                            type: "set-radius",
                            radius: Number(event.target.value),
                          })
                        }
                      />
                      <label className="check-row">
                        <input
                          type="checkbox"
                          checked={departureEnabled}
                          onChange={(event) =>
                            setDepartureEnabled(event.target.checked)
                          }
                        />
                        광화문 출발 알림 받기
                      </label>
                      <label className="check-row">
                        <input
                          type="checkbox"
                          checked={arrivalEnabled}
                          onChange={(event) =>
                            setArrivalEnabled(event.target.checked)
                          }
                        />
                        선택 장소 도착 알림 받기
                      </label>
                    </div>
                    <button
                      className="button button--primary button--wide"
                      type="button"
                      disabled={!flow.recipientSelected}
                      onClick={savePlace}
                    >
                      장소와 알림 대상 설정
                    </button>
                  </div>
                ) : flow.placeConfigured ? (
                  <strong className="step-summary">
                    {destination.label} · 철수 · 반경 {flow.radius}m
                  </strong>
                ) : null}
              </section>

              <section
                className={`setup-step ${flow.step === "run" ? "is-active" : ""}`}
              >
                <span className="step-number">3</span>
                <h2>귀가 시작</h2>
                {flow.step === "run" && (
                  <div className="step-body">
                    <div className="simulation-actions">
                      <button
                        className="button button--primary"
                        type="button"
                        onClick={toggleRun}
                      >
                        <span aria-hidden="true">
                          {flow.running ? "❚❚" : "▶"}
                        </span>
                        {flow.running ? "잠시 멈춤" : "이동 시작"}
                      </button>
                      <button
                        className="button icon-button"
                        type="button"
                        aria-label="경로 처음부터"
                        onClick={resetRoute}
                      >
                        ↻
                      </button>
                    </div>
                    <div className="speed-control" aria-label="재생 속도">
                      {[1, 2, 4].map((speed) => (
                        <button
                          key={speed}
                          className={flow.speed === speed ? "is-selected" : ""}
                          type="button"
                          aria-pressed={flow.speed === speed}
                          onClick={() => dispatch({ type: "set-speed", speed })}
                        >
                          {speed}×
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </section>
            </aside>

            <section
              className="map-stage"
              aria-label="철수의 이동 경로 3D 지도"
            >
              <JourneyMap
                ref={mapRef}
                destination={flow.destination}
                radius={flow.radius}
                friendAccepted={flow.friendAccepted}
                running={flow.running}
                speed={flow.speed}
                onProgress={(progress) =>
                  dispatch({ type: "set-progress", progress })
                }
                onDeparture={handleDeparture}
                onArrival={handleArrival}
              />
              <div className="map-toolbar">
                <div className="map-controls">
                  <button
                    type="button"
                    aria-label="지도 확대"
                    onClick={() => mapRef.current?.zoomIn()}
                  >
                    +
                  </button>
                  <button
                    type="button"
                    aria-label="지도 축소"
                    onClick={() => mapRef.current?.zoomOut()}
                  >
                    −
                  </button>
                  <button
                    type="button"
                    aria-label="지도 위치 초기화"
                    onClick={() => mapRef.current?.resetView()}
                  >
                    ⌖
                  </button>
                </div>
              </div>
              <div className="live-card" aria-live="polite">
                <div className="live-head">
                  <div className="live-person">
                    <span className="friend-avatar">철</span>
                    <span>
                      <strong>철수</strong>
                      <small>{liveStatus}</small>
                    </span>
                  </div>
                  <strong className="live-distance">{distanceLabel}</strong>
                </div>
                <div
                  className="route-progress"
                  role="progressbar"
                  aria-label="귀가 경로 진행률"
                  aria-valuemin={0}
                  aria-valuemax={100}
                  aria-valuenow={Math.round(flow.progress * 100)}
                >
                  <span style={{ width: `${flow.progress * 100}%` }} />
                </div>
              </div>
              <span className="map-help">
                드래그하여 회전 · 스크롤하여 확대
              </span>
            </section>

            <aside className="panel activity-panel" aria-label="안심 알림 내역">
              <div className="activity-head">
                <h2>안심 알림</h2>
                <button
                  className="text-button"
                  type="button"
                  disabled={events.length === 0}
                  onClick={() => setEvents([])}
                >
                  모두 지우기
                </button>
              </div>
              {events.length === 0 ? (
                <div className="empty-state">
                  <span className="empty-icon" aria-hidden="true">
                    ♢
                  </span>
                  <strong>아직 도착한 알림이 없어요</strong>
                  <p>출발·도착 시 바로 알림</p>
                </div>
              ) : (
                <ol className="timeline">
                  {events.map((event) => (
                    <li key={event.id} className="event">
                      <span
                        className={`event-icon ${
                          event.type === "arrive" ? "is-arrival" : ""
                        }`}
                        aria-hidden="true"
                      >
                        {event.type === "arrive" ? "✓" : "↗"}
                      </span>
                      <div className="event-content">
                        <strong>{event.title}</strong>
                        <p>{event.message}</p>
                        <time>오늘 {event.time}</time>
                      </div>
                    </li>
                  ))}
                </ol>
              )}
            </aside>
          </div>
        </section>
      </main>

      {flow.completed && (
        <button
          className="feature-cue"
          type="button"
          onClick={() => {
            setShowDownload(true);
          }}
        >
          설치하기 <span aria-hidden="true">→</span>
        </button>
      )}

      {showDownload && <InstallDialog onClose={() => setShowDownload(false)} />}

      <div className="toast-stack" aria-live="assertive">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`toast ${toast.type === "arrive" ? "is-arrival" : ""}`}
          >
            <strong>{toast.title}</strong>
            <span>{toast.message}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
