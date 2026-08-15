import { type PropsWithChildren, useCallback, useId, useState } from "react";

import {
  BottomSheet,
  Button,
  ChoiceRow,
  FlatListRow,
  MoreButton,
  SettingsGroup,
  SettingsRow,
  ToggleSwitch,
  useTheme,
} from "@/design-system";
import "./catalog.css";

type PreviewKey =
  "geofence-list" | "geofence-form" | "friend" | "record" | "setting";

type SheetState =
  | { kind: "place"; name: string }
  | { kind: "friend"; name: string }
  | { kind: "example" }
  | null;

const previewOptions: Array<{ key: PreviewKey; label: string }> = [
  { key: "geofence-list", label: "장소" },
  { key: "geofence-form", label: "장소 등록" },
  { key: "friend", label: "친구" },
  { key: "record", label: "기록" },
  { key: "setting", label: "설정" },
];

const places = [
  {
    name: "우리 집",
    address: "서울 성동구 왕십리로 83",
    condition: "500m 내 진입 시",
    schedule: "매일",
  },
  {
    name: "강남 파이낸스센터",
    address: "서울 강남구 테헤란로 152",
    condition: "250m 밖으로 나갈 시",
    schedule: "평일",
  },
  {
    name: "부모님 댁",
    address: "경기 수원시 팔달구 효원로 1",
    condition: "1km 내 진입 시",
    schedule: "한 번",
  },
] as const;

const friends = [
  { name: "김아름", detail: "내 도착 알림을 받아요" },
  { name: "박하늘", detail: "도착 소식을 함께 나눠요" },
  { name: "이준호", detail: "ImHere 친구" },
] as const;

function CatalogSection({
  children,
  id,
  title,
}: PropsWithChildren<{ id?: string; title: string }>) {
  const titleId = useId();

  return (
    <section id={id} className="catalog-section" aria-labelledby={titleId}>
      <h2 id={titleId}>{title}</h2>
      {children}
    </section>
  );
}

function PatternLibrary({ onOpenSheet }: { onOpenSheet: () => void }) {
  return (
    <div className="catalog-patterns">
      <div className="catalog-pattern" aria-label="텍스트">
        <strong>중요한 정보</strong>
        <span>필요한 설명은 짧고 분명하게 표시합니다.</span>
        <small>오후 7:42 · 전송 완료</small>
      </div>

      <div className="catalog-pattern" aria-label="버튼">
        <div className="catalog-button-row">
          <Button>저장하기</Button>
          <Button variant="secondary">취소</Button>
          <Button variant="danger">삭제</Button>
        </div>
      </div>

      <div className="catalog-pattern" aria-label="입력">
        <label className="catalog-field">
          <span>장소 이름</span>
          <input defaultValue="우리 집" />
          <small>알아보기 쉬운 이름을 입력하세요.</small>
        </label>
        <label className="catalog-field">
          <span>연락처</span>
          <input defaultValue="010-1234" aria-invalid="true" />
          <small className="catalog-field__error">
            전화번호를 끝까지 입력해 주세요.
          </small>
        </label>
      </div>

      <div className="catalog-pattern" aria-label="상태와 메뉴">
        <div className="catalog-flat-row">
          <div>
            <strong>우리 집</strong>
            <span>서울 성동구 왕십리로 83</span>
          </div>
          <MoreButton label="예시 항목 더보기" onClick={onOpenSheet} />
        </div>
        <div className="catalog-inline-feedback" role="status">
          <span aria-hidden="true">✓</span>
          장소가 저장되었습니다.
        </div>
        <div
          className="catalog-skeleton"
          role="status"
          aria-label="목록을 불러오는 중"
        >
          <span />
          <span />
          <span />
        </div>
        <div className="catalog-empty">
          <strong>등록된 장소가 없어요</strong>
          <span>첫 장소를 등록해 주세요.</span>
        </div>
      </div>
    </div>
  );
}

