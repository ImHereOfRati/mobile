import type { NativeBridge } from "@imhere/bridge-contract";
import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { Button, LoadingState } from "@/design-system";

type Readiness = Awaited<ReturnType<NativeBridge["getAutoSendReadiness"]>>;

const permissionCopy = {
  locationAlways: ["항상 위치 허용", "앱이 닫혀 있어도 장소 도착을 감지해요."],
  notification: ["알림 허용", "전송 결과와 도착 알림을 알려드려요."],
  batteryOptimization: [
    "배터리 최적화 예외",
    "Android에서 자동 전송이 중단되지 않게 해요.",
  ],
} as const;

export default function PermissionPage() {
  const bridge = useBridge();
  const navigate = useNavigate();
  const [readiness, setReadiness] = useState<Readiness | null>(null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const value = await bridge.getAutoSendReadiness();
      setReadiness(value);
      if (value.ready) navigate("/geofence", { replace: true });
    } catch {
      setError("권한 상태를 확인하지 못했습니다.");
    }
  }, [bridge, navigate]);

  useEffect(() => {
    const initialRefresh = setTimeout(() => void refresh(), 0);
    const unsubscribeResume = bridge.events.subscribe("onAppResumed", () => {
      void refresh();
    });
    const unsubscribePermission = bridge.events.subscribe(
      "onPermissionChanged",
      () => void refresh(),
    );
    return () => {
      clearTimeout(initialRefresh);
      unsubscribeResume();
      unsubscribePermission();
    };
  }, [bridge, refresh]);

  async function request(permission: keyof typeof permissionCopy) {
    await bridge.requestPermission({ permission });
    await refresh();
  }

  return (
    <main className="onboarding">
      <section className="onboarding__panel" aria-labelledby="permission-title">
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">자동 전송 준비</p>
          <h1 id="permission-title">필요한 권한을 확인해 주세요</h1>
          <p className="onboarding__description">
            권한 요청은 앱에서만 처리되며 언제든 설정에서 바꿀 수 있어요.
          </p>
        </header>
        {readiness === null && error === null ? (
          <LoadingState label="권한 상태를 확인하는 중" />
        ) : (
          <div className="onboarding__list">
            {Object.entries(permissionCopy).map(
              ([permission, [title, description]]) => {
                const complete =
                  permission === "locationAlways"
                    ? readiness?.locationAlways
                    : permission === "notification"
                      ? readiness?.notification
                      : readiness?.batteryOptimization;
                return (
                  <article key={permission} className="onboarding__permission">
                    <span aria-hidden="true">{complete ? "✓" : "○"}</span>
                    <div>
                      <strong>{title}</strong>
                      <p className="onboarding__meta">{description}</p>
                    </div>
                    <Button
                      variant={complete ? "ghost" : "secondary"}
                      disabled={complete}
                      onClick={() =>
                        void request(permission as keyof typeof permissionCopy)
                      }
                    >
                      {complete ? "완료" : "설정"}
                    </Button>
                  </article>
                );
              },
            )}
          </div>
        )}
        <div className="onboarding__permission-actions">
          <Link to="/location-permission-guide">위치 권한 안내</Link>
          <Link to="/battery-optimization-guide">배터리 설정 안내</Link>
        </div>
        <Button onClick={() => void refresh()}>상태 다시 확인</Button>
        {error === null ? null : (
          <p className="onboarding__error" role="alert">
            {error}
          </p>
        )}
      </section>
    </main>
  );
}
