import "./setting.css";
import "@/pages/feature-page.css";

import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { useCallback, useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { SettingsGroup, SettingsRow } from "@/design-system";

type Readiness = BridgeMethodResult<"getAutoSendReadiness">;
type Permission = "locationAlways" | "notification" | "batteryOptimization";

const items: ReadonlyArray<{
  key: Permission;
  label: string;
  description: string;
}> = [
  {
    key: "locationAlways",
    label: "항상 위치 권한",
    description:
      "앱이 닫혀 있어도 설정한 장소의 도착·이탈을 감지하기 위한 백그라운드 위치 사용",
  },
  {
    key: "notification",
    label: "알림 권한",
    description: "자동 전송 결과 알림",
  },
  {
    key: "batteryOptimization",
    label: "배터리 최적화 제외",
    description: "절전 중 감지 유지",
  },
];

export default function AutoSendReadinessPage() {
  const bridge = useBridge();
  const location = useLocation();
  const navigate = useNavigate();
  const returnTo = new URLSearchParams(location.search).get("returnTo");
  const [readiness, setReadiness] = useState<Readiness>();
  const [message, setMessage] = useState("준비 상태를 확인하는 중입니다.");

  const refresh = useCallback(async () => {
    try {
      setReadiness(await bridge.getAutoSendReadiness());
      setMessage("");
    } catch {
      setMessage("준비 상태를 확인하지 못했습니다.");
    }
  }, [bridge]);

  useEffect(() => {
    void Promise.resolve().then(refresh);
    return bridge.events.subscribe("onPermissionChanged", () => void refresh());
  }, [bridge, refresh]);

  useEffect(() => {
    if (readiness?.ready !== true || returnTo !== "/geofence/message") {
      return;
    }
    navigate(returnTo, { replace: true });
  }, [navigate, readiness?.ready, returnTo]);

  async function openPermission(permission: Permission, granted: boolean) {
    try {
      if (permission === "locationAlways" || granted) {
        await bridge.openAppSettings();
      } else await bridge.requestPermission({ permission });
      await refresh();
    } catch {
      setMessage("권한 설정을 열지 못했습니다.");
    }
  }

  return (
    <main className="feature-page auto-send-readiness" data-clarity-mask="true">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">자동 전송</span>
          <h1>자동 전송 준비</h1>
          <p>
            자동 전송을 위해 앱이 닫혀 있거나 사용하지 않는 동안에도 위치 정보를
            사용해 설정한 장소의 도착·이탈을 감지합니다.
          </p>
        </div>
      </header>
      {message ? <p aria-live="polite">{message}</p> : null}
      {readiness && !readiness.ready ? (
        <p className="auto-send-readiness__warning">
          <strong>{readiness.missing.length}개</strong> 설정 필요
        </p>
      ) : null}
      <SettingsGroup title="자동 전송 권한">
        {items.map((item) => {
          const granted = readiness?.[item.key] === true;
          return (
            <SettingsRow
              key={item.key}
              className={granted ? "" : "permission-item--needs-action"}
              label={
                <span>
                  <strong>{item.label}</strong>
                  <small>{item.description}</small>
                </span>
              }
              detail={granted ? "완료" : "허용 안 됨"}
              onClick={() => void openPermission(item.key, granted)}
            />
          );
        })}
      </SettingsGroup>
    </main>
  );
}
