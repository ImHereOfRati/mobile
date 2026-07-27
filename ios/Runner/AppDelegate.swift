import Contacts
import Flutter
import UIKit
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let contactStore = CNContactStore()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    NativeGeofencePlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.iamhere.app/contacts",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "getDeviceContacts" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.loadContacts(result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func loadContacts(result: @escaping FlutterResult) {
    contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
      guard granted, let self else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "CONTACTS_PERMISSION_DENIED",
              message: error?.localizedDescription ?? "연락처 권한이 필요합니다.",
              details: nil
            )
          )
        }
        return
      }

      do {
        let keys = [
          CNContactIdentifierKey as CNKeyDescriptor,
          CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
          CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        var contacts: [[String: Any]] = []
        try self.contactStore.enumerateContacts(with: request) { contact, _ in
          let numbers = contact.phoneNumbers.map {
            $0.value.stringValue.replacingOccurrences(
              of: "[^0-9+]",
              with: "",
              options: .regularExpression
            )
          }.filter { !$0.isEmpty }
          contacts.append([
            "id": contact.identifier,
            "displayName": CNContactFormatter.string(from: contact, style: .fullName) ?? "",
            "phoneNumbers": numbers,
          ])
        }
        DispatchQueue.main.async { result(contacts) }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "CONTACTS_READ_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }
}
