import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'main_screen.dart';
import 'library_map_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Book> _favoriteBooks = [];
  bool _isLoading = true;
  final String _userId = 'guest'; // In real app, get from auth

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final books = await DatabaseHelper.instance.getFavoriteBooks(_userId);
    setState(() {
      _favoriteBooks = books;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteBooks.isEmpty
              ? const Center(
                  child: Text(
                    'Нет избранных книг',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _favoriteBooks.length,
                    itemBuilder: (context, index) {
                      final book = _favoriteBooks[index];
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
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(bookId: book.id!),
                              ),
                            );
                            _loadFavorites(); // Reload in case favorite was removed
                          },
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LibraryMapScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

