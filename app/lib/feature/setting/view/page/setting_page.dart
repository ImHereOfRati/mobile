import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/auth/view/widget/permission_disclosure_dialog.dart';
import 'package:iamhere/feature/setting/model/type/setting_status.dart';
import 'package:iamhere/feature/setting/model/service/setting_status_service_interface.dart';
import 'package:iamhere/feature/setting/model/service/user_me_service_interface.dart';
import 'package:iamhere/feature/setting/view/widget/setting_account_row.dart';
import 'package:iamhere/feature/setting/view/widget/setting_footer.dart';
import 'package:iamhere/feature/setting/view/widget/setting_nickname_sheet.dart';
import 'package:iamhere/feature/setting/view/widget/setting_permission_row.dart';
import 'package:iamhere/feature/setting/view/widget/setting_section.dart';
import 'package:iamhere/feature/setting/viewmodel/account_view_model.dart';
import 'package:iamhere/feature/setting/viewmodel/setting_status_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

const settingSupportUrl =
    'https://dsko.notion.site/37c2776ec1898041b254ee2870657dcc?pvs=105';

class SettingPage extends ConsumerStatefulWidget {
  final UserMeServiceInterface userMeService;
  final TokenStorageService tokenStorage;
  final SettingStatusServiceInterface statusService;
  final ValueNotifier<ThemeMode> themeMode;
  final Future<void> Function(ThemeMode) saveTheme;
  final VoidCallback onOpenSendHistory;
  final VoidCallback onOpenAgreements;
  final VoidCallback? onOpenPermissionGuide;
  final Future<bool> Function(Uri uri) openUrl;

