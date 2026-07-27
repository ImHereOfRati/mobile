import { useState } from "react";

import {
  BottomSheet,
  Button,
  Card,
  EmptyState,
  ListItem,
  LoadingState,
  TextField,
  Toast,
  useTheme,
} from "@/design-system";
import "./catalog.css";

function CatalogSection({
  children,
  description,
  title,
}: {
  children: React.ReactNode;
  description: string;
  title: string;
}) {
  return (
    <section className="catalog-section">
      <header>
        <p className="catalog-section__eyebrow">FOUNDATION</p>
        <h2 className="type-headline-medium">{title}</h2>
        <p className="type-body-medium">{description}</p>
      </header>
      <div className="catalog-section__demo">{children}</div>
    </section>
  );
}

export default function ComponentCatalogPage() {
  const { setTheme, theme } = useTheme();
  const [sheetOpen, setSheetOpen] = useState(false);

  return (
    <main className="catalog-page">
      <header className="catalog-hero">
        <div className="catalog-hero__brand" aria-label="ImHere">
          <span aria-hidden="true">I⌖</span>
          <strong>ImHere</strong>
        </div>
        <div>
          <p className="catalog-hero__eyebrow">DESIGN SYSTEM 1.0</p>
          <h1 className="type-headline-large">
            일관되고 따뜻한
            <br />
            안심 경험의 시작
          </h1>
          <p className="type-body-large">
            기존 ImHere의 파랑을 지키면서, 모든 화면이 같은 언어로 이야기하도록
            만든 공용 컴포넌트입니다.
          </p>
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

      <CatalogSection
        title="타이포그래피"
        description="Web 화면 전반에 사용하는 제목·본문 스케일입니다."
      >
        <div className="catalog-type-ramp">
          <p className="type-display-medium">도착을 알려드릴게요</p>
          <p className="type-headline-medium">장소를 등록하세요</p>
          <p className="type-headline-small">가족에게 자동으로 알려요</p>
          <p className="type-body-large">
            장소에 도착하거나 떠날 때 선택한 사람에게 알림을 보냅니다.
          </p>
          <p className="type-body-medium">
            제목은 Gmarket Sans, 본문은 Pretendard를 사용합니다.
          </p>
        </div>
      </CatalogSection>

      <CatalogSection
        title="버튼"
        description="모든 버튼은 최소 44px 터치 영역과 명확한 포커스를 갖습니다."
      >
        <div className="catalog-row">
          <Button>계속하기</Button>
          <Button variant="secondary">나중에</Button>
          <Button variant="ghost">자세히 보기</Button>
          <Button variant="danger">삭제하기</Button>
          <Button loading>저장하기</Button>
        </div>
      </CatalogSection>

      <CatalogSection
        title="입력과 카드"
        description="레이블·도움말·오류를 입력창과 구조적으로 연결합니다."
      >
        <div className="catalog-grid">
          <TextField
            label="장소 이름"
            placeholder="예: 우리 집"
            helperText="알아보기 쉬운 이름을 입력하세요."
          />
          <TextField
            label="연락처"
            defaultValue="010-1234"
            error="전화번호를 끝까지 입력해 주세요."
          />
          <Card
            title="우리 집"
            description="서울특별시 중구 세종대로 110 · 반경 500m"
          >
            <div className="catalog-card-meta">
              <span>도착 시 알림</span>
              <strong>활성</strong>
            </div>
          </Card>
        </div>
      </CatalogSection>

      <CatalogSection
        title="리스트와 피드백"
        description="정보 구조를 유지하면서 상태와 다음 행동을 분명히 보여줍니다."
      >
        <Card>
          <ListItem
            leading="⌖"
            title="회사"
            description="평일 오전 9시 · 도착 알림"
            trailing="500m"
            onClick={() => undefined}
          />
          <ListItem
            leading="→"
            title="가족에게 보내기"
            description="김아름 외 2명"
            trailing="변경"
            onClick={() => undefined}
          />
        </Card>
        <div className="catalog-feedback">
          <Toast message="장소가 저장되었습니다." tone="success" />
          <Toast
            message="네트워크 연결을 확인해 주세요."
            tone="error"
            actionLabel="재시도"
          />
        </div>
      </CatalogSection>

      <CatalogSection
        title="빈 상태와 로딩"
        description="기다림과 비어 있음을 실패처럼 느끼지 않도록 안내합니다."
      >
        <div className="catalog-grid">
          <Card>
            <EmptyState
              title="등록된 장소가 없어요"
              description="첫 장소를 등록하고 자동 알림을 시작해 보세요."
              actionLabel="장소 등록하기"
            />
          </Card>
          <Card title="목록을 불러오고 있어요">
            <LoadingState rows={3} />
          </Card>
        </div>
      </CatalogSection>

      <CatalogSection
        title="바텀시트"
        description="모바일 문맥을 벗어나지 않고 짧은 선택을 완료합니다."
      >
        <Button onClick={() => setSheetOpen(true)}>반경 선택 열기</Button>
        <BottomSheet
          open={sheetOpen}
          title="알림 반경을 선택하세요"
          onClose={() => setSheetOpen(false)}
        >
          <div className="catalog-sheet-options">
            <Button variant="secondary">250m</Button>
            <Button>500m</Button>
            <Button variant="secondary">1km</Button>
          </div>
        </BottomSheet>
      </CatalogSection>
    </main>
  );
}
