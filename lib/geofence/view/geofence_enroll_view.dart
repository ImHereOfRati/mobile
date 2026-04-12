import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/contact/view_model/contact.dart';
import 'package:iamhere/geofence/view/widget/radius_button.dart';
import 'package:iamhere/geofence/view/widget/radius_info_callout.dart';
import 'package:iamhere/geofence/view_model/geofence_enroll_view_model.dart';
import 'package:iamhere/geofence/view_model/geofence_list_view_model.dart';
import 'package:iamhere/shared/component/view_component/widgets/primary_button.dart';
import 'package:iamhere/shared/component/view_component/widgets/section_title.dart';
import 'package:iamhere/shared/component/view_component/widgets/select_button.dart';
import 'package:iamhere/shared/component/view_component/widgets/text_input_field.dart';

import 'widget/map_select_view.dart';
import 'widget/recipient_select_view.dart';

class GeofenceEnrollView extends ConsumerStatefulWidget {
  const GeofenceEnrollView({super.key});

  @override
  ConsumerState<GeofenceEnrollView> createState() => _GeofenceEnrollViewState();
}

class _GeofenceEnrollViewState extends ConsumerState<GeofenceEnrollView> {
  // TextField 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ViewModel 상태와 TextField 동기화
    _nameController.addListener(_onNameChanged);
    _messageController.addListener(_onMessageChanged);
  }

  void _onNameChanged() {
    ref
        .read(geofenceEnrollViewModelProvider.notifier)
        .updateName(_nameController.text);
  }

  void _onMessageChanged() {
    ref
        .read(geofenceEnrollViewModelProvider.notifier)
        .updateMessage(_messageController.text);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _messageController.removeListener(_onMessageChanged);
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 반경 선택 핸들러
  void _onRadiusSelected(int radius) {
    ref
        .read(geofenceEnrollViewModelProvider.notifier)
        .updateRadius(radius.toString());
  }

  // 지도 선택 화면으로 이동
  Future<void> _openMapSelectScreen() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    debugPrint('=== 지도 선택 화면으로 이동 ===');
    debugPrint('현재 선택된 위치: ${formState.selectedLocation}');

    // GoRouter 대신 직접 Navigator 사용
    final result = await Navigator.of(context).push<NLatLng>(
      MaterialPageRoute(
        builder: (context) =>
            MapSelectView(initialLocation: formState.selectedLocation),
      ),
    );

    debugPrint('=== 지도 화면에서 돌아옴 ===');
    debugPrint('반환된 result: $result');
    debugPrint('result 타입: ${result.runtimeType}');

    if (result != null) {
      ref.read(geofenceEnrollViewModelProvider.notifier).updateLocation(result);
      debugPrint(
        '등록 화면: 선택된 위치 업데이트 - ${result.latitude}, ${result.longitude}',
      );
    } else {
      debugPrint('등록 화면에서 결과를 받지 못함 (result == null)');
    }
  }

  // 수신자 선택 화면으로 이동
  Future<void> _openRecipientSelectScreen() async {
    final formState = ref.read(geofenceEnrollViewModelProvider);
    final result = await Navigator.of(context).push<List<Contact>>(
      MaterialPageRoute(
        builder: (context) => RecipientSelectView(
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
      debugPrint('선택된 수신자: ${result.map((r) => r.name).join(", ")}');
    }
  }

  // 지오펜스 저장
  Future<void> _saveGeofence() async {
    try {
      final enrollViewModel = ref.read(
        geofenceEnrollViewModelProvider.notifier,
      );
      await enrollViewModel.saveGeofence();

      // 지오펜스 목록 새로고침
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
        ).showSnackBar(SnackBar(content: Text('지오펜스 등록 실패: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(geofenceEnrollViewModelProvider);

    return Scaffold(
      body: SingleChildScrollView(
        // 수평/수직 패딩 적용
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 지오펜스 이름 입력
            const SectionTitle(title: '위치 알람 이름'),
            SizedBox(height: 8.h),
            TextInputField(
              controller: _nameController,
              hintText: '회사, 학교, 집 등',
              icon: Icons.label_outline,
            ),

            SizedBox(height: 16.h),
            // 2. 위치 설정
            const SectionTitle(title: '위치 설정'),
            SizedBox(height: 8.h),
            SelectButton(
              label: formState.selectedLocation == null
                  ? '지도에서 위치 선택'
                  : '위치: ${formState.selectedLocation!.latitude.toStringAsFixed(4)}, ${formState.selectedLocation!.longitude.toStringAsFixed(4)}',
              icon: Icons.map_outlined,
              onPressed: _openMapSelectScreen,
              isSelected: formState.selectedLocation != null,
              minHeight: 120.h,
            ),

            SizedBox(height: 16.h),
            const SectionTitle(title: '반경 설정'),
            SizedBox(height: 8.h),
            // 반경 선택 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RadiusButton(
                  radius: 250,
                  isSelected: formState.radius == '250',
                  onTap: () => _onRadiusSelected(250),
                ),
                RadiusButton(
                  radius: 500,
                  isSelected: formState.radius == '500',
                  onTap: () => _onRadiusSelected(500),
                ),
                RadiusButton(
                  radius: 1000,
                  isSelected: formState.radius == '1000',
                  onTap: () => _onRadiusSelected(1000),
                ),
              ],
            ),

            // 반경에 따른 안내 메시지
            if (formState.radiusInfoMessage.isNotEmpty) SizedBox(height: 12.h),
            if (formState.radiusInfoMessage.isNotEmpty)
              RadiusInfoCallout(message: formState.radiusInfoMessage),

            // 3. 알림 메시지 설정
            SizedBox(height: 16.h),
            const SectionTitle(title: '전송할 메시지'),
            TextInputField(
              controller: _messageController,
              hintText: '알림 메시지 예: 회사에 도착했습니다!',
              icon: Icons.message_outlined,
              maxLines: 3,
            ),

            SizedBox(height: 16.h),
            const SectionTitle(title: '누구에게 알려줄까요?'),
            SizedBox(height: 8.h),
            SelectButton(
              label: formState.selectedRecipients.isEmpty
                  ? '수신자 선택 (필수)'
                  : '수신자 ${formState.selectedRecipients.length}명 선택됨',
              icon: Icons.people_alt_outlined,
              onPressed: _openRecipientSelectScreen,
              isSelected: formState.selectedRecipients.isNotEmpty,
            ),

            SizedBox(height: 32.h),
            // 4. 저장 버튼
            PrimaryButton(text: '등록하기', onPressed: _saveGeofence),
          ],
        ),
      ),
    );
  }
}
