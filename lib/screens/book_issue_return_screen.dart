import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/loan.dart';

class BookIssueReturnScreen extends StatefulWidget {
  const BookIssueReturnScreen({super.key});

  @override
  State<BookIssueReturnScreen> createState() => _BookIssueReturnScreenState();
}

class _BookIssueReturnScreenState extends State<BookIssueReturnScreen> {
  List<Book> _books = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final books = await DatabaseHelper.instance.getAllBooks();
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  Future<void> _markIssue(Book book) async {
    if (book.availableCopies == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных экземпляров')),
      );
      return;
    }

    // Показываем диалог для ввода данных заёмщика
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _IssueBookDialog(book: book),
    );

    if (result != null && mounted) {
      final borrowerName = result['borrowerName'] as String;
      final quantity = result['quantity'] as int;

      if (borrowerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите имя заёмщика')),
        );
        return;
      }

      if (quantity <= 0 || quantity > book.availableCopies) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Количество должно быть от 1 до ${book.availableCopies}')),
        );
        return;
      }

      // Создаем запись о выдаче
      final loan = Loan(
        borrowerName: borrowerName,
        bookId: book.id!,
        quantity: quantity,
        issueDate: DateTime.now(),
      );

      await DatabaseHelper.instance.recordLoan(loan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Выдано $quantity экз. книги "${book.title}" заёмщику "$borrowerName"')),
        );
        _loadBooks();
      }
    }
  }

  Future<void> _markReturn(Book book) async {
    if (book.onHandCopies == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет книг на руках')),
      );
      return;
    }

    // Получаем активные займы для этой книги
    final activeLoans = await DatabaseHelper.instance.getLoansByBook(book.id!);
    final notReturnedLoans = activeLoans.where((loan) => !loan.isReturned).toList();

    if (notReturnedLoans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет активных займов для этой книги')),
      );
      return;
    }

    // Показываем диалог для выбора займа и количества возврата
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReturnBookDialog(book: book, loans: notReturnedLoans),
    );

    if (result != null && mounted) {
      final loanId = result['loanId'] as int;
      final quantity = result['quantity'] as int?;

      await DatabaseHelper.instance.returnLoan(loanId, quantity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Книга возвращена')),
        );
        _loadBooks();
      }
    }
  }

  void _filterBooks(String query) {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _searchController.text.isEmpty
        ? _books
        : _books.where((book) {
            final query = _searchController.text.toLowerCase();
            return book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выдача / Возврат книг'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск книг',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterBooks,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                    ? const Center(child: Text('Книги не найдены'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.book, size: 40),
                              title: Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book.author),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text('В наличии: ${book.availableCopies}'),
                                        backgroundColor: Colors.green.shade100,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text('На руках: ${book.onHandCopies}'),
                                        backgroundColor: Colors.orange.shade100,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward, color: Colors.green),
                                    onPressed: book.availableCopies > 0
                                        ? () => _markIssue(book)
                                        : null,
                                    tooltip: 'Выдать',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward, color: Colors.orange),
                                    onPressed: book.onHandCopies > 0
                                        ? () => _markReturn(book)
                                        : null,
                                    tooltip: 'Вернуть',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Диалог для выдачи книги
class _IssueBookDialog extends StatefulWidget {
  final Book book;

  const _IssueBookDialog({required this.book});

  @override
  State<_IssueBookDialog> createState() => _IssueBookDialogState();
}

class _IssueBookDialogState extends State<_IssueBookDialog> {
  final _borrowerController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _borrowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Выдача книги: ${widget.book.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _borrowerController,
            decoration: const InputDecoration(
              labelText: 'Имя заёмщика',
              hintText: 'Введите имя того, кто берет книгу',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Количество: '),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Text(
                '$_quantity',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _quantity < widget.book.availableCopies
                    ? () => setState(() => _quantity++)
                    : null,
              ),
              const Spacer(),
              Text(
                'Доступно: ${widget.book.availableCopies}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'borrowerName': _borrowerController.text.trim(),
              'quantity': _quantity,
            });
          },
          child: const Text('Выдать'),
        ),
      ],
    );
  }
}

// Диалог для возврата книги
class _ReturnBookDialog extends StatefulWidget {
  final Book book;
  final List<Loan> loans;

  const _ReturnBookDialog({required this.book, required this.loans});

  @override
  State<_ReturnBookDialog> createState() => _ReturnBookDialogState();
}

class _ReturnBookDialogState extends State<_ReturnBookDialog> {
  Loan? _selectedLoan;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Возврат книги: ${widget.book.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите займ для возврата:'),
          const SizedBox(height: 8),
          ...widget.loans.map((loan) {
            return RadioListTile<Loan>(
              title: Text(loan.borrowerName),
              subtitle: Text('Количество: ${loan.quantity}, Дата: ${_formatDate(loan.issueDate)}'),
              value: loan,
              groupValue: _selectedLoan,
              onChanged: (value) {
                setState(() {
                  _selectedLoan = value;
                  _quantity = value!.quantity;
                });
              },
            );
          }),
          if (_selectedLoan != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Количество для возврата: '),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _quantity < _selectedLoan!.quantity
                      ? () => setState(() => _quantity++)
                      : null,
                ),
                const Spacer(),
                Text(
                  'Из займа: ${_selectedLoan!.quantity}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _selectedLoan != null
              ? () {
                  Navigator.pop(context, {
                    'loanId': _selectedLoan!.id!,
                    'quantity': _quantity,
                  });
                }
              : null,
          child: const Text('Вернуть'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

