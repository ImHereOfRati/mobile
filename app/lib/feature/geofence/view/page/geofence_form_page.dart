import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_recipient_service.dart';
import 'package:iamhere/feature/geofence/model/service/geofence_service.dart';
import 'package:iamhere/feature/geofence/model/service/map_search_service.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_draft.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_radius.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';
import 'package:iamhere/feature/geofence/model/type/recipient_option.dart';
import 'package:iamhere/feature/geofence/view/widget/geofence_map_picker.dart';
import 'package:iamhere/feature/geofence/view/widget/place_search_box.dart';
import 'package:iamhere/feature/geofence/viewmodel/geofence_form_view_model.dart';
import 'package:iamhere/feature/user_permission/model/app_permission.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';

/// 알림 장소를 새로 만들거나 고친다. [id]가 null이면 새로 만든다.
class GeofenceFormPage extends ConsumerStatefulWidget {
  final GeofenceService geofenceService;
  final GeofenceRecipientService recipientService;
  final MapSearchService mapSearchService;
  final PermissionGuideService permissionGuide;
  final int? id;

  const GeofenceFormPage({
    super.key,
    required this.geofenceService,
    required this.recipientService,
    required this.mapSearchService,
    required this.permissionGuide,
    this.id,
  });

  @override
  ConsumerState<GeofenceFormPage> createState() => _GeofenceFormPageState();
}

class _GeofenceFormPageState extends ConsumerState<GeofenceFormPage> {
  final _name = TextEditingController();
  final _message = TextEditingController();
  final _address = TextEditingController();

