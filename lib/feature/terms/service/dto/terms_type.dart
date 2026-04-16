import 'package:json_annotation/json_annotation.dart';

enum TermsType {
  @JsonValue('SERVICE')
  service, // 서비스 이용 약관

  @JsonValue('PRIVACY')
  privacy, // 개인정보 처리 방침

  @JsonValue('LOCATION')
  location, // 위치정보 이용약관

  @JsonValue('THIRD_PARTY_SHARING')
  thirdPartySharing, // 개인정보 및 위치정보 제3자 제공 동의

  @JsonValue('MARKETING')
  marketing, // 마케팅 정보 수신 동의
}
