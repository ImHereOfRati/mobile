import Contacts
import Flutter
import UIKit
import native_geofence

@main
@objc class AppDelegate: FlutterAppDelegate, CNContactPickerDelegate {
  private let contactStore = CNContactStore()
  private var pendingPickerResult: FlutterResult?

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
        guard call.method == "getDeviceContacts" || call.method == "pickDeviceContact" else {
          result(FlutterMethodNotImplemented)
          return
        }
        if call.method == "pickDeviceContact" {
          self?.pickContact(result: result)
        } else {
          self?.loadContacts(result: result)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func pickContact(result: @escaping FlutterResult) {
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
      DispatchQueue.main.async {
        self.pendingPickerResult = result
        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        self.window?.rootViewController?.present(picker, animated: true)
      }
    }
  }

  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    let numbers = contact.phoneNumbers.map {
      $0.value.stringValue.replacingOccurrences(
        of: "[^0-9+]",
        with: "",
        options: .regularExpression
      )
    }.filter { !$0.isEmpty }
    pendingPickerResult?([
      "id": contact.identifier,
      "displayName": CNContactFormatter.string(from: contact, style: .fullName) ?? "",
      "phoneNumbers": numbers,
    ])
    pendingPickerResult = nil
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    pendingPickerResult?(nil)
    pendingPickerResult = nil
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
