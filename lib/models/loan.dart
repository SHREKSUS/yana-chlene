class Loan {
  final int? id;
  final String borrowerName; // Имя того, кто взял книгу
  final int bookId; // ID книги
  final int quantity; // Количество экземпляров
  final DateTime issueDate; // Дата выдачи
  final DateTime? returnDate; // Дата возврата (null если еще не возвращена)
  final int? librarianId; // ID библиотекаря, который выдал книгу

  Loan({
    this.id,
    required this.borrowerName,
    required this.bookId,
    required this.quantity,
    required this.issueDate,
    this.returnDate,
    this.librarianId,
  });

  bool get isReturned => returnDate != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrower_name': borrowerName,
      'book_id': bookId,
      'quantity': quantity,
      'issue_date': issueDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'librarian_id': librarianId,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      borrowerName: map['borrower_name'] as String,
      bookId: map['book_id'] as int,
      quantity: map['quantity'] as int,
      issueDate: DateTime.parse(map['issue_date'] as String),
      returnDate: map['return_date'] != null
          ? DateTime.parse(map['return_date'] as String)
          : null,
      librarianId: map['librarian_id'] as int?,
    );
  }

  Loan copyWith({
    int? id,
    String? borrowerName,
    int? bookId,
    int? quantity,
    DateTime? issueDate,
    DateTime? returnDate,
    int? librarianId,
  }) {
    return Loan(
      id: id ?? this.id,
      borrowerName: borrowerName ?? this.borrowerName,
      bookId: bookId ?? this.bookId,
      quantity: quantity ?? this.quantity,
      issueDate: issueDate ?? this.issueDate,
      returnDate: returnDate ?? this.returnDate,
      librarianId: librarianId ?? this.librarianId,
    );
  }
}

