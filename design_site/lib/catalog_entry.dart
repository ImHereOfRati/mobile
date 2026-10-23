enum CatalogSection { introduction, foundation, component }

enum CatalogEntry {
  start(
    '시작하기',
    CatalogSection.introduction,
    'ImHere는 위치를 바탕으로 소식을 전해요.\n사용자가 지금 무슨 일이 일어났는지 바로 알고 다음 행동을 고를 수 있게 만듭니다.',
  ),
  color(
    '색상',
    CatalogSection.foundation,
    '색 이름은 값을, 역할 이름은 쓰임을 나타냅니다.\n화면에는 역할에 맞는 색을 사용해요.',
  ),
  typography(
    '타이포그래피',
    CatalogSection.foundation,
    '제목과 본문의 역할을 나누고, 한국어 문장을 작은 화면에서도 편하게 읽을 수 있도록 맞춥니다.',
  ),
  spacing(
    '간격과 모서리',
    CatalogSection.foundation,
    '간격은 4의 배수, 좌우 여백은 20으로 맞춥니다.\n모서리는 버튼 12~14, 카드 24로 넉넉하게 둥글려요.\n그림자 대신 면과 선으로 구분해요.',
  ),
  safeArea(
    '안전 영역',
    CatalogSection.foundation,
    '상태 표시줄과 제스처 바 자리에는 내용을 놓지 않습니다.\n좌우 여백 16은 안전 영역 경계부터 재요.',
  ),
  badge(
    '배지',
    CatalogSection.component,
    '상태를 짧게 알릴 때 씁니다.\n색만 보고 뜻을 짐작하게 하지 말고 상태 이름을 함께 적어요.',
  ),
  border(
    '구분선',
    CatalogSection.component,
    '뜻이 바뀌는 경계에는 진한 선, 같은 종류가 반복되는 곳에는 연한 선을 씁니다.\n마지막 항목 뒤에는 넣지 않아요.',
  ),
  logo(
    '로고',
    CatalogSection.component,
    '로고는 여기어때 잘난체, 24 크기로 고정합니다.\n글꼴, 크기, 자간, 글자 크기 배율을 바꾸지 말고 색만 골라요.',
  ),
  bottomAction(
    '하단 버튼',
    CatalogSection.component,
    '이 화면에서 해야 할 일을 하단에 놓습니다.\n버튼에는 누른 뒤 일어날 일을 적어요.',
  ),
  button(
    '버튼',
    CatalogSection.component,
    '진한 면 버튼은 화면에 하나만 둡니다.\n나머지 행동은 연한 면이나 테두리 버튼으로 낮춰요.\n처리 중에는 여러 번 누르지 못하게 해요.',
  ),
  asset(
    '아이콘',
    CatalogSection.component,
    '아이콘은 내용을 빨리 찾도록 돕습니다.\n뜻이 모호하면 글자를 붙여요.',
  ),
  listRow(
    '목록 행',
    CatalogSection.component,
    '제목과 보조 정보를 한눈에 읽도록 묶습니다.\n행 전체를 눌러 상세 내용을 볼 수 있어요.',
  ),
  listHeader('목록 제목', CatalogSection.component, '목록이 무엇을 담고 있는지 알려줍니다.'),
  navigation(
    '내비게이션',
    CatalogSection.component,
    '서로 다른 주요 화면 사이를 이동할 때 씁니다.\n현재 위치가 늘 보여야 해요.',
  ),
  paragraph('본문', CatalogSection.component, '중요한 내용을 먼저 말하고, 필요한 이유를 뒤에 붙입니다.'),
  progress(
    '진행 상태',
    CatalogSection.component,
    '처리가 끝날 때까지 원형 인디케이터로 진행 중임을 알립니다.\n기본은 무채색이고, 파랑은 중요한 첫 순간에만 써요.',
  ),
  surface(
    '표면',
    CatalogSection.component,
    '관련된 내용을 하나로 묶을 때 씁니다.\n그림자와 배경색 대신 얇은 선으로 구분해요.',
  ),
  statePanel(
    '상태 안내',
    CatalogSection.component,
    '비어 있거나 실패했을 때 이유와 다음 행동을 알립니다.\n사과보다 해결 방법을 먼저 적어요.',
  ),
  textField(
    '입력창',
    CatalogSection.component,
    '라벨은 입력창 위에 늘 보이게 둡니다.\n오류가 나면 안내 문구를 오류 이유로 바꿔요.',
  ),
  chip(
    '칩',
    CatalogSection.component,
    '사용자가 고르거나 입력한 값을 알약 모양으로 보여줍니다.\n선택되면 글자색 면으로 뒤집어요.',
  ),
  toggle(
    '스위치',
    CatalogSection.component,
    '누르는 즉시 켜고 끄는 설정에 씁니다.\n저장 버튼을 눌러야 적용되는 선택에는 체크박스를 써요.',
  ),
  checkbox(
    '체크박스',
    CatalogSection.component,
    '여러 항목 중 원하는 만큼 고를 때 씁니다.\n선택 결과는 제출할 때 한꺼번에 적용돼요.',
  ),
  radio(
    '라디오',
    CatalogSection.component,
    '여러 항목 중 하나만 고를 때 씁니다.\n선택지는 한눈에 보이도록 펼쳐 둬요.',
  ),
  segmented(
    '세그먼트',
    CatalogSection.component,
    '같은 내용을 다른 기준으로 볼 때 씁니다.\n항목은 두 개에서 네 개까지만 둬요.',
  ),
  snackbar(
    '스낵바',
    CatalogSection.component,
    '행동의 결과를 짧게 알립니다.\n한 줄로 쓰고, 되돌리기 같은 행동은 하나만 붙여요.',
  ),
  dialog(
    '다이얼로그',
    CatalogSection.component,
    '꼭 답해야 하는 결정을 물을 때만 씁니다.\n되돌릴 수 없는 일에는 위험 버튼을 써요.',
  ),
  sheet(
    '바텀 시트',
    CatalogSection.component,
    '현재 화면을 벗어나지 않고 부가 작업을 할 때 씁니다.\n위쪽 손잡이로 끌어내릴 수 있어요.',
  ),
  skeleton(
    '스켈레톤',
    CatalogSection.component,
    '내용을 불러오는 동안 들어갈 자리를 먼저 보여줍니다.\n실제 내용과 크기를 맞춰요.',
  ),
  avatar(
    '아바타',
    CatalogSection.component,
    '사람이나 모임을 나타냅니다.\n사진이 없으면 이름의 첫 글자를 써요.',
  ),
  callout(
    '콜아웃',
    CatalogSection.component,
    '화면 안에서 알아 둘 내용을 알립니다.\n잠깐 보이는 알림은 스낵바를 써요.',
  ),
  notificationBadge(
    '알림 배지',
    CatalogSection.component,
    '읽지 않은 소식이 있음을 알립니다.\n한 번에 한 곳에만 표시하고 99를 넘으면 99+로 적어요.',
  ),
  tab(
    '탭',
    CatalogSection.component,
    '같은 화면 안의 정보를 바꿔 볼 때 씁니다.\n여섯 개부터는 글자 길이에 맞춰 옆으로 넘겨 봐요.',
  ),
  topBar(
    '상단 바',
    CatalogSection.component,
    '현재 화면의 제목과 나갈 길을 보여줍니다.\n한 단계 뒤로는 화살표, 흐름을 끝낼 때는 닫기를 써요.',
  );

  const CatalogEntry(this.title, this.section, this.description);

  final String title;
  final CatalogSection section;
  final String description;
}
