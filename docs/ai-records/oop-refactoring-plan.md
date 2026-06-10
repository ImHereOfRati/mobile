# 2차 마일스톤 이후 OOP 리팩터링 계획

이 문서는 `ui-transition-plan.md`에 명시된 2차 마일스톤 이후의 OOP 점검 기준(파일당 1 클래스, 100줄 이하, private 메서드 3개 이하)에 따라 현재 코드베이스의 위반 사항을 진단하고, 이를 해결하기 위한 리팩터링 계획을 수립합니다.

## 1. 점검 기준
* **화면별 책임 분리**: UI 로직과 상태/권한 판단 로직의 혼재 여부
* **클래스 개수**: 1 파일 = 1 클래스 (Flutter 내부 제약, `.g.dart` 등 자동 생성 파일 제외)
* **파일 길이**: 100줄 이하
* **Private 메서드**: 3개 이하 (과도한 책임 의심)

## 2. 주요 위반 사항 및 리팩터링 대상

### 🚨 1순위: 초대형 파일 (500줄 이상) 및 과도한 Private 메서드
이 파일들은 UI 구성, 상태 관리, 이벤트 처리 등 여러 책임이 강하게 결합되어 있어 즉각적인 분리가 필요합니다.

* **`lib/feature/friend/view/contact_view.dart` (657줄, 16개 PM)**
  * **문제**: 주소록 연동, 검색, 리스트 렌더링, 권한 요청 로직이 모두 혼재됨.
  * **계획**:
    1. 검색 바, 연락처 리스트 아이템, 권한 안내 배너를 개별 컴포넌트(`contact_search_bar.dart`, `contact_list_item.dart` 등)로 분리.
    2. 주소록 권한/연동 로직을 ViewModel 또는 분리된 정책 객체로 이동.
* **`lib/feature/friend/view/add_friend_view.dart` (578줄, 14개 PM)**
  * **문제**: 친구 추가 폼, 상태 표시, 네트워크 결과 처리(PM 다수) 혼재.
  * **계획**: 입력 폼 요소(`add_friend_form.dart`)와 결과 피드백 UI(`add_friend_result.dart`)를 개별 파일로 분리.

### 🚨 2순위: 권한/가이드 뷰 (400줄 이상)
* **`lib/feature/user_permission/view/location_permission_guide_view.dart` (411줄, 3 클래스, 10개 PM)**
* **`lib/feature/user_permission/view/battery_optimization_guide_view.dart` (402줄, 3 클래스, 10개 PM)**
  * **문제**: 안내 UI 컴포넌트, 애니메이션 제어, OS 분기별 권한 요청 로직이 섞여 있음. 또한 한 파일에 여러 클래스가 존재함.
  * **계획**:
    1. 내부의 다중 클래스(예: 스텝 카드 UI 등)를 `component/` 디렉토리 아래의 개별 파일로 분리.
    2. 권한 확인 및 요청 책임을 담당하는 로직(PM들)을 상태 관리자(ViewModel/Service)로 위임.
    3. UI는 순수하게 가이드라인 텍스트 및 이미지 렌더링만 담당하도록 100줄 내외로 축소.

### ⚠️ 3순위: 복수 클래스 포함 및 150~350줄 규모 파일
* **`lib/feature/terms/view/terms_list_view.dart` (346줄, 7개 PM)**
  * **계획**: 약관 아이템 타일(`terms_list_tile.dart`) 및 전체 동의 헤더(`terms_all_agree_header.dart`) 컴포넌트 분리.
* **`lib/feature\record\view\component\record_overview_items.dart` (219줄, 5 클래스)**
* **`lib/feature\record\view\component\record_overview_sections.dart` (153줄, 4 클래스)**
  * **문제**: 컴포넌트 모음집 형태의 파일 구성으로 1 파일 1 클래스 원칙 위반.
  * **계획**: 각각의 Item과 Section 클래스를 단일 파일로 쪼개어 `record/view/component/` 하위에 배치.
