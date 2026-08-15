class ContactEntity {
  final int? id;
  final String name;
  final String number;
  final bool hidden;

  ContactEntity({
    this.id,
    required this.name,
    required this.number,
    this.hidden = false,
  });

  ContactEntity copyWith({
    int? id,
    String? name,
    String? number,
    bool? hidden,
  }) {
    return ContactEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      hidden: hidden ?? this.hidden,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'number': number, 'hidden': hidden ? 1 : 0};
  }

  factory ContactEntity.fromMap(Map<String, dynamic> map) {
    return ContactEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      number: map['number'] as String,
      hidden: (map['hidden'] as int? ?? 0) == 1,
    );
  }
}
