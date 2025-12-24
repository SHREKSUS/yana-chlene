class Favorite {
  final int? id;
  final int bookId;
  final String userId; // username or identifier

  Favorite({
    this.id,
    required this.bookId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      bookId: map['book_id'] as int,
      userId: map['user_id'] as String,
    );
  }
}