function GeofenceListPreview({
  onOpenSheet,
}: {
  onOpenSheet: (name: string) => void;
}) {
  const [active, setActive] = useState<Record<string, boolean>>({
    "우리 집": true,
    "강남 파이낸스센터": true,
    "부모님 댁": false,
  });

  return (
    <div className="catalog-preview-screen">
      <h3 className="visually-hidden">장소 목록 미리보기</h3>
      <div className="catalog-status-line" role="status">
        <span aria-hidden="true" />
        자동 전송 준비 완료
      </div>
      <div className="catalog-list">
        {places.map((place) => (
          <FlatListRow
            key={place.name}
            title={place.name}
            description={place.address}
            detail={place.condition}
            meta={place.schedule}
            onClick={() => undefined}
            actions={
              <>
                <MoreButton
                  label={`${place.name} 더보기`}
                  onClick={() => onOpenSheet(place.name)}
                />
                <ToggleSwitch
                  checked={active[place.name] ?? false}
                  label={`${place.name} 활성화`}
                  onChange={(checked) =>
                    setActive((current) => ({
                      ...current,
                      [place.name]: checked,
                    }))
                  }
                />
              </>
            }
          />
        ))}
      </div>
      <p className="catalog-note">
        반복하지 않는 알림은 첫 전송 후 자동으로 꺼집니다.
      </p>
    </div>
  );
}

function GeofenceFormPreview() {
  const [name, setName] = useState("우리 집");
  const [radius, setRadius] = useState("500m");
  const [saved, setSaved] = useState(false);
  const showError = name.trim().length === 0;

  return (
    <form
      className="catalog-preview-screen catalog-form-preview"
      onSubmit={(event) => {
        event.preventDefault();
        setSaved(!showError);
      }}
    >
      <h3 className="visually-hidden">장소 등록 미리보기</h3>
      <fieldset className="catalog-form-section">
        <legend>위치</legend>
        <label className="catalog-search">
          <span className="visually-hidden">주소 검색</span>
          <span aria-hidden="true">⌕</span>
          <input placeholder="주소 또는 장소 이름" />
        </label>
        <div className="catalog-map-placeholder">
          <span aria-hidden="true">⌖</span>
          <strong>서울 성동구 왕십리로 83</strong>
          <small>지도를 눌러 위치를 조정할 수 있어요.</small>
        </div>
        <ChoiceRow
          label="알림 반경"
          value={radius}
          onChange={setRadius}
          options={["250m", "500m", "1km"].map((option) => ({
            label: option,
            value: option,
          }))}
        />
      </fieldset>

      <fieldset className="catalog-form-section">
        <legend>알림 내용</legend>
        <label className="catalog-field">
          <span>장소 이름</span>
          <input
            value={name}
            aria-invalid={showError || undefined}
            onChange={(event) => {
              setName(event.target.value);
              setSaved(false);
            }}
          />
          {showError ? (
            <small className="catalog-field__error" role="alert">
              장소 이름을 입력해 주세요.
            </small>
          ) : null}
        </label>
        <label className="catalog-field">
          <span>보낼 메시지</span>
          <textarea defaultValue="집에 도착했어요." />
        </label>
      </fieldset>

      <fieldset className="catalog-form-section">
        <legend>받는 사람</legend>
        {friends.slice(0, 2).map((friend, index) => (
          <label className="catalog-check-row" key={friend.name}>
            <span>
              <strong>{friend.name}</strong>
              <small>{friend.detail}</small>
            </span>
            <input type="checkbox" defaultChecked={index === 0} />
          </label>
        ))}
      </fieldset>

      {saved ? (
        <p className="catalog-inline-feedback" role="status">
          <span aria-hidden="true">✓</span>
          저장할 준비가 되었어요.
        </p>
      ) : null}

      <div className="catalog-sticky-action">
        <button type="submit" aria-label="장소 저장하기">
          저장하기
        </button>
      </div>
    </form>
  );
}

