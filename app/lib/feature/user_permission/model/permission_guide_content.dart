import 'package:iamhere/feature/user_permission/model/app_permission.dart';

/// 시스템 화면에 나오는 선택지 하나. [target]이 사용자가 눌러야 하는 항목이다.
class GuideOption {
  final String label;
  final bool target;

  const GuideOption(this.label, {this.target = false});
}

/// 안내의 한 단계. 한 단계에는 동작 하나만 담는다.
class GuideStep {
  /// 해야 할 동작 한 문장.
  final String text;

  /// [text] 안에서 눈에 띄게 보여 줄 말. 눌러야 할 이름을 가리킨다.
  final List<String> highlights;

  /// 동작을 보충하는 한 줄.
  final String? note;

  const GuideStep(this.text, {this.highlights = const [], this.note});
}

/// 설정 화면이나 시스템 창으로 보내기 전에 보여 주는 안내 내용.
///
/// 어디로 가서 무엇을 눌러야 하는지 단계마다 명시하고, 눌러야 할 항목은
/// 미리보기에서 깜빡여 보여 준다.
class PermissionGuideContent {
  final String title;

  /// 사용 목적 안내. 백그라운드 위치처럼 이유를 먼저 밝혀야 하는 권한에 쓴다.
  final String? purpose;
  final List<GuideStep> steps;
  final String previewTitle;
  final List<GuideOption> options;

  /// 이동 버튼 이름. 첫 단계가 이 이름을 그대로 가리킨다.
  final String confirmLabel;

  const PermissionGuideContent({
    required this.title,
    required this.steps,
    required this.previewTitle,
    required this.options,
    required this.confirmLabel,
    this.purpose,
  });

  static const _locationPurpose =
      '앱을 닫아도 위치를 확인해요.\n'
      '등록한 장소에 도착하거나 떠나면 선택한 친구에게 알려요.';

  static const _backStep = GuideStep(
    '뒤로 가기로 ImHere에 돌아와요.',
    note: '허용했는지는 자동으로 확인해요.',
  );

  /// [opensSettings]가 true면 시스템 창이 아니라 앱 설정 화면으로 이동한다.
  /// 안내가 필요 없는 요청(처음 보내는 알림·연락처 권한)은 null을 돌려준다.
  static PermissionGuideContent? of(
    AppPermission permission, {
    required bool opensSettings,
    required bool isAndroid,
  }) {
    if (opensSettings) return _settings(permission);
    return switch (permission) {
      AppPermission.locationAlways => _location(isAndroid: isAndroid),
      AppPermission.batteryOptimization => _battery(),
      AppPermission.notification || AppPermission.contacts => null,
    };
  }

  static PermissionGuideContent _location({required bool isAndroid}) {
    if (!isAndroid) {
      return const PermissionGuideContent(
        title: '위치를 항상 허용해 주세요',
        purpose: _locationPurpose,
        steps: [
          GuideStep('계속 버튼을 눌러요.', highlights: ['계속']),
          GuideStep('나오는 창에서 항상 허용으로 변경을 눌러요.', highlights: ['항상 허용으로 변경']),
        ],
        previewTitle: '이런 창이 나와요',
        options: [
          GuideOption('항상 허용으로 변경', target: true),
          GuideOption('앱 사용 중에만 허용 유지'),
        ],
        confirmLabel: '계속',
      );
    }
    return const PermissionGuideContent(
      title: '위치를 항상 허용해 주세요',
      purpose: _locationPurpose,
      steps: [
        GuideStep('설정으로 이동 버튼을 눌러요.', highlights: ['설정으로 이동']),
        GuideStep('위치 권한 화면에서 항상 허용을 눌러요.', highlights: ['항상 허용']),
        _backStep,
      ],
      previewTitle: '위치 권한 화면은 이렇게 보여요',
      options: [
        GuideOption('항상 허용', target: true),
        GuideOption('앱 사용 중에만 허용'),
        GuideOption('허용 안 함'),
      ],
      confirmLabel: '설정으로 이동',
    );
  }

  static PermissionGuideContent _battery() => const PermissionGuideContent(
    title: '배터리 최적화에서 제외해 주세요',
    purpose: '절전 모드에서도 위치 감지가 끊기지 않아요.',
    steps: [
      GuideStep('계속 버튼을 눌러요.', highlights: ['계속']),
      GuideStep('나오는 창에서 허용을 눌러요.', highlights: ['허용']),
    ],
    previewTitle: '이런 창이 나와요',
    options: [GuideOption('허용', target: true), GuideOption('거부')],
    confirmLabel: '계속',
  );

  /// 권한을 영구 거부했거나 한 번 요청해도 달라지지 않아, 앱 설정에서 직접
  /// 바꿔야 하는 경우.
  static PermissionGuideContent _settings(AppPermission permission) {
    final (name, selection, options) = switch (permission) {
      AppPermission.locationAlways => (
        '위치',
        const GuideStep('항상 허용을 선택해요.', highlights: ['항상 허용']),
        const [
          GuideOption('항상 허용', target: true),
          GuideOption('앱 사용 중에만 허용'),
          GuideOption('허용 안 함'),
        ],
      ),
      AppPermission.notification => (
        '알림',
        const GuideStep('알림 허용을 켜요.', highlights: ['알림 허용']),
        const [GuideOption('알림 허용', target: true)],
      ),
      AppPermission.contacts => (
        '연락처',
        const GuideStep('허용을 선택해요.', highlights: ['허용']),
        const [GuideOption('허용', target: true), GuideOption('허용 안 함')],
      ),
      AppPermission.batteryOptimization => (
        '배터리',
        const GuideStep('제한 없음을 선택해요.', highlights: ['제한 없음']),
        const [
          GuideOption('제한 없음', target: true),
          GuideOption('최적화'),
          GuideOption('제한'),
        ],
      ),
    };
    final isBattery = permission == AppPermission.batteryOptimization;
    return PermissionGuideContent(
      title: '$name 설정을 직접 바꿔 주세요',
      purpose: permission == AppPermission.locationAlways
          ? _locationPurpose
          : null,
      steps: [
        const GuideStep(
          '설정으로 이동 버튼을 눌러요.',
          highlights: ['설정으로 이동'],
          note: 'ImHere 앱 정보 화면이 열려요.',
        ),
        if (isBattery)
          const GuideStep('배터리를 눌러요.', highlights: ['배터리'])
        else
          GuideStep('권한을 누른 뒤 $name 항목을 눌러요.', highlights: ['권한', name]),
        selection,
        _backStep,
      ],
      previewTitle: '$name 화면은 이렇게 보여요',
      options: options,
      confirmLabel: '설정으로 이동',
    );
  }
}