* **`lib/feature/geofence/view/map_select/component/map_select_widgets.dart` (159줄, 4 클래스)**
  * **계획**: 지도 핀, 오버레이, 하단 패널 등 개별 위젯을 독립된 파일로 분리.

### 🟡 4순위: 비즈니스/서비스 로직 책임 비대화
* **`lib/feature/auth/service/auth_service.dart` (93줄, 5개 PM)**
* **`lib/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart` (144줄)**
* **`lib/feature/geofence/service/sms_service.dart` (157줄, 6개 PM)**
  * **문제**: 파일 라인 수는 상대적으로 적으나, private 메서드가 많아 책임이 집중된 것으로 보임.
  * **계획**:
    1. `sms_service.dart` 내의 템플릿 생성 및 권한 검사 등의 역할을 별도 객체(예: `SmsTemplateGenerator`)로 분리 검토.
    2. `geofence_enroll_view_model.dart`에서 반복/메시지/위치 검증 로직을 `Validator` 또는 모델 내 도메인 로직으로 추출.

## 3. 실행 전략

1. **Phase 1: 다중 클래스 파일 분리**
   * `record_overview_items.dart`, `map_select_widgets.dart`, 권한 가이드 파일들에 존재하는 다중 클래스를 각각 하나의 파일로 쪼갭니다.
2. **Phase 2: 초대형 View 컴포넌트 분리**
   * `contact_view.dart`, `add_friend_view.dart`의 `build` 메서드 내 위젯 트리를 잘라내어 Stateless Widget으로 분리합니다.
3. **Phase 3: 로직(Private 메서드) 추출**
   * View나 Service에 존재하는 3개 이상의 Private 메서드들을 성격에 맞게 묶어 별도 정책 객체(Policy)나 포맷터(Formatter) 클래스로 분리합니다.
4. **Phase 4: 책임 검증 중심의 TDD 보강**
   * 로직이 캡슐화된 정책 객체 및 추출된 클래스들이 단일 책임을 제대로 수행하는지 점검하는 테스트를 추가합니다.

## 4. TDD 전략: 책임 검증 중심 (Responsibility-Driven Testing)

플로우(화면 이동, 전체 시나리오 진행)를 검증하는 E2E 성격의 테스트보다는, 이번 리팩터링으로 쪼개진 **각 객체가 맡은 단일 책임을 정확히 수행하는가**를 검증하는 단위 테스트(Unit Test)를 우선 작성합니다.

* **정책 객체 (Policy) 검증**: 
  * 예: `ContactPermissionPolicy`
  * 테스트 대상: 특정 권한 상태와 OS 버전이 주어졌을 때, 뷰에 노출해야 할 올바른 안내 메시지 타입이나 상태 열거형을 반환하는지 검증합니다.
* **포맷터 및 생성기 (Formatter / Generator) 검증**:
  * 예: `SmsTemplateGenerator`
  * 테스트 대상: 다양한 수신자 정보, 장소 이름, 알림 타입이 입력으로 주어졌을 때 정책에 맞는 SMS 메시지 문자열이 생성되는지 검증합니다.
* **검증기 (Validator) 검증**:
  * 예: `GeofenceEnrollValidator`
  * 테스트 대상: 폼 입력 데이터(반복 설정, 수신자, 위치 정보 등)를 주입하고, 유효한 데이터인지 혹은 예상된 에러 메시지를 반환하는지 검증합니다.
* **진행 방식**:
  * 대상 클래스를 분리하기 **전**에, 해당 클래스가 가져야 할 책임(입출력)을 정의하는 실패하는 테스트를 먼저 작성합니다.
  * 복잡한 Private 메서드들을 이 새로운 객체로 옮기며 테스트를 통과시킵니다.
  * UI(View)는 렌더링 로직만 남게 되므로, UI 위젯 테스트는 필요한 경우 시각적 렌더링 여부만 가볍게 확인합니다.
