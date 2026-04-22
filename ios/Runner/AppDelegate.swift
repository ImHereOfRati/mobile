import Flutter
import UIKit
import ContactsUI
import Contacts
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate, CNContactPickerDelegate {

  private var resultCallback: FlutterResult?
  private let methodChannelName = "com.iamhere.app/contacts"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // native_geofence 백그라운드 FlutterEngine 에서 플러그인을 재등록하기 위한 콜백.
    // 앱 종료 상태에서 지오펜스 진입 시 이 콜백으로 플러그인들이 주입되어야 Dio/SQLite/Firebase 등이 동작.
    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let contactChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: controller.binaryMessenger)

      contactChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else { return }

        if call.method == "selectContact" {
          self.resultCallback = result // 결과 콜백 저장
          self.showContactPicker(controller: controller)
        } else if call.method == "importContact" {
          // 전체 연락처 로드 (MethodChannel만 등록하고 Swift 구현은 생략 가능)
          result(FlutterMethodNotImplemented)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 5. 연락처 선택기 실행 함수
  private func showContactPicker(controller: FlutterViewController) {
    let picker = CNContactPickerViewController()
    picker.delegate = self

    // 사용자에게 전화번호만 표시하도록 설정 (원하는 속성 키 설정)
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey]

    controller.present(picker, animated: true, completion: nil)
  }

  // 6. 델리게이트 메서드 구현: 연락처 하나를 선택했을 때
  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)

    // 첫 번째 전화번호를 가져와서 숫자 외 문자 제거
    let number = contact.phoneNumbers.first?.value.stringValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

    let contactMap: [String: Any?] = [
      "name": name,
      "number": number
    ]

    resultCallback?(contactMap)
    resultCallback = nil
  }

  // 7. 델리게이트 메서드 구현: 선택을 취소했을 때
  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    // 취소 시 null 전달
    resultCallback?(nil)
    resultCallback = nil
  }
}
