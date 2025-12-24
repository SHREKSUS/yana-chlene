import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'edit_book_screen.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
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

  Future<void> _deleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('Вы уверены, что хотите удалить "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteBook(book.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Книга удалена')),
        );
        _loadBooks();
      }
    }
  }

  void _filterBooks(String query) {
    setState(() {
      // Filtering will be done in build method
    });
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
                book.author.toLowerCase().contains(query) ||
                (book.subject?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление книгами'),
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
                                  Text(
                                    'В наличии: ${book.availableCopies}, На руках: ${book.onHandCopies}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('Просмотр'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Редактировать'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Удалить', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'view') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookDetailScreen(bookId: book.id!),
                                      ),
                                    );
                                  } else if (value == 'edit') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditBookScreen(bookId: book.id!),
                                      ),
                                    );
                                    // Обновляем список только если редактирование было успешным
                                    if (result == true) {
                                      _loadBooks();
                                    }
                                  } else if (value == 'delete') {
                                    _deleteBook(book);
                                  }
                                },
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

