class ContactEntity {
  final int? id;
  final String name;
  final String number;

  ContactEntity({this.id, required this.name, required this.number});

  ContactEntity copyWith({int? id, String? name, String? number}) {
    return ContactEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'number': number};
  }

  factory ContactEntity.fromMap(Map<String, dynamic> map) {
    return ContactEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      number: map['number'] as String,
    );
  }
}
