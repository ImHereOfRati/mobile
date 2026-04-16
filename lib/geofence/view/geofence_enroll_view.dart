import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/friend/view_model/contact.dart';
import 'package:iamhere/geofence/view/widget/radius_button.dart';
import 'package:iamhere/geofence/view/widget/radius_info_callout.dart';
import 'package:iamhere/geofence/view_model/geofence_enroll_view_model.dart';
import 'package:iamhere/geofence/view_model/geofence_list_view_model.dart';
import 'package:iamhere/user_permission/service/concrete/locate_permission_service.dart';

import 'widget/map_select_view.dart';
import 'widget/recipient_select_view.dart';

class GeofenceEnrollView extends ConsumerStatefulWidget {
  const GeofenceEnrollView({super.key});

  @override
  ConsumerState<GeofenceEnrollView> createState() => _GeofenceEnrollViewState();
}

class _GeofenceEnrollViewState extends ConsumerState<GeofenceEnrollView> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  // 지도
  NaverMapController? _mapController;
  NMarker? _currentMarker;
  late Future<NLatLng> _initialLocationFuture;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(geofenceEnrollViewModelProvider);
    _messageController.text = formState.message;
    _nameController.addListener(_onNameChanged);
    _messageController.addListener(_onMessageChanged);
    _initialLocationFuture = _fetchInitialLocation();
  }

  Future<NLatLng> _fetchInitialLocation() async {
    try {
      final pos = await LocatePermissionService().getCurrentUserLocation();
      return NLatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return const NLatLng(37.5665, 126.9780); // 서울 시청 fallback
    }
  }

  void _onNameChanged() => ref
      .read(geofenceEnrollViewModelProvider.notifier)
      .updateName(_nameController.text);

  void _onMessageChanged() => ref
      .read(geofenceEnrollViewModelProvider.notifier)
      .updateMessage(_messageController.text);

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _messageController.removeListener(_onMessageChanged);
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── 지도 탭 → 마커 갱신 ───────────────────────────────────────────────
  void _onMapTapped(NLatLng latlng) {
    if (_currentMarker != null) {
      _mapController?.deleteOverlay(_currentMarker!.info);
    }
    _currentMarker = NMarker(id: 'selected_pin', position: latlng);
    _mapController?.addOverlay(_currentMarker!);
    ref.read(geofenceEnrollViewModelProvider.notifier).updateLocation(latlng);
  }

  // ── 지도에서 위치 선택 화면 ───────────────────────────────────────────
  Future<void> _openMapSelect() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    final result = await Navigator.of(context).push<NLatLng>(
      MaterialPageRoute(
        builder: (_) =>
            MapSelectView(initialLocation: formState.selectedLocation),
      ),
    );
    if (result != null) {
      _onMapTapped(result);
      // 지도 카메라도 선택된 위치로 이동
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: result, zoom: 15),
      );
    }
  }

  // ── 수신자 선택 화면 ─────────────────────────────────────────────────
  Future<void> _openRecipientSelect() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    final result = await Navigator.of(context).push<List<Contact>>(
      MaterialPageRoute(
        builder: (_) => RecipientSelectView(
          initialSelectedIds: formState.selectedRecipients
              .where((r) => r.id != null)
              .map((r) => r.id!)
              .toList(),
        ),
      ),
    );
    if (result != null) {
      ref
          .read(geofenceEnrollViewModelProvider.notifier)
          .updateRecipients(result);
    }
  }

  // ── 지오펜스 저장 ────────────────────────────────────────────────────
  Future<void> _save() async {
    try {
      await ref.read(geofenceEnrollViewModelProvider.notifier).saveGeofence();
      ref.read(geofenceListViewModelProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('지오펜스가 등록되었습니다')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('등록 실패: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(geofenceEnrollViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── 인라인 지도 ────────────────────────────────────────────
          SizedBox(height: 260.h, child: _buildInlineMap(formState, cs)),

          // ── 폼 ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 반경 설정
                  _sectionLabel(context, '반경 설정'),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      RadiusButton(
                        radius: 250,
                        isSelected: formState.radius == '250',
                        onTap: () => ref
                            .read(geofenceEnrollViewModelProvider.notifier)
                            .updateRadius('250'),
                      ),
                      RadiusButton(
                        radius: 500,
                        isSelected: formState.radius == '500',
                        onTap: () => ref
                            .read(geofenceEnrollViewModelProvider.notifier)
                            .updateRadius('500'),
                      ),
                      RadiusButton(
                        radius: 1000,
                        isSelected: formState.radius == '1000',
                        onTap: () => ref
                            .read(geofenceEnrollViewModelProvider.notifier)
                            .updateRadius('1000'),
                      ),
                    ],
                  ),
                  if (formState.radiusInfoMessage.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    RadiusInfoCallout(message: formState.radiusInfoMessage),
                  ],

                  SizedBox(height: 20.h),
                  // 위치 알람 이름
                  _sectionLabel(context, '위치 알람 이름'),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    context,
                    cs,
                    controller: _nameController,
                    hint: '예) 우리집, 회사, 학교',
                    maxLines: 1,
                  ),

                  SizedBox(height: 20.h),
                  // 앱 알림 메시지
                  _sectionLabel(context, '도착 알림 메시지'),
                  SizedBox(height: 8.h),
                  _buildTextField(
                    context,
                    cs,
                    controller: _messageController,
                    hint: '안녕하세요! {location}에 도착했습니다.',
                    maxLines: 3,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '{location}은 위치 알람 이름으로 자동 변환돼요',
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 12.sp,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sms_outlined,
                          size: 16.r,
                          color: const Color(0xFFE65100),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '문자 메시지 발송 시에는 적용되지 않아요',
                            style: TextStyle(
                              fontFamily: 'BMHANNAAir',
                              fontSize: 12.sp,
                              color: const Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),
                  // 전송될 문자 형식
                  _buildSmsPreviewCard(context, cs, formState),

                  SizedBox(height: 20.h),
                  // 위치 알람 활성화
                  _buildActivateToggle(context, cs, formState),

                  SizedBox(height: 12.h),
                  // 꼭 확인하세요!
                  _buildCheckCard(context, cs),

                  SizedBox(height: 20.h),
                  // 어떤 친구에게 알려줄까요?
                  _buildRecipientSection(context, cs, formState),

                  SizedBox(height: 24.h),
                  // 등록하기
                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        '등록하기',
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 인라인 지도 ──────────────────────────────────────────────────────
  Widget _buildInlineMap(GeofenceEnrollFormState formState, ColorScheme cs) {
    return FutureBuilder<NLatLng>(
      future: _initialLocationFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: const Color(0xFFD6EAF8),
            child: Center(child: CircularProgressIndicator(color: cs.primary)),
          );
        }

        final initialTarget = snapshot.data!;
        return Stack(
          children: [
            NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: initialTarget,
                  zoom: 15,
                ),
                scrollGesturesEnable: true,
                zoomGesturesEnable: true,
                tiltGesturesEnable: false,
                consumeSymbolTapEvents: false,
              ),
              onMapReady: (controller) {
                _mapController = controller;
                // 기존 선택 위치가 있으면 마커 복원
                if (formState.selectedLocation != null) {
                  _onMapTapped(formState.selectedLocation!);
                }
              },
              onMapTapped: (_, latlng) => _onMapTapped(latlng),
            ),
            // 위치 미선택 시 안내 오버레이
            if (formState.selectedLocation == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.18),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 40.r,
                            color: cs.primary,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '지도에서 위치를 선택하세요',
                            style: TextStyle(
                              fontFamily: 'BMHANNAAir',
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // 선택 완료 시 좌표 뱃지
            if (formState.selectedLocation != null)
              Positioned(
                bottom: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14.r,
                        color: cs.onPrimary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '위치 선택됨',
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 12.sp,
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 지도에서 위치 선택하기 버튼
            Positioned(
              bottom: 12.h,
              right: 12.w,
              child: Material(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20.r),
                elevation: 3,
                child: InkWell(
                  onTap: _openMapSelect,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, size: 16.r, color: cs.primary),
                        SizedBox(width: 4.w),
                        Text(
                          '지도에서 위치 선택하기',
                          style: TextStyle(
                            fontFamily: 'BMHANNAAir',
                            fontSize: 12.sp,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── 섹션 레이블 ──────────────────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }

  // ── 텍스트 필드 ──────────────────────────────────────────────────────
  Widget _buildTextField(
    BuildContext context,
    ColorScheme cs, {
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 14.sp,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 14.sp,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  // ── 실제 문자 형식 카드 ──────────────────────────────────────────────
  Widget _buildSmsPreviewCard(
    BuildContext context,
    ColorScheme cs,
    GeofenceEnrollFormState formState,
  ) {
    final locationName = formState.name.isNotEmpty ? formState.name : '{위치 이름}';

    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sms_outlined,
                size: 16.r,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              SizedBox(width: 6.w),
              Text(
                '실제 문자 형식',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 13.sp,
                      color: cs.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: locationName,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: '에 안전하게 도착하였습니다.'),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '보낸 분 : 홍길동',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '시간: 오후 3시 30분',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Service by ImHere',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 11.sp,
                    color: cs.onSurface.withValues(alpha: 0.45),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '※ 문자 내용은 서버에서 자동 생성되며 변경할 수 없어요',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 11.sp,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── 위치 알람 활성화 토글 ────────────────────────────────────────────
  Widget _buildActivateToggle(
    BuildContext context,
    ColorScheme cs,
    GeofenceEnrollFormState formState,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '위치 알람 활성화',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          Switch(
            value: formState.isActive,
            onChanged: (v) => ref
                .read(geofenceEnrollViewModelProvider.notifier)
                .updateIsActive(v),
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }

  // ── 꼭 확인하세요! 카드 ──────────────────────────────────────────────
  Widget _buildCheckCard(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFE082)),
        // left border accent
      ),
      padding: EdgeInsets.all(14.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔑', style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '꼭 확인하세요!',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '위치 알람을 등록한 후에는 반드시 활성화를 해야 알림이 전송됩니다. 메인 화면에서 스위치를 켜주세요!',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 수신자 섹션 ──────────────────────────────────────────────────────
  Widget _buildRecipientSection(
    BuildContext context,
    ColorScheme cs,
    GeofenceEnrollFormState formState,
  ) {
    final recipients = formState.selectedRecipients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '어떤 친구에게 알려줄까요?',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: _openRecipientSelect,
              child: Text(
                '추가하기',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 80.h),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: recipients.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      '아직 선택된 친구가 없어요',
                      style: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 13.sp,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: _openRecipientSelect,
                      child: Text(
                        '추가하기',
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: recipients
                        .map((r) => _recipientChip(cs, r))
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _recipientChip(ColorScheme cs, Contact recipient) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14.r, color: cs.primary),
          SizedBox(width: 4.w),
          Text(
            recipient.name,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
