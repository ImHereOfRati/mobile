class GeofenceServerRecipientEntity {
  final int? id;
  final int geofenceId;
  final String friendRelationshipId;
  final String friendEmail;
  final String friendAlias;

  GeofenceServerRecipientEntity({
    this.id,
    required this.geofenceId,
    required this.friendRelationshipId,
    required this.friendEmail,
    this.friendAlias = '',
  });

  GeofenceServerRecipientEntity copyWith({
    int? id,
    int? geofenceId,
    String? friendRelationshipId,
    String? friendEmail,
    String? friendAlias,
  }) {
    return GeofenceServerRecipientEntity(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      friendRelationshipId: friendRelationshipId ?? this.friendRelationshipId,
      friendEmail: friendEmail ?? this.friendEmail,
      friendAlias: friendAlias ?? this.friendAlias,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'geofence_id': geofenceId,
      'friend_relationship_id': friendRelationshipId,
      'friend_email': friendEmail,
      'friend_alias': friendAlias,
    };
  }

  factory GeofenceServerRecipientEntity.fromMap(Map<String, dynamic> map) {
    return GeofenceServerRecipientEntity(
      id: map['id'] as int?,
      geofenceId: map['geofence_id'] as int,
      friendRelationshipId: map['friend_relationship_id'] as String,
      friendEmail: map['friend_email'] as String,
      friendAlias: map['friend_alias'] as String? ?? '',
    );
  }
}
