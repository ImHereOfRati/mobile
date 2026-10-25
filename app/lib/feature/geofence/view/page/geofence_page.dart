import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';
import 'package:iamhere/feature/geofence/model/service/auto_send_status_service.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_service.dart';
import 'package:iamhere/feature/geofence/model/service/map_search_service.dart';
import 'package:iamhere/feature/geofence/viewmodel/geofence_list_view_model.dart';

/// 장소 탭의 첫 화면. 등록한 알림 장소와 자동 전송 준비 상태를 보여 준다.
class GeofencePage extends ConsumerStatefulWidget {
  final GeofenceService geofenceService;
  final MapSearchService mapSearchService;
  final AutoSendStatusService statusService;

  /// 활성 장소가 있으면 이 주기로 목록을 다시 읽는다. 도착 알림이 나가면 "출발 대기"
  /// 같은 상태가 백그라운드에서 바뀌기 때문이다.
  final Duration pollInterval;

  const GeofencePage({
    super.key,
    required this.geofenceService,
    required this.mapSearchService,
    required this.statusService,
    this.pollInterval = const Duration(seconds: 5),
  });

  @override
  ConsumerState<GeofencePage> createState() => _GeofencePageState();
}

class _GeofencePageState extends ConsumerState<GeofencePage>
    with WidgetsBindingObserver {
  Timer? _poll;

  GeofenceListViewModelProvider get _provider => geofenceListViewModelProvider(
    widget.geofenceService,
    widget.mapSearchService,
    widget.statusService,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(widget.pollInterval, (_) {
      final items = ref.read(_provider).value?.items ?? const [];
      if (items.any((item) => item.isActive)) {
        ref.read(_provider.notifier).reloadItems();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 권한과 GPS는 설정 앱에서 바뀌므로 앱으로 돌아올 때마다 다시 읽는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(_provider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: AsyncStateView<GeofenceListState>(
        value: ref.watch(_provider),
        errorTitle: '알림 장소를 불러오지 못했어요',
        onRetry: () => ref.invalidate(_provider),
        builder: _content,
      ),
    );
  }

  Widget _content(GeofenceListState data) {
    final metrics = ImHereMetrics.of(context);
    final active = data.items.where((item) => item.isActive).toList();
    final inactive = data.items.where((item) => !item.isActive).toList();

    return Column(
      children: [
        if (!data.status.ready)
          _ReadinessBanner(
            status: data.status,
            onTap: () => context.push('/setting/permissions'),
          ),
        Expanded(
          child: data.items.isEmpty
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.resolve(ImHereSpace.gutter),
                    metrics.resolve(ImHereSpace.md),
                    metrics.resolve(ImHereSpace.gutter),
                    metrics.resolve(ImHereSpace.md),
                  ),
                  child: Column(
                    children: [
                      _AddPlaceAction(
                        onTap: () => context.push('/geofence/message'),
                      ),
                      const Expanded(
                        child: ImHereStatePanel(
                          glyph: ImHereGlyph.place,
                          title: '아직 등록한 장소가 없어요',
                          description: '도착하거나 떠날 때 알릴 장소를 추가해 보세요.',
                          size: ImHereStateSize.large,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    metrics.resolve(ImHereSpace.gutter),
                    metrics.resolve(ImHereSpace.md),
                    metrics.resolve(ImHereSpace.gutter),
                    metrics.resolve(ImHereSpace.xl),
                  ),
                  children: [
                    _AddPlaceAction(
                      onTap: () => context.push('/geofence/message'),
                    ),
                    SizedBox(height: metrics.resolve(ImHereSpace.lg)),
                    if (active.isNotEmpty) ...[
                      ImHereListHeader(title: '알림 켠 장소 ${active.length}곳'),
                      for (final item in active) _placeItem(item, metrics),
                    ],
                    if (inactive.isNotEmpty) ...[
                      if (active.isNotEmpty)
                        SizedBox(height: metrics.resolve(ImHereSpace.md)),
                      ImHereListHeader(title: '알림 꺼둔 장소 ${inactive.length}곳'),
                      for (final item in inactive) _placeItem(item, metrics),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _placeItem(GeofenceEntity item, ImHereMetrics metrics) => Padding(
    padding: EdgeInsets.only(bottom: metrics.resolve(ImHereSpace.xs)),
    child: _GeofenceCard(
      item: item,
      onOpen: () => _openActions(item),
      onToggle: (active) => _toggle(item, active),
    ),
  );

  Future<void> _toggle(GeofenceEntity item, bool active) async {
    final failure = await ref.read(_provider.notifier).toggle(item, active);
    if (failure != null && mounted) showImHereSnackbar(context, failure);
  }

  Future<void> _openActions(GeofenceEntity item) async {
    final action = await showImHereSheet<_PlaceAction>(
      context,
      title: item.name,
      builder: (sheetContext) {
        final metrics = ImHereMetrics.of(sheetContext);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImHereButton(
              label: '수정',
              tone: ImHereButtonTone.weak,
              expand: true,
              onPressed: () =>
                  Navigator.of(sheetContext).pop(_PlaceAction.edit),
            ),
            SizedBox(height: metrics.resolve(ImHereSpace.xs)),
            ImHereButton(
              label: '삭제',
              tone: ImHereButtonTone.danger,
              expand: true,
              onPressed: () =>
                  Navigator.of(sheetContext).pop(_PlaceAction.delete),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    switch (action) {
      case _PlaceAction.edit:
        context.push('/geofence/${item.id}/edit');
      case _PlaceAction.delete:
        await _confirmDelete(item);
      case null:
        break;
    }
  }

  Future<void> _confirmDelete(GeofenceEntity item) async {
    final confirmed = await showImHereDialog(
      context,
      title: '이 장소를 삭제할까요?',
      description: '삭제하면 이 장소의 자동 알림도 멈춰요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref.read(_provider.notifier).delete(item);
    if (mounted) showImHereSnackbar(context, failure ?? '알림 장소를 삭제했어요');
  }
}

enum _PlaceAction { edit, delete }

class _ReadinessBanner extends StatelessWidget {
  final AutoSendStatus status;
  final VoidCallback onTap;

  const _ReadinessBanner({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final message = !status.locationServiceEnabled
        ? status.missingPermissions > 0
              ? '휴대폰 위치를 켜고, 앱 권한도 확인해 주세요.'
              : '휴대폰 위치를 켜 주세요.'
        : '앱 권한을 확인해 주세요.';

    return Material(
      color: colors.warningSubtle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.resolve(ImHereSpace.gutter),
            vertical: metrics.resolve(ImHereSpace.sm),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_rounded,
                size: metrics.resolve(20),
                color: colors.warning,
              ),
              SizedBox(width: metrics.resolve(ImHereSpace.xs)),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SizedBox(width: metrics.resolve(ImHereSpace.xs)),
              ImHereIcon(
                glyph: ImHereGlyph.chevron,
                size: 18,
                color: colors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPlaceAction extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPlaceAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ImHereSurface(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: metrics.resolve(40),
            height: metrics.resolve(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.actionSubtle,
              shape: BoxShape.circle,
            ),
            child: ImHereIcon(
              glyph: ImHereGlyph.add,
              size: 22,
              color: colors.action,
            ),
          ),
          SizedBox(width: metrics.resolve(ImHereSpace.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('장소 추가', style: textTheme.titleSmall),
                SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                Text(
                  '도착하거나 떠날 때 알리기',
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(width: metrics.resolve(ImHereSpace.xs)),
          ImHereIcon(
            glyph: ImHereGlyph.chevron,
            size: 20,
            color: colors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _GeofenceCard extends StatelessWidget {
  final GeofenceEntity item;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  const _GeofenceCard({
    required this.item,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return ImHereSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImHereListRow(
            title: item.name,
            description: [
              if (item.address.isNotEmpty) item.address,
              if (item.awaitingDeparture) '출발 대기',
              formatGeofenceCondition(item),
              if (GeofenceRepeat.fromName(item.repeatType) case final repeat
                  when repeat != GeofenceRepeat.none)
                repeat.label,
            ].join(' · '),
            leading: const ImHereIcon(glyph: ImHereGlyph.place),
            alignTop: true,
            onTap: onOpen,
          ),
          const ImHereBorder(tone: ImHereDividerTone.subtle),
          SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          ImHereSwitch(
            label: '${item.name} 알림',
            value: item.isActive,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

/// 알림 조건을 한 줄로 풀어 쓴다.
String formatGeofenceCondition(GeofenceEntity item) {
  final radius = item.radius.round() == 1000
      ? '1km'
      : '${item.radius.round()}m';
  return switch (EventType.fromName(item.eventType)) {
    EventType.arrival => '$radius 안에 들어오면',
    EventType.departure => '$radius 밖으로 나가면',
    EventType.both => '$radius 안에 들어오거나 밖으로 나가면',
  };
}