  GeofenceFormViewModelProvider get _provider => geofenceFormViewModelProvider(
    widget.geofenceService,
    widget.recipientService,
    widget.mapSearchService,
    widget.id,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requireAlwaysLocation(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    _address.dispose();
    super.dispose();
  }

  /// 항상 허용된 위치 권한이 없으면 장소를 등록해도 앱이 닫힌 뒤에는 감지되지 않는다.
  /// 먼저 권한 안내로 보낸다.
  Future<void> _requireAlwaysLocation() async {
    final state = await widget.permissionGuide.check(
      AppPermission.locationAlways,
    );
    if (!mounted) return;
    if (!PermissionGuideService.isGranted(
      AppPermission.locationAlways,
      state,
    )) {
      context.go('/setting/permissions');
    }
  }

  /// 지도나 검색으로 이름과 메시지가 바뀌면 입력칸도 같은 값으로 맞춘다.
  void _syncControllers(GeofenceDraft draft) {
    _setText(_name, draft.name);
    _setText(_message, draft.message);
    _setText(_address, draft.address);
  }

  static void _setText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_provider, (_, next) {
      final value = next.value;
      if (value != null) _syncControllers(value.draft);
    });
    final value = ref.watch(_provider);
    // 첫 빌드에서는 listen이 호출되지 않으므로 처음 도착한 값으로 채운다.
    final loaded = value.value;
    if (loaded != null &&
        _name.text.isEmpty &&
        _message.text.isEmpty &&
        _address.text.isEmpty) {
      _syncControllers(loaded.draft);
    }

    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: AsyncStateView<GeofenceFormState>(
        value: value,
        errorTitle: widget.id == null
            ? '알림 장소 정보를 준비하지 못했어요'
            : '수정할 알림 장소를 찾지 못했어요',
        onRetry: () => ref.invalidate(_provider),
        builder: _form,
      ),
    );
  }

  Widget _form(GeofenceFormState state) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final viewModel = ref.read(_provider.notifier);
    final draft = state.draft;
    final gap = SizedBox(height: metrics.resolve(ImHereSpace.sm));
    final sectionGap = SizedBox(height: metrics.resolve(ImHereSpace.lg));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.navToTitle),
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.xl),
            ),
            children: [
              Text(
                widget.id == null ? '새 알림 장소' : '알림 장소 수정',
                style: textTheme.titleLarge,
              ),
              sectionGap,
              const ImHereListHeader(title: '어디에서 알릴까요?'),
              PlaceSearchBox(
                service: widget.mapSearchService,
                onSelected: viewModel.selectPlace,
              ),
              gap,
              GeofenceMapPicker(
                latitude: draft.latitude,
                longitude: draft.longitude,
                radiusMeters: draft.radius.meters,
                onPicked: viewModel.selectLocation,
              ),
              gap,
              ImHereTextField(
                label: '선택한 주소',
                controller: _address,
                enabled: false,
                errorText: state.errors[GeofenceField.address],
              ),
              gap,
              Text('알림 거리', style: textTheme.titleSmall),
              gap,
              ImHereSegmentedControl(
                labels: [
                  for (final radius in GeofenceRadius.values) radius.label,
                ],
                index: GeofenceRadius.values.indexOf(draft.radius),
                onChanged: (index) =>
                    viewModel.setRadius(GeofenceRadius.values[index]),
              ),
              sectionGap,
              const ImHereListHeader(title: '어떤 알림을 보낼까요?'),
              ImHereTextField(
                label: '장소 이름',
                controller: _name,
                errorText: state.errors[GeofenceField.name],
                helper: draft.hasDeviceRecipients
                    ? '장소 이름도 문자 본문 길이에 포함돼요'
                    : null,
                onChanged: (value) =>
                    _applyEdit(viewModel.setName(value), draft.name, _name),
              ),
              gap,
              ImHereTextField(
                label: '알림 메시지',
                controller: _message,
                errorText: state.errors[GeofenceField.message],
                helper: draft.hasDeviceRecipients
                    ? '{location}은 장소 이름으로 바뀌어요\n'
                          '문자 본문 ${draft.smsBody.length}/$smsBodyMaxLength자 (머리말 포함)'
                    : '{location}은 장소 이름으로 바뀌어요',
                onChanged: (value) => _applyEdit(
                  viewModel.setMessage(value),
                  draft.message,
                  _message,
                ),
              ),
              sectionGap,
              const ImHereListHeader(title: '언제 알릴까요?'),
              for (final eventType in const [
                EventType.arrival,
                EventType.departure,
              ])
                ImHereRadio<EventType>(
                  label: eventType.displayName,
                  value: eventType,
                  groupValue: draft.eventType,
                  onChanged: viewModel.setEventType,
                ),
              sectionGap,
              const ImHereListHeader(title: '얼마나 자주 알릴까요?'),
              Text(
                draft.repeat == GeofenceRepeat.none
                    ? '처음 감지했을 때 한 번만 알려요'
                    : '이 장소를 다시 지날 때마다 선택한 날에 알려요',
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              gap,
              for (final repeat in GeofenceRepeat.values)
                ImHereRadio<GeofenceRepeat>(
                  label: repeat.label,
                  value: repeat,
                  groupValue: draft.repeat,
                  onChanged: viewModel.setRepeat,
                ),
              if (draft.repeat == GeofenceRepeat.custom) ...[
                gap,
                Wrap(
                  spacing: metrics.resolve(ImHereSpace.xs),
                  runSpacing: metrics.resolve(ImHereSpace.xxs),
                  children: [
                    for (var weekday = 1; weekday <= 7; weekday++)
                      ImHereChip(
                        label: const [
                          '월',
                          '화',
                          '수',
                          '목',
                          '금',
                          '토',
                          '일',
                        ][weekday - 1],
                        selected:
                            draft.customDaysBitmask & (1 << (weekday - 1)) != 0,
                        onChanged: (_) => viewModel.toggleRepeatDay(weekday),
                      ),
                  ],
                ),
                if (state.errors[GeofenceField.repeatDays] case final message?)
                  Padding(
                    padding: EdgeInsets.only(
                      top: metrics.resolve(ImHereSpace.xs),
                    ),
                    child: Text(
                      message,
                      style: textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                  ),
              ],
              sectionGap,
              ImHereListHeader(title: '받는 사람 ${draft.recipientCount}명'),
              Text(
                'ImHere 친구와 기기 연락처를 함께 고를 수 있어요',
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              gap,
              for (final option in state.recipients)
                ImHereCheckbox(
                  label: option.label,
                  prefix: ImHereBadge(
                    label: option.source.label,
                    tone: ImHereBadgeTone.neutral,
                    size: ImHereBadgeSize.medium,
                  ),
                  value: option.source == RecipientSource.device
                      ? draft.deviceContactIds.contains(option.key)
                      : draft.serverRecipientKeys.contains(option.key),
                  onChanged: (_) => viewModel.toggleRecipient(option),
                ),
              if (state.recipients.isEmpty)
                const ImHereStatePanel(
                  glyph: ImHereGlyph.friends,
                  title: '고를 수 있는 사람이 없어요',
                  description: '친구를 추가하거나 연락처를 골라 주세요',
                ),
              if (state.errors[GeofenceField.recipients] case final message?)
                Padding(
                  padding: EdgeInsets.only(
                    top: metrics.resolve(ImHereSpace.xs),
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      style: textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                  ),
                ),
              sectionGap,
              ImHereSwitch(
                label: '저장 후 바로 활성화',
                value: draft.active,
                onChanged: viewModel.setActive,
              ),
              if (state.submitError case final message?)
                Padding(
                  padding: EdgeInsets.only(
                    top: metrics.resolve(ImHereSpace.sm),
                  ),
                  child: ImHereCallout(
                    tone: ImHereCalloutTone.error,
                    text: message,
                  ),
                ),
            ],
          ),
        ),
        ImHereBottomAction(
          label: widget.id == null ? '알림 장소 만들기' : '변경사항 저장',
          loading: state.saving,
          onPressed: state.saving ? null : _submit,
        ),
      ],
    );
  }

  /// 받아들여지지 않은 입력이면 입력칸을 이전 값으로 되돌린다.
  void _applyEdit(bool accepted, String previous, TextEditingController field) {
    if (!accepted) _setText(field, previous);
  }

  Future<void> _submit() async {
    final saved = await ref.read(_provider.notifier).submit();
    if (!saved || !mounted) return;
    showImHereSnackbar(context, '알림 장소를 저장했어요');
    context.go('/geofence');
  }
}
