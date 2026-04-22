import 'geofence_enroll_form_state.dart';
import '../dto/geofence_form_validation_result.dart';
export '../dto/geofence_form_validation_result.dart';

class GeofenceFormValidator {
  static GeofenceFormValidationResult validate(GeofenceEnrollFormState state) {
    if (state.name.trim().isEmpty) {
      return GeofenceFormValidationResult(isValid: false, errorMessage: '지오펜스 이름을 입력해주세요');
    }
    if (state.selectedLocation == null) {
      return GeofenceFormValidationResult(isValid: false, errorMessage: '위치를 선택해주세요');
    }
    final radius = double.tryParse(state.radius.trim());
    if (radius == null || radius <= 0) {
      return GeofenceFormValidationResult(isValid: false, errorMessage: '올바른 반경 값을 입력해주세요');
    }
    if (state.selectedRecipients.isEmpty) {
      return GeofenceFormValidationResult(isValid: false, errorMessage: '최소 1명 이상의 수신자를 선택해주세요');
    }
    if (state.message.trim().isEmpty) {
      return GeofenceFormValidationResult(isValid: false, errorMessage: '알림 메시지를 입력해주세요');
    }
    return GeofenceFormValidationResult(isValid: true);
  }
}
