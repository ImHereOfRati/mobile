import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';
import 'package:iamhere/feature/geofence/model/service/auto_send_status_service.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_service.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_recipient_service.dart';
import 'package:iamhere/feature/geofence/model/service/map_search_service.dart';
import 'package:iamhere/feature/geofence/viewmodel/geofence_list_view_model.dart';

/// 장소 탭의 첫 화면. 등록한 알림 장소와 자동 전송 준비 상태를 보여 준다.
class GeofencePage extends ConsumerStatefulWidget {
  final GeofenceService geofenceService;
  final GeofenceRecipientService recipientService;
  final MapSearchService mapSearchService;
  final AutoSendStatusService statusService;

  /// 활성 장소가 있으면 이 주기로 목록을 다시 읽는다. 도착 알림이 나가면 "출발 대기"
  /// 같은 상태가 백그라운드에서 바뀌기 때문이다.
  final Duration pollInterval;

  const GeofencePage({
    super.key,
    required this.geofenceService,
    required this.recipientService,
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
  bool _openingAddPlace = false;

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
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.md),
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.xl),
            ),
            children: [
              _AddPlaceAction(loading: _openingAddPlace, onTap: _openAddPlace),
              if (data.items.isEmpty) ...[
                SizedBox(height: metrics.resolve(ImHereSpace.xl)),
                const ImHereStatePanel(
                  glyph: ImHereGlyph.place,
                  title: '알림 받을 장소를 추가해 보세요',
                  description: '장소에 도착하거나 떠날 때 선택한 사람에게 알려드려요.',
                  size: ImHereStateSize.large,
                ),
              ] else ...[
                SizedBox(height: metrics.resolve(ImHereSpace.xl)),
                if (active.isNotEmpty) ...[
                  _PlaceSectionHeading(title: '알림 켜짐', count: active.length),
                  SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                  _placeGroup(active, metrics),
                ],
                if (inactive.isNotEmpty) ...[
                  if (active.isNotEmpty)
                    SizedBox(height: metrics.resolve(ImHereSpace.lg)),
                  _PlaceSectionHeading(title: '알림 꺼짐', count: inactive.length),
                  SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                  _placeGroup(inactive, metrics),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeGroup(List<GeofenceEntity> items, ImHereMetrics metrics) {
    final colors = ImHereColors.of(context);
    final radius = BorderRadius.circular(metrics.resolve(ImHereRadius.lg));
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _GeofenceCard(
              item: items[index],
              onOpen: () => items[index].isActive
                  ? context.push('/geofence/${items[index].id}')
                  : _openActions(items[index]),
              onToggle: (active) => _toggle(items[index], active),
            ),
            if (index < items.length - 1)
              const ImHereBorder(
                indent: ImHereSpace.md,
                tone: ImHereDividerTone.subtle,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAddPlace() async {
    if (_openingAddPlace) return;
    setState(() => _openingAddPlace = true);
    try {
      final recipients = await widget.recipientService.load();
      if (!mounted) return;
      if (recipients.isNotEmpty) {
        context.push('/geofence/message');
        return;
      }

      final addFriend = await showImHereDialog(
        context,
        title: '알림을 받을 사람이 없어요',
        description: 'ImHere 친구를 추가하거나 기기 연락처를 등록해 주세요.',
        confirmLabel: '친구 추가',
        cancelLabel: '나중에',
      );
      if (addFriend == true && mounted) context.push('/friend/add');
    } catch (_) {
      if (mounted) showImHereSnackbar(context, '받는 사람을 확인하지 못했어요');
    } finally {
      if (mounted) setState(() => _openingAddPlace = false);
    }
  }

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

class _PlaceSectionHeading extends StatelessWidget {
  const _PlaceSectionHeading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        ImHereBadge(
          label: '$count곳',
          tone: ImHereBadgeTone.neutral,
          size: ImHereBadgeSize.medium,
        ),
        SizedBox(width: metrics.resolve(ImHereSpace.xxs)),
      ],
    );
  }
}

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
  final bool loading;

  const _AddPlaceAction({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return ImHereButton(
      label: '장소 추가',
      icon: ImHereGlyph.add,
      tone: ImHereButtonTone.secondary,
      loading: loading,
      expand: true,
      onPressed: loading ? null : onTap,
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
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final eventType = EventType.fromName(item.eventType);
    final eventLabel = switch (eventType) {
      EventType.arrival => '도착 알림',
      EventType.departure => '출발 알림',
      EventType.both => '도착·출발 알림',
    };
    final repeat = GeofenceRepeat.fromName(item.repeatType);

    return Padding(
      padding: EdgeInsets.all(metrics.resolve(ImHereSpace.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(
                metrics.resolve(ImHereRadius.md),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: metrics.resolve(ImHereSpace.xxs),
                ),
                child: Row(
                  children: [
                    Container(
                      width: metrics.resolve(40),
                      height: metrics.resolve(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.actionSubtle,
                        borderRadius: BorderRadius.circular(
                          metrics.resolve(ImHereRadius.md),
                        ),
                      ),
                      child: ImHereIcon(
                        glyph: ImHereGlyph.place,
                        size: 22,
                        color: colors.action,
                      ),
                    ),
                    SizedBox(width: metrics.resolve(ImHereSpace.sm)),
                    Expanded(
                      child: Text(item.name, style: textTheme.titleSmall),
                    ),
                    ImHereIcon(
                      glyph: ImHereGlyph.chevron,
                      size: 20,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (item.address.isNotEmpty) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            Text(
              item.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          if (eventType == EventType.arrival)
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatGeofenceCondition(item),
                    style: textTheme.bodyMedium?.copyWith(color: colors.text),
                  ),
                ),
                SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                ImHereBadge(label: eventLabel),
              ],
            )
          else
            Text(
              formatGeofenceCondition(item),
              style: textTheme.bodyMedium?.copyWith(color: colors.text),
            ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          Wrap(
            spacing: metrics.resolve(ImHereSpace.xs),
            runSpacing: metrics.resolve(ImHereSpace.xs),
            children: [
              if (eventType != EventType.arrival)
                ImHereBadge(label: eventLabel),
              if (repeat != GeofenceRepeat.none)
                ImHereBadge(label: repeat.label, tone: ImHereBadgeTone.neutral),
              if (item.awaitingDeparture)
                const ImHereBadge(
                  label: '출발 대기',
                  tone: ImHereBadgeTone.warning,
                ),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          const ImHereBorder(tone: ImHereDividerTone.subtle),
          ImHereSwitch(
            label: '알림 사용',
            value: item.isActive,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