function FriendPreview({
  onOpenSheet,
}: {
  onOpenSheet: (name: string) => void;
}) {
  return (
    <div className="catalog-preview-screen">
      <h3 className="visually-hidden">친구 목록 미리보기</h3>
      <nav className="catalog-utility-list" aria-label="친구 관리">
        <button type="button">
          <span>
            <strong>새로운 친구 찾기</strong>
            <small>이름이나 아이디로 검색</small>
          </span>
          <span aria-hidden="true">›</span>
        </button>
        <button type="button">
          <span>
            <strong>받은 친구 요청</strong>
            <small>새 요청 1건</small>
          </span>
          <span className="catalog-count">1</span>
        </button>
      </nav>
      <div className="catalog-subsection-label">친구 3명</div>
      <div className="catalog-list">
        {friends.map((friend) => (
          <FlatListRow
            key={friend.name}
            title={friend.name}
            description={friend.detail}
            onClick={() => undefined}
            actions={
              <MoreButton
                label={`${friend.name} 더보기`}
                onClick={() => onOpenSheet(friend.name)}
              />
            }
          />
        ))}
      </div>
    </div>
  );
}

function RecordPreview() {
  const [filter, setFilter] = useState("전체");
  const records = [
    {
      day: "오늘",
      kind: "도착",
      time: "오후 7:42",
      title: "우리 집에 도착했어요",
      detail: "김아름 외 1명에게 전송",
    },
    {
      day: "오늘",
      kind: "출발",
      time: "오후 6:18",
      title: "회사에서 출발했어요",
      detail: "박하늘에게 전송",
    },
    {
      day: "어제",
      kind: "도착",
      time: "오후 2:05",
      title: "부모님 댁에 도착했어요",
      detail: "김아름에게 전송",
    },
  ];
  const visible = records.filter(
    (record) => filter === "전체" || record.kind === filter,
  );

  return (
    <div className="catalog-preview-screen">
      <h3 className="visually-hidden">기록 미리보기</h3>
      <ChoiceRow
        compact
        label="기록 필터"
        value={filter}
        onChange={setFilter}
        options={["전체", "도착", "출발"].map((option) => ({
          label: option,
          value: option,
        }))}
      />
      {["오늘", "어제"].map((day) => {
        const items = visible.filter((record) => record.day === day);
        if (items.length === 0) return null;
        return (
          <section className="catalog-timeline" key={day}>
            <h4>{day}</h4>
            {items.map((record) => (
              <article key={`${record.time}-${record.title}`}>
                <time>{record.time}</time>
                <span aria-hidden="true" />
                <div>
                  <strong>{record.title}</strong>
                  <small>{record.detail}</small>
                </div>
              </article>
            ))}
          </section>
        );
      })}
    </div>
  );
}

function SettingPreview({
  onOpenAccount,
  theme,
  toggleTheme,
}: {
  onOpenAccount: () => void;
  theme: "light" | "dark";
  toggleTheme: () => void;
}) {
  const groups: Array<{
    label: string;
    rows: Array<{
      label: string;
      detail: string;
      action?: () => void;
    }>;
  }> = [
    {
      label: "계정",
      rows: [
        {
          label: "김아름",
          detail: "계정 관리",
          action: onOpenAccount,
        },
      ],
    },
    {
      label: "앱 설정",
      rows: [
        {
          label: "화면 테마",
          detail: theme === "dark" ? "다크" : "라이트",
          action: toggleTheme,
        },
        { label: "알림 권한", detail: "허용됨" },
        { label: "항상 위치 권한", detail: "확인 필요" },
      ],
    },
    {
      label: "서비스",
      rows: [
        { label: "약관 및 개인정보", detail: "보기" },
        { label: "버전", detail: "1.0.0" },
      ],
    },
  ];

  return (
    <div className="catalog-preview-screen">
      <h3 className="visually-hidden">설정 미리보기</h3>
      {groups.map((group) => (
        <SettingsGroup key={group.label} title={group.label}>
          {group.rows.map((row) => (
            <SettingsRow
              key={row.label}
              label={row.label}
              detail={row.detail}
              onClick={row.action}
            />
          ))}
        </SettingsGroup>
      ))}
    </div>
  );
}

