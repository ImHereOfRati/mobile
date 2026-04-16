import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/geofence/utils/radius_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'geofence_view_model_provider.dart';

part 'geofence_enroll_view_model.g.dart';

/// 지오펜스 등록 폼 상태
class GeofenceEnrollFormState {
  final String name;
  final NLatLng? selectedLocation;
  final String radius;
  final List<Contact> selectedRecipients;
  final String message;
  final bool isActive;

  GeofenceEnrollFormState({
    this.name = '',
    this.selectedLocation,
    this.radius = '500',
    this.selectedRecipients = const [],
    this.message = '안녕하세요! {location}에 도착했습니다.',
    this.isActive = true,
  });

  /// 현재 선택된 반경에 대한 안내 메시지
  String get radiusInfoMessage {
    final radiusValue = int.tryParse(radius);
    if (radiusValue == null) return '';
    return RadiusHelper.getRadiusInfoMessage(radiusValue);
  }

  GeofenceEnrollFormState copyWith({
    String? name,
    NLatLng? selectedLocation,
    String? radius,
    List<Contact>? selectedRecipients,
    String? message,
    bool? isActive,
  }) {
    return GeofenceEnrollFormState(
      name: name ?? this.name,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      radius: radius ?? this.radius,
      selectedRecipients: selectedRecipients ?? this.selectedRecipients,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
    );
  }
}

@Riverpod(keepAlive: false)
class GeofenceEnrollViewModel extends _$GeofenceEnrollViewModel {
  @override
  GeofenceEnrollFormState build() {
    return GeofenceEnrollFormState();
  }

  /// 이름 업데이트
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// 위치 업데이트
  void updateLocation(NLatLng? location) {
    state = state.copyWith(selectedLocation: location);
  }

  /// 반경 업데이트
  void updateRadius(String radius) {
    state = state.copyWith(radius: radius);
  }

  /// 수신자 업데이트
  void updateRecipients(List<Contact> recipients) {
    state = state.copyWith(selectedRecipients: recipients);
  }

  /// 메시지 업데이트
  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  /// 활성화 상태 업데이트
  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive);
  }

  /// 폼 초기화
  void resetForm() {
    state = GeofenceEnrollFormState();
  }

  /// 지오펜스 저장
  Future<void> saveGeofence() async {
    // 유효성 검사
    final validationResult = GeofenceFormValidator.validate(
      name: state.name,
      selectedLocation: state.selectedLocation,
      radiusText: state.radius,
      selectedRecipients: state.selectedRecipients,
      message: state.message,
    );

    if (!validationResult.isValid) {
      throw Exception(validationResult.errorMessage ?? '입력값을 확인해주세요');
    }

    // 연락처 ID 리스트 추출
    final contactIds = state.selectedRecipients
        .where((contact) => contact.id != null)
        .map((contact) => contact.id!)
        .toList();

    final vmInterface = ref.read(geofenceViewModelInterfaceProvider);
    final radius = double.parse(state.radius.trim());

    final saved = await vmInterface.saveGeofence(
      name: state.name.trim(),
      lat: state.selectedLocation!.latitude,
      lng: state.selectedLocation!.longitude,
      radius: radius,
      message: state.message.trim(),
      contactIds: contactIds,
    );

    // 활성화 상태가 true면 토글 적용 (기본 저장값은 false)
    if (state.isActive && saved.id != null) {
      await vmInterface.toggleGeofenceActive(saved.id!, true);
    }
  }
}

/// 지오펜스 등록 폼 유효성 검사 결과
class GeofenceFormValidationResult {
  final bool isValid;
  final String? errorMessage;

  GeofenceFormValidationResult({required this.isValid, this.errorMessage});
}

/// 지오펜스 등록 폼 유효성 검사
class GeofenceFormValidator {
  static GeofenceFormValidationResult validate({
    required String name,
    required Object? selectedLocation, // NLatLng? 또는 null
    required String radiusText,
    required List<Contact> selectedRecipients,
    required String message,
  }) {
    if (name.trim().isEmpty) {
      return GeofenceFormValidationResult(
        isValid: false,
        errorMessage: '지오펜스 이름을 입력해주세요',
      );
    }

    if (selectedLocation == null) {
      return GeofenceFormValidationResult(
        isValid: false,
        errorMessage: '위치를 선택해주세요',
      );
    }

    if (radiusText.trim().isEmpty) {
      return GeofenceFormValidationResult(
        isValid: false,
        errorMessage: '반경을 입력해주세요',
      );
    }

    final radius = double.tryParse(radiusText.trim());
    if (radius == null || radius <= 0) {
      return GeofenceFormValidationResult(
        isValid: false,
        errorMessage: '올바른 반경 값을 입력해주세요',
      );
    }

    if (selectedRecipients.isEmpty) {
      return GeofenceFormValidationResult(
        isValid: false,
        errorMessage: '최소 1명 이상의 수신자를 선택해주세요',
      );
    }

    if (message.trim().isEmpty) {
      return GeofenceFormValidationResult(
        isValid: false,
        errorMessage: '알림 메시지를 입력해주세요',
      );
    }

    return GeofenceFormValidationResult(isValid: true);
  }
}
