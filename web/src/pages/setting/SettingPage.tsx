import "./setting.css";
import "@/pages/feature-page.css";

import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";
import {
  BottomSheet,
  Button,
  SettingsGroup,
  SettingsRow,
  TextField,
  useTheme,
} from "@/design-system";
import { loadTerms, type Term } from "./terms-service";
import { formatActivityTime } from "@/pages/record/record-model";

import { settingService, SUPPORT_URL, type UserMe } from "./setting-service";
import { BackgroundLocationDisclosure } from "./BackgroundLocationDisclosure";

type AppInfo = BridgeMethodResult<"getAppInfo">;
type Readiness = BridgeMethodResult<"getAutoSendReadiness">;
type Record = BridgeMethodResult<"queryRecords">["items"][number];

export default function SettingPage() {
  const api = useApiClient();
  const bridge = useBridge();
  const analytics = useAnalytics();
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const [me, setMe] = useState<UserMe>();
  const [appInfo, setAppInfo] = useState<AppInfo>();
  const [readiness, setReadiness] = useState<Readiness>();
  const [lastRecord, setLastRecord] = useState<Record>();
  const [terms, setTerms] = useState<Term[]>([]);
  const [contactAccess, setContactAccess] = useState(false);
  const [status, setStatus] = useState("설정 정보를 불러오는 중입니다.");
  const [confirmation, setConfirmation] = useState<
    "signOut" | "withdraw" | null
  >(null);
  const [nicknameSheetOpen, setNicknameSheetOpen] = useState(false);
  const [nicknameDraft, setNicknameDraft] = useState("");
  const [nicknameSaving, setNicknameSaving] = useState(false);
  const [locationDisclosureOpen, setLocationDisclosureOpen] = useState(false);

  const refreshNative = async () => {
    const [infoResult, readinessResult, recordResult, contactsResult] =
      await Promise.allSettled([
        bridge.getAppInfo(),
        bridge.getAutoSendReadiness(),
        bridge.queryRecords({ limit: 1 }),
        bridge.getPermissionStatus({ permission: "contacts" }),
      ]);
    if (infoResult.status === "fulfilled") setAppInfo(infoResult.value);
    if (readinessResult.status === "fulfilled") {
      setReadiness(readinessResult.value);
    }
    if (recordResult.status === "fulfilled") {
      setLastRecord(recordResult.value.items[0]);
    }
    if (contactsResult?.status === "fulfilled") {
      setContactAccess(contactsResult.value.status === "granted");
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

  const openNicknameEditor = () => {
    setNicknameDraft(me?.nickname ?? "");
    setNicknameSheetOpen(true);
  };

  const editNickname = async () => {
    const nickname = nicknameDraft.trim();
    if (!nickname || nickname.length > 30) {
      setStatus("닉네임은 1~30자로 입력해 주세요.");
      return;
    }
    setNicknameSaving(true);
    try {
      setMe(await settingService.changeNickname(api, nickname));
      setStatus("닉네임을 변경했습니다.");
      setNicknameSheetOpen(false);
    } catch {
      setStatus("닉네임을 변경하지 못했습니다.");
    } finally {
      setNicknameSaving(false);
    }
  };

  const openPermission = async (
    permission:
      "locationAlways" | "notification" | "batteryOptimization" | "contacts",
    granted: boolean,
  ) => {
    try {
      if (permission === "locationAlways" || granted) {
        setLocationDisclosureOpen(true);
      } else await bridge.requestPermission({ permission });
      await refreshNative();
    } catch {
      setStatus("권한 설정을 열지 못했습니다.");
    }
  };

  const signOut = async () => {
    await bridge.signOut();
    await analytics.setConsent(false);
    navigate("/auth", { replace: true });
  };

  const withdraw = async () => {
    try {
      await settingService.withdraw(api);
    } catch {
      setStatus("회원 탈퇴에 실패했습니다.");
      return;
    }
    // 계정은 이미 지워졌다. 남은 정리가 실패해도 로그인 화면으로 돌려보내는
    // 편이 맞다 — 지워진 계정의 토큰을 들고 앱에 남아 있을 이유가 없다.
    await Promise.allSettled([bridge.signOut(), analytics.setConsent(false)]);
    navigate("/auth", { replace: true });
  };

  return (
    <main className="feature-page" data-clarity-mask="true">
      <h1 className="visually-hidden">설정</h1>
      {status && <p aria-live="polite">{status}</p>}

      <SettingsGroup title="계정">
        <SettingsRow
          label={
            <span className="setting-profile">
              <strong>{me?.nickname ?? "내 정보"}</strong>
              <span>{me?.email ?? "계정 정보를 확인하는 중"}</span>
            </span>
          }
          detail="닉네임 수정"
          onClick={openNicknameEditor}
        />
      </SettingsGroup>

      <SettingsGroup title="디스플레이">
        <SettingsRow
          label="화면 테마"
          detail={theme === "dark" ? "다크" : "라이트"}
          role="switch"
          aria-checked={theme === "dark"}
          onClick={toggleTheme}
        />
      </SettingsGroup>

      <SettingsGroup title="앱 사용 권한">
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
          label="위치 권한 (항상 허용)"
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
          onClick={() => void openPermission("contacts", contactAccess)}
        />
      </SettingsGroup>

      <SettingsGroup title="전송 진단">
        <SettingsRow
          label="마지막 자동 전송"
          detail={
            lastRecord
              ? `${lastRecord.geofenceName} · ${formatActivityTime(lastRecord.occurredAt)}`
              : "아직 없음"
          }
          onClick={() => navigate("/record/send-history")}
        />
        <p className="setting-note">
          일부 기기의 제조사 절전 설정은 자동 전송을 막을 수 있습니다. 전송이
          누락되면 절전 설정에서 ImHere를 제외해 주세요.
        </p>
      </SettingsGroup>

      <SettingsGroup title="서비스 약관">
        <SettingsRow
          label="약관 동의 관리"
          detail="동의 내역 보기"
          onClick={() => navigate("/setting/agreements")}
        />
        {terms.length === 0 ? (
          <SettingsRow label="표시할 약관이 없습니다." />
        ) : (
          terms.map((term) => (
            <SettingsRow
              key={term.id}
              label={term.title}
              detail="보기"
              onClick={() => navigate(`/terms-detail/${term.id}`)}
            />
          ))
        )}
      </SettingsGroup>

      <SettingsGroup title="고객 지원">
        <SettingsRow
          label="문의하기"
          detail="Notion"
          onClick={() =>
            void bridge
              .openExternalUrl({ url: SUPPORT_URL })
              .catch(() => setStatus("문의하기 페이지를 열지 못했습니다."))
          }
        />
      </SettingsGroup>

      <SettingsGroup title="앱 정보">
        <SettingsRow
          label="버전 정보"
          detail={
            appInfo
              ? `${appInfo.appVersion} (${appInfo.buildNumber})`
              : "정보 없음"
          }
        />
      </SettingsGroup>

      <footer className="setting-footer">
        <p>ImHere · 소중한 사람과 위치의 순간을 나눠요.</p>
        <Button variant="secondary" onClick={() => setConfirmation("signOut")}>
          로그아웃
        </Button>
        <Button variant="danger" onClick={() => setConfirmation("withdraw")}>
          회원 탈퇴
        </Button>
      </footer>

      <BottomSheet
        open={nicknameSheetOpen}
        title="닉네임 수정"
        onClose={() => setNicknameSheetOpen(false)}
      >
        <form
          className="feature-page__sheet-actions"
          onSubmit={(event) => {
            event.preventDefault();
            void editNickname();
          }}
        >
          <TextField
            autoFocus
            label="닉네임"
            maxLength={30}
            value={nicknameDraft}
            onChange={(event) => setNicknameDraft(event.target.value)}
          />
          <Button loading={nicknameSaving} type="submit">
            저장
          </Button>
        </form>
      </BottomSheet>

      <BackgroundLocationDisclosure
        open={locationDisclosureOpen}
        onClose={() => setLocationDisclosureOpen(false)}
        onConfirm={() => {
          setLocationDisclosureOpen(false);
          void bridge
            .openAppSettings()
            .catch(() => setStatus("권한 설정을 열지 못했습니다."));
        }}
      />

      <BottomSheet
        open={confirmation !== null}
        title={confirmation === "withdraw" ? "회원 탈퇴" : "로그아웃"}
        onClose={() => setConfirmation(null)}
      >
        <div className="feature-page__sheet-actions">
          <p className="setting-note">
            {confirmation === "withdraw"
              ? "회원 탈퇴 시 계정과 연결된 정보가 삭제되며 되돌릴 수 없습니다. 탈퇴할까요?"
              : "로그아웃할까요?"}
          </p>
          <Button
            variant={confirmation === "withdraw" ? "danger" : "primary"}
            onClick={() => {
              const action = confirmation;
              setConfirmation(null);
              if (action === "signOut") void signOut();
              if (action === "withdraw") void withdraw();
            }}
          >
            {confirmation === "withdraw" ? "회원 탈퇴" : "로그아웃"}
          </Button>
          <Button variant="secondary" onClick={() => setConfirmation(null)}>
            취소
          </Button>
        </div>
      </BottomSheet>
    </main>
  );
}

function PermissionItem({
  detail,
  label,
  granted,
  onClick,
}: {
  granted: boolean;
  detail?: string;
  label: string;
  onClick: () => void;
}) {
  return (
    <SettingsRow
      className={granted ? "" : "permission-item--needs-action"}
      label={label}
      detail={detail ?? (granted ? "허용됨" : "허용 안 됨")}
      onClick={onClick}
    />
  );
}
