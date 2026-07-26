import "./setting.css";
import "@/pages/feature-page.css";

import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useBridge } from "@/bridge/bridge-context";
import { useTheme } from "@/design-system";
import { loadTerms, type Term } from "@/pages/onboarding/terms-service";
import { formatActivityTime } from "@/pages/record/record-model";

import { settingService, SUPPORT_URL, type UserMe } from "./setting-service";

type AppInfo = BridgeMethodResult<"getAppInfo">;
type Readiness = BridgeMethodResult<"getAutoSendReadiness">;
type Record = BridgeMethodResult<"queryRecords">["items"][number];

export default function SettingPage() {
  const api = useApiClient();
  const bridge = useBridge();
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const [me, setMe] = useState<UserMe>();
  const [appInfo, setAppInfo] = useState<AppInfo>();
  const [readiness, setReadiness] = useState<Readiness>();
  const [lastRecord, setLastRecord] = useState<Record>();
  const [terms, setTerms] = useState<Term[]>([]);
  const [contactAccess, setContactAccess] = useState(false);
  const [status, setStatus] = useState("설정 정보를 불러오는 중입니다.");

  const refreshNative = async () => {
    const [infoResult, readinessResult, recordResult] =
      await Promise.allSettled([
        bridge.getAppInfo(),
        bridge.getAutoSendReadiness(),
        bridge.queryRecords({ limit: 1 }),
      ]);
    if (infoResult.status === "fulfilled") setAppInfo(infoResult.value);
    if (readinessResult.status === "fulfilled") {
      setReadiness(readinessResult.value);
    }
    if (recordResult.status === "fulfilled") {
      setLastRecord(recordResult.value.items[0]);
    }
  };

  useEffect(() => {
    void Promise.allSettled([
      settingService.me(api).then(setMe),
      loadTerms(api).then(setTerms),
      Promise.resolve().then(refreshNative),
    ]).then((results) => {
      setStatus(
        results.every((result) => result.status === "rejected")
          ? "설정 정보를 불러오지 못했습니다."
          : "",
      );
    });
    const unsubscribeResume = bridge.events.subscribe(
      "onAppResumed",
      () => void refreshNative(),
    );
    const unsubscribePermission = bridge.events.subscribe(
      "onPermissionChanged",
      () => void refreshNative(),
    );
    return () => {
      unsubscribeResume();
      unsubscribePermission();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api, bridge]);

  const editNickname = async () => {
    const nickname = window
      .prompt("새 닉네임을 입력하세요.", me?.nickname)
      ?.trim();
    if (!nickname || nickname.length > 30) return;
    try {
      setMe(await settingService.changeNickname(api, nickname));
      setStatus("닉네임을 변경했습니다.");
    } catch {
      setStatus("닉네임을 변경하지 못했습니다.");
    }
  };

  const openPermission = async (
    permission: "locationAlways" | "notification" | "batteryOptimization",
    granted: boolean,
  ) => {
    try {
      if (granted) await bridge.openAppSettings();
      else await bridge.requestPermission({ permission });
      await refreshNative();
    } catch {
      setStatus("권한 설정을 열지 못했습니다.");
    }
  };

  const signOut = async () => {
    if (!window.confirm("로그아웃할까요?")) return;
    await bridge.signOut();
    navigate("/auth", { replace: true });
  };

  const withdraw = async () => {
    if (
      !window.confirm(
        "회원 탈퇴 시 계정과 연결된 정보가 삭제되며 되돌릴 수 없습니다. 탈퇴할까요?",
      )
    ) {
      return;
    }
    try {
      await settingService.withdraw(api);
      await bridge.withdraw();
      navigate("/auth", { replace: true });
    } catch {
      setStatus("회원 탈퇴에 실패했습니다.");
    }
  };

  return (
    <main className="feature-page">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">내 앱 관리</span>
          <h1>설정</h1>
          <p>계정, 화면, 권한과 자동 전송 상태를 관리하세요.</p>
        </div>
      </header>
      {status && <p aria-live="polite">{status}</p>}

      <SettingSection title="계정">
        <li>
          <button
            className="setting-item"
            onClick={() => void editNickname()}
            type="button"
          >
            <span className="setting-profile">
              <strong>{me?.nickname ?? "내 정보"}</strong>
              <span>{me?.email ?? "계정 정보를 확인하는 중"}</span>
            </span>
            <span className="setting-item__detail">닉네임 수정</span>
          </button>
        </li>
      </SettingSection>

      <SettingSection title="디스플레이">
        <li>
          <button className="setting-item" onClick={toggleTheme} type="button">
            <span>화면 테마</span>
            <span className="setting-item__detail">
              {theme === "dark" ? "다크" : "라이트"}
            </span>
          </button>
        </li>
      </SettingSection>

      <SettingSection title="앱 사용 권한">
        <PermissionItem
          granted={readiness?.notification ?? false}
          label="앱 알림 권한"
          onClick={() =>
            void openPermission(
              "notification",
              readiness?.notification ?? false,
            )
          }
        />
        <PermissionItem
          granted={readiness?.locationAlways ?? false}
          label="항상 위치 권한"
          onClick={() =>
            void openPermission(
              "locationAlways",
              readiness?.locationAlways ?? false,
            )
          }
        />
        <PermissionItem
          granted={readiness?.batteryOptimization ?? false}
          label="배터리 최적화 제외"
          onClick={() =>
            void openPermission(
              "batteryOptimization",
              readiness?.batteryOptimization ?? false,
            )
          }
        />
        <PermissionItem
          granted={contactAccess}
          label="연락처 접근 권한"
          onClick={() =>
            void bridge
              .getDeviceContacts()
              .then(() => setContactAccess(true))
              .catch(() => setStatus("연락처 권한을 확인하지 못했습니다."))
          }
        />
      </SettingSection>

      <SettingSection title="전송 진단">
        <li>
          <Link className="setting-item" to="/record/send-history">
            <span>마지막 자동 전송</span>
            <span className="setting-item__detail">
              {lastRecord
                ? `${lastRecord.geofenceName} · ${formatActivityTime(lastRecord.occurredAt)}`
                : "아직 없음"}
            </span>
          </Link>
        </li>
        <li>
          <p className="setting-note">
            일부 기기의 제조사 절전 설정은 자동 전송을 막을 수 있습니다. 전송이
            누락되면 절전 설정에서 ImHere를 제외해 주세요.
          </p>
        </li>
      </SettingSection>

      <SettingSection title="서비스 약관">
        {terms.length === 0 ? (
          <li>
            <span className="setting-item">표시할 약관이 없습니다.</span>
          </li>
        ) : (
          terms.map((term) => (
            <li key={term.id}>
              <Link className="setting-item" to={`/terms-detail/${term.id}`}>
                <span>{term.title}</span>
                <span className="setting-item__detail">보기</span>
              </Link>
            </li>
          ))
        )}
      </SettingSection>

      <SettingSection title="고객 지원">
        <li>
          <button
            className="setting-item"
            onClick={() =>
              void bridge
                .openExternalUrl({ url: SUPPORT_URL })
                .catch(() => setStatus("문의하기 페이지를 열지 못했습니다."))
            }
            type="button"
          >
            <span>문의하기</span>
            <span className="setting-item__detail">Notion</span>
          </button>
        </li>
      </SettingSection>

      <SettingSection title="앱 정보">
        <li>
          <span className="setting-item">
            <span>버전 정보</span>
            <span className="setting-item__detail">
              {appInfo
                ? `${appInfo.appVersion} (${appInfo.buildNumber})`
                : "정보 없음"}
            </span>
          </span>
        </li>
      </SettingSection>

      <footer className="setting-footer">
        <p>ImHere · 소중한 사람과 위치의 순간을 나눠요.</p>
        <button
          className="ds-button ds-button--secondary"
          onClick={() => void signOut()}
          type="button"
        >
          로그아웃
        </button>
        <button
          className="ds-button ds-button--danger"
          onClick={() => void withdraw()}
          type="button"
        >
          회원 탈퇴
        </button>
      </footer>
    </main>
  );
}

function SettingSection({
  title,
  children,
}: {
  children: React.ReactNode;
  title: string;
}) {
  return (
    <section className="setting-section">
      <h2>{title}</h2>
      <ul className="setting-list">{children}</ul>
    </section>
  );
}

function PermissionItem({
  label,
  granted,
  onClick,
}: {
  granted: boolean;
  label: string;
  onClick: () => void;
}) {
  return (
    <li>
      <button className="setting-item" onClick={onClick} type="button">
        <span>{label}</span>
        <span className="setting-item__detail">
          {granted ? "허용됨" : "설정 필요"}
        </span>
      </button>
    </li>
  );
}
