import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/list_skeleton.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_recipient_service.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_service.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_draft.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';
import 'package:iamhere/feature/geofence/model/type/recipient_option.dart';

class GeofenceDetailPage extends StatefulWidget {
  final GeofenceService geofenceService;
  final GeofenceRecipientService recipientService;
  final int id;

  const GeofenceDetailPage({
    super.key,
    required this.geofenceService,
    required this.recipientService,
    required this.id,
  });

  @override
  State<GeofenceDetailPage> createState() => _GeofenceDetailPageState();
}

class _GeofenceDetailPageState extends State<GeofenceDetailPage> {
  late Future<_GeofenceDetailData> _detail;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<_GeofenceDetailData> _load() async {
    final item = (await widget.geofenceService.findAll())
        .where((item) => item.id == widget.id)
        .firstOrNull;
    if (item == null) throw StateError('Geofence ${widget.id} not found');
    final draft = await widget.geofenceService.loadDraft(widget.id);
    if (draft == null) throw StateError('Geofence ${widget.id} not found');
    final options = await widget.recipientService.load();
    final recipients = options.where((option) {
      return option.source == RecipientSource.device
          ? draft.deviceContactIds.contains(option.key)
          : draft.serverRecipientKeys.contains(option.key);
    }).toList();
    return _GeofenceDetailData(
      item: item,
      draft: draft,
      recipients: recipients,
    );
  }

  Future<void> _setActive(GeofenceEntity item, bool active) async {
    setState(() => _updating = true);
    try {
      await widget.geofenceService.setActive(widget.id, active);
      if (mounted) setState(() => _detail = _load());
    } catch (_) {
      if (mounted) showImHereSnackbar(context, '알림 상태를 변경하지 못했어요');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _delete(GeofenceEntity item) async {
    final confirmed = await showImHereDialog(
      context,
      title: '장소를 삭제할까요?',
      description: '삭제하면 이 장소의 자동 알림이 중지돼요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.geofenceService.delete(widget.id);
      if (mounted) context.go('/geofence');
    } catch (_) {
      if (mounted) showImHereSnackbar(context, '장소를 삭제하지 못했어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: FutureBuilder<_GeofenceDetailData>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ListSkeleton(rows: 4);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ImHereStatePanel(
              glyph: ImHereGlyph.place,
              title: '장소 정보를 불러오지 못했어요',
              actionLabel: '다시 불러오기',
              onAction: () => setState(() => _detail = _load()),
            );
          }

          final data = snapshot.requireData;
          final item = data.item;
          final draft = data.draft;
          final repeat = GeofenceRepeat.fromName(item.repeatType);
          final event = EventType.fromName(item.eventType);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.navToTitle),
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.xl),
            ),
            children: [
              ImHereSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (item.address.isNotEmpty) ...[
                      SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                      ImHereParagraph(text: item.address, muted: true),
                    ],
                    SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                    ImHereBadge(
                      label: item.isActive ? '알림 켜짐' : '알림 꺼짐',
                      tone: item.isActive
                          ? ImHereBadgeTone.success
                          : ImHereBadgeTone.neutral,
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.lg)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatGeofenceCondition(item),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                  ImHereBadge(
                    label: _eventBadgeLabel(event),
                    tone: ImHereBadgeTone.action,
                  ),
                ],
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.md)),
              ImHereSwitch(
                label: '장소 알림 사용',
                value: item.isActive,
                onChanged: _updating
                    ? null
                    : (value) => _setActive(item, value),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.md)),
              const ImHereListHeader(title: '알림 설정'),
              ImHereSurface(
                child: Column(
                  children: [
                    _DetailRow(label: '감지 범위', value: draft.radius.label),
                    const ImHereBorder(tone: ImHereDividerTone.subtle),
                    _DetailRow(label: '반복', value: repeat.label),
                    const ImHereBorder(tone: ImHereDividerTone.subtle),
                    _DetailRow(
                      label: '받는 사람',
                      value: data.recipients.isEmpty
                          ? '선택된 사람 없음'
                          : data.recipients
                                .map((recipient) => recipient.label)
                                .join(', '),
                    ),
                  ],
                ),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.md)),
              const ImHereListHeader(title: '알림 메시지'),
              ImHereSurface(child: ImHereParagraph(text: draft.message)),
              SizedBox(height: metrics.resolve(ImHereSpace.lg)),
              Row(
                children: [
                  Expanded(
                    child: ImHereButton(
                      label: '삭제',
                      tone: ImHereButtonTone.danger,
                      expand: true,
                      onPressed: () => _delete(item),
                    ),
                  ),
                  SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                  Expanded(
                    child: ImHereButton(
                      label: '수정',
                      expand: true,
                      onPressed: () async {
                        await context.push('/geofence/${widget.id}/edit');
                        if (mounted) setState(() => _detail = _load());
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _eventBadgeLabel(EventType event) => switch (event) {
    EventType.arrival => '도착 알림',
    EventType.departure => '출발 알림',
    EventType.both => '도착·출발 알림',
  };
}

class _GeofenceDetailData {
  final GeofenceEntity item;
  final GeofenceDraft draft;
  final List<RecipientOption> recipients;

  const _GeofenceDetailData({
    required this.item,
    required this.draft,
    required this.recipients,
  });
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: metrics.resolve(ImHereSpace.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: metrics.resolve(88),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
