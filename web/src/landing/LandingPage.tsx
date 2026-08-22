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

const landingShareData = {
  title: "ImHere | 위치 기반 서비스",
  text: "친구의 출발과 도착 순간만 알려주는 위치 기반 알림 서비스 ImHere.",
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

function PrivacyPolicySection() {
  return (
    <section className="privacy-policy" aria-labelledby="privacy-policy-title">
      <div className="privacy-policy__inner">
        <p className="eyebrow">ImHere 개인정보 보호</p>
        <h2 id="privacy-policy-title">ImHere 개인정보처리방침</h2>
        <p className="privacy-policy__updated">최종 수정일: 2026년 6월 29일</p>
        <p className="privacy-policy__intro">
          ImHere(이하 &quot;본 앱&quot;)은 사용자의 개인정보 보호를 중요하게
          생각합니다. 본 방침은 본 앱이 수집·이용·보관·보호하는 개인정보와 외부
          서비스 이용 내용을 설명합니다.
        </p>
        <div className="privacy-policy__sections">
          <details>
            <summary>1. 수집하는 개인정보 항목</summary>
            <p>
              계정 정보(이메일, 닉네임, 로그인 제공자, 제공자 식별값, 회원
              상태), 인증·보안 정보(세션·refresh token 관련 정보), 친구 관계와
              요청 정보, 알림 정보(대상, 제목, 본문, 발송 상태), FCM 토큰과 기기
              종류를 처리합니다. 위치 권한이 허용되고 기능이 활성화되면 지오펜스
              위치·반경, 도착·이탈 이벤트와 알림에 필요한 위치 관련 정보가
              처리될 수 있습니다. 사용자가 선택한 연락처의 이름과 전화번호는
              기기에서 처리하며 SMS 발송이 필요한 경우에만 발송 과정에서 전송될
              수 있습니다.
            </p>
          </details>
          <details>
            <summary>2. 개인정보 수집 방법</summary>
            <p>
              소셜 로그인, 사용자의 직접 입력(닉네임·지오펜스·연락처), 기기
              권한을 통한 위치·연락처 처리, FCM 토큰 등록, 서비스 이용 과정에서
              생성되는 친구·알림·오류 정보를 통해 수집합니다.
            </p>
          </details>
          <details>
            <summary>3. 개인정보의 수집 및 이용 목적</summary>
            <p>
              사용자 인증과 계정 관리, 친구 관계 관리, 지오펜스 기반 도착·이탈
              감지, 푸시·문자 알림 발송, 발송 실패 재시도와 중복 방지, 보안·장애
              대응 및 고객 문의 처리를 위해 이용합니다. 선택적 분석에 동의한
              경우 서비스 이용 통계와 기능 개선에도 이용합니다.
            </p>
          </details>
          <details>
            <summary>4. 개인정보의 보유 및 이용 기간</summary>
            <p>
              계정 정보는 회원 탈퇴 시까지 보유하며 법령상 보존이 필요한
              경우에는 해당 기간 동안 분리 보관합니다. refresh token과 FCM
              토큰은 만료·교체· 회원 탈퇴·무효화 시 삭제합니다. 친구·알림·동의
              이력은 서비스 제공, 권리 보호와 분쟁 대응에 필요한 기간 동안
              보관할 수 있습니다. 위치 관련 정보는 기능 제공에 필요한 최소 기간
              동안만 처리합니다. 기기 내 연락처와 지오펜스 설정은 사용자가
              권한·설정을 삭제하거나 앱을 삭제하면 기기에서 삭제됩니다.
            </p>
          </details>
          <details>
            <summary>5. 개인정보의 제3자 제공</summary>
            <p>
              원칙적으로 개인정보를 판매하거나 목적 외로 제공하지 않습니다. 다만
              로그인 제공자(Kakao, Google, Apple), 푸시 알림(Firebase Cloud
              Messaging), 문자 발송(Solapi 등)을 위해 각 서비스에 필요한 정보가
              전송될 수 있습니다. SMS 발송 시 수신 전화번호와 메시지 내용이 문자
              발송 사업자에 전달될 수 있습니다.
              <br />
              <a
                href="https://www.kakao.com/policy/privacy"
                target="_blank"
                rel="noreferrer"
              >
                Kakao 개인정보처리방침
              </a>
            </p>
          </details>
          <details>
            <summary>6. 개인정보의 처리 위탁</summary>
            <p>
              본 앱은 서비스 제공을 위해 위 5항의 외부 서비스 사업자를
              이용합니다. 사업자별 처리 항목과 목적은 해당 사업자의
              개인정보처리방침 및 서비스 설정에 따라 달라질 수 있습니다.
            </p>
          </details>
          <details>
            <summary>7. 개인정보의 파기</summary>
            <p>
              보유기간이 지나거나 처리 목적이 달성되면 지체 없이 파기합니다.
              회원 탈퇴 시 계정과 기기 내 저장 정보를 삭제하고, 법령·분쟁 대응에
              필요한 정보는 해당 기간이 끝난 뒤 복구할 수 없도록 삭제합니다.
            </p>
          </details>
          <details>
            <summary>8. 사용자 권리</summary>
            <p>
              사용자는 개인정보 열람·정정·삭제·처리정지, 동의 철회와 회원 탈퇴를
              요청할 수 있습니다. 앱 내 설정 메뉴 또는 아래 개인정보 보호
              문의처를 통해 요청해 주세요. 위치 권한을 철회하면 위치 기반 알림
              기능이 제한될 수 있습니다.
            </p>
          </details>
          <details>
            <summary>9. 개인정보 보호책임자</summary>
            <p>
              개인정보 보호 관련 문의는 아래 연락처로 요청해 주세요.
              <br />
              이메일: [개인정보 보호책임자 이메일 주소를 입력하세요]
              <br />
              전화번호: [개인정보 보호책임자 전화번호를 입력하세요]
            </p>
          </details>
          <details>
            <summary>10. 개인정보의 안전성 확보 조치</summary>
            <p>
              접근 권한 관리, 인증·토큰 보호, 전송·저장 구간의 보안 조치, 접근
              통제, 로그와 운영 권한 관리, 보안 프로그램과 내부 관리 절차를
              적용합니다.
            </p>
          </details>
          <details>
            <summary>11. 위치 정보 처리</summary>
            <p>
              GPS 기반 현재 위치와 사용자가 설정한 지오펜스 위치·반경을
              도착·이탈 감지와 위치 기반 알림에 이용합니다. 백그라운드 위치는
              사용자가 명시적으로 허용하고 해당 기능을 활성화한 경우에만
              처리하며, 기능 제공에 필요한 최소 범위로 제한합니다.
            </p>
          </details>
          <details>
            <summary>12. 연락처 정보 처리</summary>
            <p>
              사용자가 선택한 연락처의 이름과 전화번호를 SMS 수신자 관리와 알림
              발송에 이용합니다. 연락처 전체 목록은 기능에 필요한 경우에만
              기기에서 읽으며, SMS 발송 과정 외에는 서버로 전송하지 않습니다.
            </p>
          </details>
          <details>
            <summary>13. SMS 전송 기능</summary>
            <p>
              Android에서는 사용자의 권한과 기기 정책에 따라 자동 SMS를 발송할
              수 있고, iOS에서는 SMS 앱을 열어 사용자가 직접 전송합니다. 기기
              발송이 아닌 백업 서버 발송이 사용되는 경우 전화번호와 메시지
              내용이 문자 발송 사업자로 전송될 수 있습니다.
            </p>
          </details>
          <details>
            <summary>14. 쿠키 및 추적 기술</summary>
            <p>
              본 앱은 필수 서비스 제공 외의 분석 도구를 선택 동의 없이
              활성화하지 않습니다. 선택적 분석에 동의한 경우 Google Analytics
              4와 Microsoft Clarity가 서비스 이용 이벤트, 브라우저·기기와 접속
              환경 정보를 처리할 수 있습니다.
            </p>
          </details>
          <details>
            <summary>15. 아동의 개인정보 보호</summary>
            <p>
              본 앱은 만 14세 미만 아동을 대상으로 하지 않으며, 해당 아동의
              개인정보를 고의로 수집하지 않습니다.
            </p>
          </details>
          <details>
            <summary>16. 개인정보처리방침 변경</summary>
            <p>
              법령, 서비스, 외부 사업자 또는 보안 기술의 변경에 따라 본 방침을
              수정할 수 있습니다. 중요한 변경은 시행 전에 앱 또는 웹사이트를
              통해 안내합니다.
            </p>
          </details>
        </div>
      </div>
    </section>
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
  const [shareStatus, setShareStatus] = useState("");
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

  const shareLanding = useCallback(async () => {
    const url = window.location.href;

    try {
      if (typeof navigator.share === "function") {
        await navigator.share({ ...landingShareData, url });
        setShareStatus("공유 창을 열었어요.");
        return;
      }

      if (navigator.clipboard) {
        await navigator.clipboard.writeText(url);
        setShareStatus("링크를 복사했어요.");
        return;
      }

      setShareStatus("주소창의 링크를 복사해 공유해 주세요.");
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      setShareStatus("공유하지 못했어요. 주소창의 링크를 복사해 주세요.");
    }
  }, []);

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
        <div className="topbar__share">
          <button className="share-button" type="button" onClick={shareLanding}>
            공유하기
          </button>
          <span className="sr-only" role="status" aria-live="polite">
            {shareStatus}
          </span>
        </div>
      </header>

      <main>
        <section className="product-intro" aria-labelledby="product-title">
          <div>
            <p className="eyebrow">위치 기반 서비스</p>
            <h1 id="product-title">ImHere</h1>
            <ul className="product-points">
              <li>위치 기반</li>
              <li>위치 기반 알림</li>
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
            <h2 id="experience-title">철수에게 위치 알림을 보내보세요</h2>
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
                          <small>위치 알림 요청</small>
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
                <h2>이동 시작</h2>
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
                  aria-label="이동 경로 진행률"
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

            <aside className="panel activity-panel" aria-label="위치 알림 내역">
              <div className="activity-head">
                <h2>위치 알림</h2>
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

        <section className="seo-support" aria-labelledby="seo-support-title">
          <div className="seo-support__inner">
            <p className="eyebrow">ImHere 위치 기반 알림</p>
            <h2 id="seo-support-title">
              친구의 도착을 기다리는 가장 간편한 방법
            </h2>
            <p className="seo-support__lead">
              ImHere는 서로 수락한 친구에게 출발과 도착 순간을 알려주는 위치
              기반 알림 서비스입니다. 목적지와 알림 반경을 설정하면 지오펜싱이
              위치 변화를 감지하고, 필요한 순간에 푸시 알림과 문자 알림을
              전달합니다.
            </p>
            <div className="seo-support__grid">
              <article>
                <h3>친구 위치 알림</h3>
                <p>
                  이동 중인 친구의 출발과 도착 정보를 필요한 순간에 전달합니다.
                </p>
              </article>
              <article>
                <h3>지오펜싱 자동 알림</h3>
                <p>
                  정해 둔 장소와 반경을 기준으로 출발·도착 알림을 자동
                  처리합니다.
                </p>
              </article>
              <article>
                <h3>푸시와 문자 전달</h3>
                <p>
                  ImHere 친구에게는 푸시로, 앱이 없는 상대에게는 문자로
                  알립니다.
                </p>
              </article>
            </div>
            <div className="seo-faq" aria-label="ImHere 자주 묻는 질문">
              <details>
                <summary>ImHere는 어떤 서비스인가요?</summary>
                <p>
                  친구의 출발과 목적지 도착을 자동으로 알려주는 위치 기반 알림
                  서비스입니다.
                </p>
              </details>
              <details>
                <summary>상대방도 ImHere를 설치해야 하나요?</summary>
                <p>
                  ImHere 친구에게는 푸시 알림을 보내고, 앱이 없는 상대에게는
                  문자 알림을 보낼 수 있습니다.
                </p>
              </details>
            </div>
          </div>
        </section>
        <PrivacyPolicySection />
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
