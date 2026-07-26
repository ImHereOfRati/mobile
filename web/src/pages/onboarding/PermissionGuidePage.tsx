import { useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { Button } from "@/design-system";

export default function PermissionGuidePage({
  kind,
}: {
  kind: "location" | "battery";
}) {
  const bridge = useBridge();
  const navigate = useNavigate();
  const location = kind === "location";

  async function openSettings() {
    await bridge.requestPermission({
      permission: location ? "locationAlways" : "batteryOptimization",
    });
  }

  return (
    <main className="onboarding">
      <section className="onboarding__panel" aria-labelledby="guide-title">
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">설정 안내</p>
          <h1 id="guide-title">
            {location
              ? "위치를 항상 허용해 주세요"
              : "배터리 제한을 해제해 주세요"}
          </h1>
          <p className="onboarding__description">
            {location
              ? "위치 권한을 ‘항상 허용’으로 선택하면 앱이 닫혀 있어도 도착을 감지할 수 있어요."
              : "배터리 최적화 예외를 허용하면 백그라운드 자동 전송이 안정적으로 동작해요."}
          </p>
        </header>
        <ol className="onboarding__list">
          <li>아래 버튼을 눌러 시스템 설정을 열어 주세요.</li>
          <li>
            {location
              ? "위치 권한에서 ‘항상 허용’을 선택해 주세요."
              : "ImHere의 배터리 사용 제한을 해제해 주세요."}
          </li>
          <li>앱으로 돌아오면 상태를 자동으로 다시 확인해요.</li>
        </ol>
        <Button onClick={() => void openSettings()}>설정 열기</Button>
        <Button variant="secondary" onClick={() => navigate(-1)}>
          돌아가기
        </Button>
      </section>
    </main>
  );
}
