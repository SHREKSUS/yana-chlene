class Shelf {
  final int? id;
  final int buildingId;
  final String letter; // A, B, C, etc.

  Shelf({
    this.id,
    required this.buildingId,
    required this.letter,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'building_id': buildingId,
      'letter': letter,
    };
  }

  factory Shelf.fromMap(Map<String, dynamic> map) {
    return Shelf(
      id: map['id'] as int?,
      buildingId: map['building_id'] as int,
      letter: map['letter'] as String,
    );
  }
}