function PreviewContent({
  onOpenFriend,
  onOpenPlace,
  preview,
  theme,
  toggleTheme,
}: {
  onOpenFriend: (name: string) => void;
  onOpenPlace: (name: string) => void;
  preview: PreviewKey;
  theme: "light" | "dark";
  toggleTheme: () => void;
}) {
  if (preview === "geofence-form") return <GeofenceFormPreview />;
  if (preview === "friend") {
    return <FriendPreview onOpenSheet={onOpenFriend} />;
  }
  if (preview === "record") return <RecordPreview />;
  if (preview === "setting") {
    return (
      <SettingPreview
        theme={theme}
        toggleTheme={toggleTheme}
        onOpenAccount={() => onOpenFriend("김아름")}
      />
    );
  }
  return <GeofenceListPreview onOpenSheet={onOpenPlace} />;
}

function SheetActions({
  sheet,
  onClose,
}: {
  sheet: SheetState;
  onClose: () => void;
}) {
  if (sheet?.kind === "place") {
    return (
      <>
        <Button variant="secondary" onClick={onClose}>
          수정
        </Button>
        <Button variant="danger" onClick={onClose}>
          삭제
        </Button>
      </>
    );
  }
  if (sheet?.kind === "friend") {
    return (
      <>
        <label className="catalog-field">
          <span>별명</span>
          <input defaultValue={sheet.name} />
        </label>
        <Button onClick={onClose}>별명 저장</Button>
        <Button variant="text" onClick={onClose}>
          친구 삭제
        </Button>
        <Button variant="danger" onClick={onClose}>
          차단
        </Button>
      </>
    );
  }
  return (
    <>
      <Button onClick={onClose}>확인</Button>
      <Button variant="secondary" onClick={onClose}>
        취소
      </Button>
    </>
  );
}

function sheetTitle(sheet: SheetState) {
  if (sheet?.kind === "place") return `${sheet.name} 관리`;
  if (sheet?.kind === "friend") return `${sheet.name} 관리`;
  return "작업 선택";
}

export default function ComponentCatalogPage() {
  const { setTheme, theme, toggleTheme } = useTheme();
  const [preview, setPreview] = useState<PreviewKey>("geofence-list");
  const [sheet, setSheet] = useState<SheetState>(null);
  const closeSheet = useCallback(() => setSheet(null), []);

  return (
    <main className="catalog-page">
      <header className="catalog-toolbar">
        <div>
          <strong>ImHere</strong>
          <span>UI Preview</span>
          <h1 className="visually-hidden">ImHere 미니멀 UI 미리보기</h1>
        </div>
        <fieldset className="catalog-theme-picker">
          <legend className="visually-hidden">화면 테마</legend>
          <button
            type="button"
            aria-pressed={theme === "light"}
            onClick={() => setTheme("light")}
          >
            라이트
          </button>
          <button
            type="button"
            aria-pressed={theme === "dark"}
            onClick={() => setTheme("dark")}
          >
            다크
          </button>
        </fieldset>
      </header>

      <CatalogSection title="기본 요소">
        <PatternLibrary onOpenSheet={() => setSheet({ kind: "example" })} />
      </CatalogSection>

      <CatalogSection id="catalog-preview" title="화면 미리보기">
        <div className="catalog-preview-tabs" aria-label="미리보기 화면">
          {previewOptions.map((option) => (
            <button
              key={option.key}
              type="button"
              aria-pressed={preview === option.key}
              onClick={() => setPreview(option.key)}
            >
              {option.label}
            </button>
          ))}
        </div>
        <div className="catalog-preview-stage">
          <PreviewContent
            preview={preview}
            theme={theme}
            toggleTheme={toggleTheme}
            onOpenPlace={(name) => setSheet({ kind: "place", name })}
            onOpenFriend={(name) => setSheet({ kind: "friend", name })}
          />
        </div>
      </CatalogSection>

      <BottomSheet
        closeLabel="닫기"
        open={sheet !== null}
        title={sheetTitle(sheet)}
        onClose={closeSheet}
      >
        <SheetActions sheet={sheet} onClose={closeSheet} />
      </BottomSheet>
    </main>
  );
}
