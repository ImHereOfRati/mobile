import 'dart:convert';
import 'dart:developer';

import 'package:iamhere/contact/repository/contact_entity.dart';
import 'package:iamhere/contact/repository/contact_local_repository.dart';
import 'package:iamhere/geofence/repository/geofence_entity.dart';
import 'package:injectable/injectable.dart';

/// Resolve and fetch contact information for geofence recipients
@injectable
class ContactResolutionService {
  final ContactLocalRepository _contactRepository;

  ContactResolutionService(this._contactRepository);

  /// Get contact entities for a geofence's contact IDs
  /// Returns empty list if no contacts found
  Future<List<ContactEntity>> resolveContacts(GeofenceEntity geofence) async {
    try {
      // Parse contact IDs from JSON string
      final List<dynamic> contactIdsJson = jsonDecode(geofence.contactIds);
      final List<int> contactIds = contactIdsJson.map((id) => id as int).toList();

      if (contactIds.isEmpty) {
        log('No contacts specified for geofence: ${geofence.name}');
        return [];
      }

      // Fetch all contacts
      final allContacts = await _contactRepository.findAll();

      // Filter contacts matching the IDs
      final recipients = allContacts
          .where((contact) => contactIds.contains(contact.id))
          .toList();

      if (recipients.isEmpty) {
        log('No matching contacts found for geofence: ${geofence.name}');
      }

      return recipients;
    } catch (e) {
      log('Error resolving contacts: $e');
      return [];
    }
  }

  /// Extract and format phone numbers from contacts
  List<String> extractPhoneNumbers(List<ContactEntity> contacts) {
    return contacts
        .map((contact) => contact.number.replaceAll(RegExp(r'[^\d]'), ''))
        .where((number) => number.isNotEmpty)
        .toList();
  }
}
