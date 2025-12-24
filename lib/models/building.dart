class Building {
  final int? id;
  final String name;
  final String code; // DA or TB

  Building({
    this.id,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  factory Building.fromMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
    );
  }
}

