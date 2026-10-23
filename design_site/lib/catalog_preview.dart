import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

import 'catalog_entry.dart';
import 'typography_catalog.dart';

class CatalogPreview extends StatefulWidget {
  const CatalogPreview({
    super.key,
    required this.entry,
    required this.onMessage,
  });

  final CatalogEntry entry;
  final ValueChanged<String> onMessage;

  @override
  State<CatalogPreview> createState() => _CatalogPreviewState();
}

class _CatalogPreviewState extends State<CatalogPreview> {
  int tabIndex = 0;
  int segmentIndex = 0;
  bool toggleValue = true;
  bool checkValue = false;
  String radioValue = 'all';
  final chips = <String>{'친구'};

  @override
  Widget build(BuildContext context) => _preview();

  Widget _preview() => switch (widget.entry) {
    CatalogEntry.start => _overview(),
    CatalogEntry.color => _colors(),
    CatalogEntry.typography => const TypographyCatalog(),
    CatalogEntry.spacing => _spacing(),
    CatalogEntry.safeArea => _safeArea(),
    CatalogEntry.logo => _logo(),
    CatalogEntry.badge => _badges(),
    CatalogEntry.border => _border(),
    CatalogEntry.bottomAction => _bottomAction(),
    CatalogEntry.button => _buttons(),
    CatalogEntry.asset => _assets(),
    CatalogEntry.listRow => _rows(),
    CatalogEntry.listHeader => _header(),
    CatalogEntry.navigation => _navigation(),
    CatalogEntry.paragraph => _paragraph(),
    CatalogEntry.progress => const Center(child: ImHereProgress()),
    CatalogEntry.surface => _surface(),
    CatalogEntry.statePanel => _statePanel(),
    CatalogEntry.textField => _textField(),
    CatalogEntry.chip => _chips(),
    CatalogEntry.toggle => _toggle(),
    CatalogEntry.checkbox => _checkbox(),
    CatalogEntry.radio => _radio(),
    CatalogEntry.segmented => _segmented(),
    CatalogEntry.snackbar => _snackbar(),
    CatalogEntry.dialog => _dialog(),
    CatalogEntry.sheet => _sheet(),
    CatalogEntry.skeleton => _skeleton(),
    CatalogEntry.avatar => _avatar(),
    CatalogEntry.callout => _callout(),
    CatalogEntry.notificationBadge => _notificationBadge(),
    CatalogEntry.tab => _tabs(),
    CatalogEntry.topBar => _topBar(),
  };

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('만드는 기준', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      const ImHereParagraph(
        text: '믿을 수 있는 정보를 빠르게 전합니다. 화면에는 지금 필요한 내용과 다음 행동을 남깁니다.',
      ),
      const SizedBox(height: 20),
      const ImHereBadge(label: '위치 알림 켜짐', tone: ImHereBadgeTone.success),
      const SizedBox(height: 20),
      ImHereButton(
        label: '알림 내역 보기',
        onPressed: () => _showMessage('알림 내역을 열었어요.'),
      ),
    ],
  );

  Widget _colors() {
    final colors = ImHereColors.of(context);
    final samples = [
      ('주요 행동', colors.action),
      ('행동 위 글자', colors.onAction),
      ('약한 강조', colors.actionSubtle),
      ('글자', colors.text),
      ('보조 글자', colors.textMuted),
      ('배경', colors.background),
      ('표면', colors.surface),
      ('보조 표면', colors.surfaceSubtle),
      ('구분선', colors.border),
      ('성공', colors.success),
      ('주의', colors.warning),
      ('오류', colors.error),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = ImHereMetrics.of(context).resolve(8);
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (name, color) in samples) _swatch(name, color, width),
          ],
        );
      },
    );
  }

  Widget _swatch(String name, Color color, double width) {
    final textColor = color.computeLuminance() > 0.179
        ? Colors.black
        : Colors.white;
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return Container(
      width: width,
      constraints: BoxConstraints(
        minHeight: ImHereMetrics.of(context).resolve(80),
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: ImHereColors.of(context).border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('#${hex.toUpperCase()}', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _spacing() {
    final colors = ImHereColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, value) in [
          ('4', 4.0),
          ('8', 8.0),
          ('12', 12.0),
          ('16', 16.0),
          ('24', 24.0),
          ('32', 32.0),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text(name)),
                Container(
                  width: value * 5,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors.action,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _safeArea() {
    final insets = MediaQuery.paddingOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImHereCallout(text: '붉게 표시된 위·아래 띠에는 글자와 버튼을 놓지 않아요.'),
        const SizedBox(height: 16),
        ImHereListRow(
          title: '위쪽',
          description: '상태 표시줄과 카메라 구멍 · ${insets.top.round()}dp',
        ),
        const ImHereBorder(tone: ImHereDividerTone.subtle),
        ImHereListRow(
          title: '아래쪽',
          description: '제스처 바 · ${insets.bottom.round()}dp',
        ),
        const ImHereBorder(tone: ImHereDividerTone.subtle),
        const ImHereListRow(title: '좌우', description: '안전 영역 경계에서 16dp'),
        const SizedBox(height: 16),
        const ImHereParagraph(
          text: '상단 바는 위쪽을, 하단 버튼과 내비게이션은 아래쪽을 스스로 비켜 갑니다.',
          muted: true,
        ),
      ],
    );
  }

  Widget _badges() => const Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ImHereBadge(label: '전송 중'),
      ImHereBadge(label: '전송 완료', tone: ImHereBadgeTone.success),
      ImHereBadge(label: '확인 필요', tone: ImHereBadgeTone.warning),
      ImHereBadge(label: '전송 실패', tone: ImHereBadgeTone.error),
    ],
  );

  Widget _border() => const Column(
    children: [
      Text('첫 번째 내용'),
      SizedBox(height: 16),
      ImHereBorder(),
      SizedBox(height: 16),
      Text('다음 내용'),
      SizedBox(height: 16),
      ImHereBorder(tone: ImHereDividerTone.subtle),
      SizedBox(height: 16),
      Text('같은 종류의 내용'),
    ],
  );

  Widget _bottomAction() => ImHereBottomAction(
    label: '장소 저장하기',
    onPressed: () => _showMessage('장소를 저장했어요.'),
    secondaryLabel: '닫기',
    onSecondaryPressed: () => _showMessage('닫았어요.'),
  );

  Widget _buttons() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ImHereButton(label: '알림 보내기', onPressed: () => _showMessage('알림을 보냈어요.')),
      ImHereButton(
        label: '자세히 보기',
        tone: ImHereButtonTone.secondary,
        onPressed: () => _showMessage('상세 내용을 열었어요.'),
      ),
      ImHereButton(
        label: '확인하기',
        tone: ImHereButtonTone.neutral,
        onPressed: () => _showMessage('확인했어요.'),
      ),
      ImHereButton(
        label: '나중에',
        tone: ImHereButtonTone.weak,
        onPressed: () => _showMessage('나중에 볼게요.'),
      ),
      ImHereButton(
        label: '더 보기',
        tone: ImHereButtonTone.ghost,
        onPressed: () => _showMessage('더 보여줘요.'),
      ),
      const ImHereButton(label: '저장 중', onPressed: null, loading: true),
      const ImHereButton(label: '보낼 수 없어요', onPressed: null),
      ImHereButton(
        label: '닫기',
        tone: ImHereButtonTone.quiet,
        size: ImHereButtonSize.sm,
        onPressed: () => _showMessage('닫았어요.'),
      ),
      ImHereButton(
        label: '삭제하기',
        tone: ImHereButtonTone.danger,
        size: ImHereButtonSize.lg,
        onPressed: () => _showMessage('삭제했어요.'),
      ),
    ],
  );

  Widget _assets() => const Wrap(
    spacing: 12,
    children: [
      ImHereAsset(glyph: ImHereGlyph.place, label: '장소'),
      ImHereAsset(glyph: ImHereGlyph.bell, label: '알림'),
      ImHereAsset(glyph: ImHereGlyph.friends, label: '친구'),
    ],
  );

  Widget _rows() => Column(
    children: [
      ImHereListRow(
        title: '회사',
        description: '서울 강남구 테헤란로',
        leading: const ImHereAsset(glyph: ImHereGlyph.place, label: '장소'),
        onTap: () => _showMessage('회사 장소를 열었어요.'),
      ),
      const ImHereBorder(),
      ImHereListRow(
        title: '집',
        description: '도착 알림 켜짐',
        leading: const ImHereAsset(glyph: ImHereGlyph.home, label: '집'),
        onTap: () => _showMessage('집 장소를 열었어요.'),
      ),
    ],
  );

  Widget _header() => ImHereListHeader(
    title: '저장한 장소',
    actionLabel: '모두 보기',
    onAction: () => _showMessage('저장한 장소를 모두 보여줘요.'),
  );

  Widget _navigation() => const ImHereParagraph(
    text: '내비게이션은 모든 미리보기에서 화면 아래에 고정돼요. 아래 막대를 눌러 보세요.',
    muted: true,
  );

  Widget _surface() => ImHereSurface(
    onTap: () => _showMessage('장소 정보를 열었어요.'),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImHereParagraph(text: '회사 근처 도착 알림'),
        SizedBox(height: 4),
        ImHereParagraph(text: '평일 오전 8시부터 켜져 있어요.', muted: true),
      ],
    ),
  );

  Widget _statePanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ImHereStatePanel(
        glyph: ImHereGlyph.place,
        title: '저장한 장소가 없어요',
        description: '자주 가는 곳을 등록하면 도착했을 때 알려드려요.',
        actionLabel: '장소 추가하기',
        onAction: () => _showMessage('장소 추가 화면을 열었어요.'),
      ),
      const ImHereBorder(),
      ImHereStatePanel(
        glyph: ImHereGlyph.bell,
        title: '알림을 불러오지 못했어요',
        description: '네트워크 연결을 확인한 뒤 다시 시도해 주세요.',
        actionLabel: '다시 시도',
        onAction: () => _showMessage('다시 불러오고 있어요.'),
        secondaryLabel: '돌아가기',
        onSecondary: () => _showMessage('이전 화면으로 돌아가요.'),
      ),
    ],
  );

  Widget _textField() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ImHereTextField(
        label: '장소 이름',
        hint: '예: 회사',
        helper: '친구에게도 이 이름으로 보여요.',
        maxLength: 20,
      ),
      SizedBox(height: 20),
      ImHereTextField(label: '메모', hint: '기억할 내용을 적어요', optional: true),
      SizedBox(height: 20),
      ImHereTextField(
        label: '친구 연락처',
        hint: '010-0000-0000',
        errorText: '연락처 형식이 맞지 않아요.',
        keyboardType: TextInputType.phone,
      ),
    ],
  );

  Widget _chips() => Wrap(
    spacing: 8,
    children: [
      for (final label in ['친구', '가족', '회사', '동네'])
        ImHereChip(
          label: label,
          selected: chips.contains(label),
          onChanged: (on) =>
              setState(() => on ? chips.add(label) : chips.remove(label)),
        ),
    ],
  );

  Widget _toggle() => Column(
    children: [
      ImHereSwitch(
        label: '도착 알림',
        value: toggleValue,
        onChanged: (v) => setState(() => toggleValue = v),
      ),
      const ImHereBorder(tone: ImHereDividerTone.subtle),
      const ImHereSwitch(label: '조용한 시간', value: false, onChanged: null),
    ],
  );

  Widget _checkbox() => ImHereCheckbox(
    label: '친구에게 도착 소식 보내기',
    value: checkValue,
    onChanged: (v) => setState(() => checkValue = v),
  );

  Widget _radio() => Column(
    children: [
      for (final (value, label) in [
        ('all', '모든 친구'),
        ('some', '선택한 친구'),
        ('none', '보내지 않기'),
      ])
        ImHereRadio<String>(
          label: label,
          value: value,
          groupValue: radioValue,
          onChanged: (v) => setState(() => radioValue = v),
        ),
    ],
  );

  Widget _segmented() => ImHereSegmentedControl(
    labels: const ['전체', '도착', '출발'],
    index: segmentIndex,
    onChanged: (v) => setState(() => segmentIndex = v),
  );

  Widget _snackbar() => ImHereButton(
    label: '스낵바 보기',
    tone: ImHereButtonTone.weak,
    onPressed: () => showImHereSnackbar(
      context,
      '장소를 저장했어요.',
      actionLabel: '되돌리기',
      onAction: () => _showMessage('저장을 취소했어요.'),
    ),
  );

  Widget _dialog() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ImHereButton(
        label: '삭제 확인',
        tone: ImHereButtonTone.danger,
        onPressed: () async {
          final ok = await showImHereDialog(
            context,
            title: '이 장소를 삭제할까요?',
            description: '삭제하면 도착 알림도 함께 사라져요.',
            confirmLabel: '삭제하기',
            destructive: true,
          );
          if (ok == true) _showMessage('삭제했어요.');
        },
      ),
    ],
  );

  Widget _sheet() => ImHereButton(
    label: '시트 열기',
    tone: ImHereButtonTone.weak,
    onPressed: () => showImHereSheet<void>(
      context,
      title: '알림 받을 사람',
      builder: (_) =>
          const ImHereParagraph(text: '도착했을 때 소식을 받을 친구를 골라요.', muted: true),
    ),
  );

  Widget _skeleton() => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ImHereSkeleton(width: 44, height: 44, circle: true),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImHereSkeleton(width: 140, height: 18),
            SizedBox(height: 8),
            ImHereSkeleton(height: 14),
          ],
        ),
      ),
    ],
  );

  Widget _logo() {
    final colors = ImHereColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ImHereLogo(),
        const SizedBox(height: 20),
        ImHereLogo(color: colors.action),
        const SizedBox(height: 20),
        const ImHereLogo(caption: 'Design'),
      ],
    );
  }

  Widget _avatar() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ImHereAvatar(name: '민지', size: ImHereAvatarSize.xs),
          ImHereAvatar(name: '민지', size: ImHereAvatarSize.sm),
          ImHereAvatar(name: '민지'),
          ImHereAvatar(name: '민지', size: ImHereAvatarSize.lg),
        ],
      ),
      SizedBox(height: 20),
      Wrap(
        spacing: 12,
        children: [
          ImHereAvatar(name: ''),
          ImHereAvatar(name: '', size: ImHereAvatarSize.lg),
        ],
      ),
      SizedBox(height: 20),
      ImHereAvatarGroup(names: ['민지', '준호', '서연', '하준', '지우']),
    ],
  );

  Widget _callout() => const Column(
    children: [
      ImHereCallout(text: '위치 권한이 켜져 있어야 도착 알림을 보낼 수 있어요.'),
      SizedBox(height: 12),
      ImHereCallout(
        tone: ImHereCalloutTone.warning,
        title: '배터리 절약 모드',
        text: '절약 모드에서는 알림이 늦게 도착할 수 있어요.',
      ),
      SizedBox(height: 12),
      ImHereCallout(
        tone: ImHereCalloutTone.error,
        title: '알림을 보내지 못했어요',
        text: '네트워크 연결을 확인해 주세요.',
      ),
    ],
  );

  Widget _notificationBadge() => const Wrap(
    spacing: 32,
    runSpacing: 24,
    children: [
      ImHereNotificationBadge(
        child: ImHereIcon(glyph: ImHereGlyph.bell, size: 28),
      ),
      ImHereNotificationBadge(
        count: 3,
        child: ImHereIcon(glyph: ImHereGlyph.bell, size: 28),
      ),
      ImHereNotificationBadge(
        count: 128,
        child: ImHereIcon(glyph: ImHereGlyph.bell, size: 28),
      ),
    ],
  );

  Widget _paragraph() => const ImHereParagraph(
    text: '장소를 등록하면 근처에 도착했을 때 선택한 사람에게 알림을 보내요. 알림은 언제든 끌 수 있어요.',
  );

  Widget _tabs() => ImHereTabBar(
    labels: const ['받은 알림', '보낸 알림'],
    index: tabIndex,
    onChanged: (value) => setState(() => tabIndex = value),
  );

  Widget _topBar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ImHereParagraph(
        text: '맨 위 막대는 한 단계 뒤로 가는 형태예요. 아래는 흐름을 끝내는 닫기 형태예요.',
        muted: true,
      ),
      const SizedBox(height: 16),
      ImHereTopBar(title: '장소 추가', onClose: () => _showMessage('추가를 그만뒀어요.')),
    ],
  );

  void _showMessage(String message) => widget.onMessage(message);
}
