import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/util/korean_text.dart';
import 'package:iamhere/feature/user_permission/model/app_permission.dart';
import 'package:iamhere/feature/user_permission/model/permission_guide_content.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';
import 'package:iamhere/feature/user_permission/view/widget/permission_step_sheet.dart';
import 'package:iamhere/feature/user_permission/viewmodel/permission_guide_view_model.dart';

/// 신규 회원이 앱 사용 권한을 한 번에 설정하는 안내 화면.
class PermissionGuidePage extends ConsumerStatefulWidget {
  final PermissionGuideService service;
  final VoidCallback onDone;

  /// 앱 셸이 이미 헤더를 그리는 화면(설정 하위)에서는 끈다.
  final bool showHeader;

  const PermissionGuidePage({
    super.key,
    required this.service,
    required this.onDone,
    this.showHeader = true,
  });

  @override
  ConsumerState<PermissionGuidePage> createState() =>
      _PermissionGuidePageState();
}

class _PermissionGuidePageState extends ConsumerState<PermissionGuidePage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 설정 앱에서 권한을 바꾸고 돌아오면 상태를 다시 읽는다.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    ref
        .read(permissionGuideViewModelProvider(widget.service).notifier)
        .refresh();
  }

  /// 시스템 화면으로 넘어가기 전에, 무엇을 눌러야 하는지 단계별로 알려 준다.
  Future<bool> _confirm(
    AppPermission permission, {
    required bool opensSettings,
  }) async {
    final content = PermissionGuideContent.of(
      permission,
      opensSettings: opensSettings,
      isAndroid: widget.service.isAndroid,
    );
    if (content == null) return true;
    return showPermissionStepSheet(context, content);
  }

  Future<void> _requestOne(AppPermission permission) {
    return ref
        .read(permissionGuideViewModelProvider(widget.service).notifier)
        .request(permission, confirm: _confirm);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionGuideViewModelProvider(widget.service));
    final viewModel = ref.read(
      permissionGuideViewModelProvider(widget.service).notifier,
    );
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final allGranted = state.loaded && viewModel.allGranted;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          if (widget.showHeader) const ImHereTopBar(title: '권한 설정'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                metrics.resolve(ImHereSpace.gutter),
                metrics.resolve(ImHereSpace.lg),
                metrics.resolve(ImHereSpace.gutter),
                metrics.resolve(ImHereSpace.md),
              ),
              children: [
                Text(
                  KoreanText.keepWords('ImHere를 쓰려면\n권한이 필요해요'),
                  style: textTheme.titleLarge,
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                Text(
                  KoreanText.keepWords('한 번에 허용하면 도착·출발 알림을 바로 쓸 수 있어요.'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.lg)),
                for (final permission in viewModel.permissions) ...[
                  _PermissionCard(
                    permission: permission,
                    state: state.states[permission],
                    attempted: state.attempted.contains(permission),
                    onTap: state.requestingAll
                        ? null
                        : () => _requestOne(permission),
                  ),
                  SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                ],
              ],
            ),
          ),
          ImHereBottomAction(
            label: allGranted ? '시작하기' : '모두 허용하기',
            loading: state.requestingAll,
            onPressed: allGranted
                ? widget.onDone
                : () => viewModel.requestAll(confirm: _confirm),
            secondaryLabel: allGranted ? null : '나중에 할게요',
            onSecondaryPressed: allGranted ? null : widget.onDone,
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AppPermission permission;
  final PermissionState? state;
  final bool attempted;
  final VoidCallback? onTap;

  const _PermissionCard({
    required this.permission,
    required this.state,
    required this.attempted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = ImHereColors.of(context);
    final info = _info(permission);
    final granted =
        state != null && PermissionGuideService.isGranted(permission, state!);
    final hint = granted ? null : _hint();

    return ImHereSurface(
      onTap: granted ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImHereAsset(glyph: info.glyph, label: info.title),
          SizedBox(width: metrics.resolve(ImHereSpace.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KoreanText.keepWords(info.title),
                  style: textTheme.titleSmall,
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                Text(
                  KoreanText.keepWords(info.description),
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
                if (hint != null) ...[
                  SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                  Text(
                    KoreanText.keepWords(hint),
                    style: textTheme.bodySmall?.copyWith(color: colors.warning),
                  ),
                ],
              ],
            ),
          ),
          if (state != null) ...[
            SizedBox(width: metrics.resolve(ImHereSpace.xs)),
            _badge(granted),
          ],
        ],
      ),
    );
  }

  Widget _badge(bool granted) {
    if (granted) {
      return const ImHereBadge(
        label: '허용됨',
        tone: ImHereBadgeTone.success,
        size: ImHereBadgeSize.medium,
      );
    }
    if (state == PermissionState.permanentlyDenied ||
        (permission == AppPermission.locationAlways && attempted)) {
      return const ImHereBadge(
        label: '설정에서 허용',
        tone: ImHereBadgeTone.warning,
        size: ImHereBadgeSize.medium,
      );
    }
    return const ImHereBadge(
      label: '허용 필요',
      tone: ImHereBadgeTone.action,
      size: ImHereBadgeSize.medium,
    );
  }

  String? _hint() {
    if (permission == AppPermission.locationAlways &&
        state == PermissionState.grantedWhenInUse) {
      return '설정 화면에서 "항상 허용"을 선택해 주세요.';
    }
    if (state == PermissionState.serviceDisabled) {
      return '기기의 위치 서비스를 켜 주세요.';
    }
    if (state == PermissionState.permanentlyDenied) {
      return '설정 앱에서 직접 허용해 주세요.';
    }
    return null;
  }

  static ({ImHereGlyph glyph, String title, String description}) _info(
    AppPermission permission,
  ) => switch (permission) {
    AppPermission.notification => (
      glyph: ImHereGlyph.bell,
      title: '알림',
      description: '친구 소식과 도착·출발 알림을 받아요.',
    ),
    AppPermission.locationAlways => (
      glyph: ImHereGlyph.place,
      title: '위치 (항상 허용)',
      description: '앱을 닫아도 등록한 장소에 도착하거나 떠난 걸 알아차려요.',
    ),
    AppPermission.batteryOptimization => (
      glyph: ImHereGlyph.settings,
      title: '배터리 최적화 제외',
      description: '절전 모드에서도 위치 감지가 끊기지 않아요.',
    ),
    AppPermission.contacts => (
      glyph: ImHereGlyph.friends,
      title: '연락처',
      description: '알림을 받을 사람을 연락처에서 골라요.',
    ),
  };
}
