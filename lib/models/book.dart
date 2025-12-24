class Book {
  final int? id;
  final int rackId;
  final String title;
  final String author;
  final String? subject;
  final String? genre;
  final String? description;
  final int totalCopies;
  final int availableCopies;
  final int onHandCopies;
  final String? coverImagePath;

  Book({
    this.id,
    required this.rackId,
    required this.title,
    required this.author,
    this.subject,
    this.genre,
    this.description,
    required this.totalCopies,
    required this.availableCopies,
    required this.onHandCopies,
    this.coverImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rack_id': rackId,
      'title': title,
      'author': author,
      'subject': subject,
      'genre': genre,
      'description': description,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'on_hand_copies': onHandCopies,
      'cover_image_path': coverImagePath,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      rackId: map['rack_id'] as int,
      title: map['title'] as String,
      author: map['author'] as String,
      subject: map['subject'] as String?,
      genre: map['genre'] as String?,
      description: map['description'] as String?,
      totalCopies: map['total_copies'] as int,
      availableCopies: map['available_copies'] as int,
      onHandCopies: map['on_hand_copies'] as int,
      coverImagePath: map['cover_image_path'] as String?,
    );
  }

  Book copyWith({
    int? id,
    int? rackId,
    String? title,
    String? author,
    String? subject,
    String? genre,
    String? description,
    int? totalCopies,
    int? availableCopies,
    int? onHandCopies,
    String? coverImagePath,
  }) {
    return Book(
      id: id ?? this.id,
      rackId: rackId ?? this.rackId,
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      onHandCopies: onHandCopies ?? this.onHandCopies,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }
}

