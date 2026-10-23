import 'dart:convert';
import 'dart:developer';

import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/repository/contact_local_repository.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_ports.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository.dart';
import 'package:injectable/injectable.dart';

/// Resolve and fetch friend information for geofence recipients
@injectable
class ContactResolutionService implements GeofenceRecipientResolver {
  final ContactLocalRepository _contactRepository;
  final GeofenceServerRecipientLocalRepository _serverRecipientRepository;

  ContactResolutionService(
    this._contactRepository,
    this._serverRecipientRepository,
  );

  /// Get local contact entities for a geofence's contact IDs
  /// Returns empty list if no contacts found
  @override
  Future<List<ContactEntity>> resolveContacts(GeofenceEntity geofence) async {
    try {
      final List<dynamic> contactIdsJson = jsonDecode(geofence.contactIds);
      final contactIds = contactIdsJson
          .map((id) => id is int ? id : int.tryParse(id.toString()))
          .whereType<int>()
          .toList();

      if (contactIds.isEmpty) {
        log('No local contacts specified for geofence: ${geofence.name}');
        return [];
      }

      final allContacts = (await _contactRepository.findAll())
          .where((contact) => !contact.hidden)
          .toList();
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
  @override
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
  @override
  List<String> extractPhoneNumbers(List<ContactEntity> contacts) {
    return contacts
        .map((contact) => contact.number.replaceAll(RegExp(r'[^\d]'), ''))
        .where((number) => number.isNotEmpty)
        .toList();
  }

  /// Extract server user UUIDs required by NotificationRequest.targetIds.
  @override
  List<String> extractServerUserIds(
    List<GeofenceServerRecipientEntity> serverRecipients,
  ) {
    return serverRecipients
        .map((r) => r.friendUserId.trim())
        .where((userId) => userId.isNotEmpty)
        .toList();
  }
}