  const SettingPage({
    super.key,
    required this.userMeService,
    required this.tokenStorage,
    required this.statusService,
    required this.themeMode,
    required this.saveTheme,
    required this.onOpenSendHistory,
    required this.onOpenAgreements,
    this.onOpenPermissionGuide,
    this.openUrl = _launchExternally,
  });

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage>
    with WidgetsBindingObserver {
  bool _withdrawing = false;

  AccountViewModelProvider get _accountProvider =>
      accountViewModelProvider(widget.userMeService, widget.tokenStorage);

  SettingStatusViewModelProvider get _statusProvider =>
      settingStatusViewModelProvider(widget.statusService);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 권한은 설정 앱에서 바뀌므로 앱으로 돌아올 때마다 다시 읽는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(_statusProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final account = ref.watch(_accountProvider);
    final status = ref.watch(_statusProvider).value;
    // 모두 허용돼 있으면 한 번에 설정하기 행을 보여 주지 않는다.
    final allPermissionsGranted =
        status != null &&
        _permissionItems.every((item) => status.isGranted(item.permission));

    return Scaffold(
      backgroundColor: colors.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.md),
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.xl),
        ),
        children: [
          SettingSection(
            title: '계정',
            children: [
              SettingAccountRow(
                account: account,
                onEditNickname: _editNickname,
                onRetry: () => ref.invalidate(_accountProvider),
              ),
            ],
          ),
          SettingSection(
            title: '디스플레이',
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeMode,
                builder: (context, _, __) => ImHereSwitch(
                  label: '다크 모드',
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: _setDark,
                ),
              ),
            ],
          ),
          SettingSection(
            title: '앱 사용 권한',
            children: [
              for (final item in _permissionItems)
                SettingPermissionRow(
                  label: item.label,
                  granted: status?.isGranted(item.permission) ?? false,
                  onTap: () => _onPermissionTap(item.permission),
                ),
              if (widget.onOpenPermissionGuide != null &&
                  !allPermissionsGranted)
                ImHereListRow(
                  title: '한 번에 설정하기',
                  description: '모든 권한을 이어서 허용해요',
                  onTap: widget.onOpenPermissionGuide,
                ),
            ],
          ),
          SettingSection(
            title: '약관',
            children: [
              ImHereListRow(title: '약관 동의 관리', onTap: widget.onOpenAgreements),
            ],
          ),
          SettingSection(
            title: '전송 진단',
            children: [
              ImHereListRow(
                title: '마지막 자동 전송',
                description: _lastDeliveryText(status?.lastDelivery),
                onTap: widget.onOpenSendHistory,
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: metrics.resolve(ImHereSpace.sm),
                ),
                child: Text(
                  '일부 기기의 제조사 절전 설정은 자동 전송을 막을 수 있어요. '
                  '전송이 누락되면 절전 설정에서 ImHere를 제외해 주세요.',
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
          SettingSection(
            title: '고객 지원',
            children: [ImHereListRow(title: '문의하기', onTap: _openSupport)],
          ),
          SettingSection(
            title: '앱 정보',
            divider: false,
            children: [
              ImHereListRow(
                title: '버전 정보',
                trailing: Text(
                  status?.appVersion ?? '정보 없음',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.xl)),
          SettingFooter(
            withdrawing: _withdrawing,
            onSignOut: _confirmSignOut,
            onWithdraw: _confirmWithdraw,
          ),
        ],
      ),
    );
  }

  String _lastDeliveryText(LastDelivery? delivery) {
    if (delivery == null) return '아직 없음';
    return '${delivery.geofenceName} · ${_formatTime(delivery.occurredAt)}';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _setDark(bool dark) async {
    final next = dark ? ThemeMode.dark : ThemeMode.light;
    widget.themeMode.value = next;
    SystemChrome.setSystemUIOverlayStyle(
      dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
    await widget.saveTheme(next);
  }

  Future<void> _onPermissionTap(SettingPermission permission) async {
    final viewModel = ref.read(_statusProvider.notifier);
    final outcome = await viewModel.onPermissionTap(permission);
    if (!mounted) return;
    switch (outcome) {
      case PermissionTapOutcome.done:
        return;
      case PermissionTapOutcome.failed:
        showImHereSnackbar(context, '권한 설정을 열지 못했어요.');
      case PermissionTapOutcome.needsLocationDisclosure:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => const LocationDisclosureDialog(),
        );
        if (confirmed != true || !mounted) return;
        if (!await viewModel.openAppSettings() && mounted) {
          showImHereSnackbar(context, '권한 설정을 열지 못했어요.');
        }
    }
  }

  Future<void> _openSupport() async {
    var opened = false;
    try {
      opened = await widget.openUrl(Uri.parse(settingSupportUrl));
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      showImHereSnackbar(context, '문의하기 페이지를 열지 못했어요.');
    }
  }

  Future<void> _editNickname(String current) async {
    final saved = await showNicknameSheet(
      context,
      initial: current,
      onSave: ref.read(_accountProvider.notifier).changeNickname,
    );
    if (saved == true && mounted) {
      showImHereSnackbar(context, '닉네임을 변경했어요.');
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showImHereDialog(
      context,
      title: '로그아웃할까요?',
      confirmLabel: '로그아웃',
    );
    if (confirmed != true) return;
    await ref.read(_accountProvider.notifier).signOut();
  }

  Future<void> _confirmWithdraw() async {
    final confirmed = await showImHereDialog(
      context,
      title: '회원 탈퇴할까요?',
      description: '계정과 연결된 정보가 삭제되며 되돌릴 수 없어요.',
      confirmLabel: '회원 탈퇴',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _withdrawing = true);
    final message = await ref.read(_accountProvider.notifier).withdraw();
    if (!mounted) return;
    setState(() => _withdrawing = false);
    if (message != null) showImHereSnackbar(context, message);
  }

  static const _permissionItems = [
    _PermissionItem(SettingPermission.notification, '앱 알림 권한'),
    _PermissionItem(SettingPermission.locationAlways, '위치 권한 (항상 허용)'),
    _PermissionItem(SettingPermission.batteryOptimization, '배터리 최적화 제외'),
    _PermissionItem(SettingPermission.contacts, '연락처 접근 권한'),
  ];
}

class _PermissionItem {
  final SettingPermission permission;
  final String label;

  const _PermissionItem(this.permission, this.label);
}
