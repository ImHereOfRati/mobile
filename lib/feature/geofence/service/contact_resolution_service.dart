import 'dart:convert';
import 'dart:developer';

import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/repository/contact_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository.dart';
import 'package:injectable/injectable.dart';

/// Resolve and fetch friend information for geofence recipients
@injectable
class ContactResolutionService {
  final ContactLocalRepository _contactRepository;
  final GeofenceServerRecipientLocalRepository _serverRecipientRepository;

  ContactResolutionService(
    this._contactRepository,
    this._serverRecipientRepository,
  );

  /// Get local contact entities for a geofence's contact IDs
  /// Returns empty list if no contacts found
  Future<List<ContactEntity>> resolveContacts(GeofenceEntity geofence) async {
    try {
      final List<dynamic> contactIdsJson = jsonDecode(geofence.contactIds);
      final List<int> contactIds = contactIdsJson
          .map((id) => id as int)
          .toList();

      if (contactIds.isEmpty) {
        log('No local contacts specified for geofence: ${geofence.name}');
        return [];
      }

      final allContacts = await _contactRepository.findAll();
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

  /// Get server recipient entities persisted for the geofence
  Future<List<GeofenceServerRecipientEntity>> resolveServerRecipients(
    GeofenceEntity geofence,
  ) async {
    if (geofence.id == null) return [];
    try {
      return await _serverRecipientRepository.findByGeofenceId(geofence.id!);
    } catch (e) {
      log('Error resolving server recipients: $e');
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

  /// Extract emails from server recipients
  List<String> extractServerEmails(
    List<GeofenceServerRecipientEntity> serverRecipients,
  ) {
    return serverRecipients
        .map((r) => r.friendEmail.trim())
        .where((email) => email.isNotEmpty)
        .toList();
  }
}
