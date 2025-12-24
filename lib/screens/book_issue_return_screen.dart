import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';

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

    await DatabaseHelper.instance.markBookIssue(book.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Книга выдана')),
      );
      _loadBooks();
    }
  }

  Future<void> _markReturn(Book book) async {
    if (book.onHandCopies == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет книг на руках')),
      );
      return;
    }

    await DatabaseHelper.instance.markBookReturn(book.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Книга возвращена')),
      );
      _loadBooks();
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

