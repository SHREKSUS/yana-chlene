class Rack {
  final int? id;
  final int shelfId;
  final int number;

  Rack({
    this.id,
    required this.shelfId,
    required this.number,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shelf_id': shelfId,
      'number': number,
    };
  }

  factory Rack.fromMap(Map<String, dynamic> map) {
    return Rack(
      id: map['id'] as int?,
      shelfId: map['shelf_id'] as int,
      number: map['number'] as int,
    );
  }
}

