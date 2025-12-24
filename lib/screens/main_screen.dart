import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/database_helper.dart';
import '../models/book.dart';
import '../utils/responsive.dart';
import '../utils/image_helper.dart';
import 'book_detail_screen.dart';
import 'library_map_screen.dart';
import 'favorites_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _searchController = TextEditingController();
  List<Book> _searchResults = [];
  List<Book> _popularBooks = [];
  List<Book> _filteredBooks = [];
  List<Book> _allBooks = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _currentFilter = 'all'; // all, subject, author, genre, new
  String? _selectedSubject;
  String? _selectedAuthor;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await DatabaseHelper.instance.getAllBooks();
      final popular = await DatabaseHelper.instance.getPopularBooks();
      setState(() {
        _allBooks = books ?? [];
        _popularBooks = popular ?? [];
        _filteredBooks = books ?? [];
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _allBooks = [];
        _popularBooks = [];
        _filteredBooks = [];
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_allBooks.isEmpty) {
      setState(() {
        _filteredBooks = [];
      });
      return;
    }

    setState(() {
      switch (_currentFilter) {
        case 'all':
          _filteredBooks = List<Book>.from(_allBooks);
          break;
        case 'subject':
          if (_selectedSubject != null) {
            _filteredBooks = _allBooks.where((book) => book.subject == _selectedSubject).toList();
          } else {
            _filteredBooks = _allBooks.where((book) => book.subject != null && book.subject!.isNotEmpty).toList();
          }
          break;
        case 'author':
          if (_selectedAuthor != null) {
            _filteredBooks = _allBooks.where((book) => book.author == _selectedAuthor).toList();
          } else {
            _filteredBooks = List<Book>.from(_allBooks);
          }
          break;
        case 'genre':
          if (_selectedGenre != null) {
            _filteredBooks = _allBooks.where((book) => book.genre == _selectedGenre).toList();
          } else {
            _filteredBooks = _allBooks.where((book) => book.genre != null && book.genre!.isNotEmpty).toList();
          }
          break;
        case 'new':
          _filteredBooks = List<Book>.from(_popularBooks);
          break;
        default:
          _filteredBooks = List<Book>.from(_allBooks);
      }
    });
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    List<Book> results;
    if (query.length >= 4 && query.contains('-')) {
      // Try to search by code (e.g., DA-A15)
      results = await DatabaseHelper.instance.searchBooksByCode(query.toUpperCase());
    } else {
      results = await DatabaseHelper.instance.searchBooks(query);
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final isDesktop = Responsive.isDesktop(context);
    final maxWidth = Responsive.getMaxWidth(context);
    final padding = Responsive.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('БИБЛИОТЕКА'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              Padding(
                padding: padding,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск книги (название, автор, предмет или код DA-A15)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchBooks('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _searchBooks,
                ),
              ),
              if (!_isSearching && _searchController.text.isEmpty) ...[
                // Quick filters
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding.horizontal),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Все', 'all'),
                      _buildFilterChip('По предмету', 'subject'),
                      _buildFilterChip('По автору', 'author'),
                      _buildFilterChip('По жанру', 'genre'),
                      _buildFilterChip('Популярные', 'new'),
                    ],
                  ),
                ),
                // Show selected filter info
                if (_currentFilter == 'subject' && _selectedSubject != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding.horizontal, vertical: 8),
                    child: Row(
                      children: [
                        Chip(
                          label: Text('Предмет: $_selectedSubject'),
                          onDeleted: () {
                            setState(() {
                              _selectedSubject = null;
                            });
                            _applyFilter();
                          },
                        ),
                      ],
                    ),
                  ),
                if (_currentFilter == 'author' && _selectedAuthor != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding.horizontal, vertical: 8),
                    child: Row(
                      children: [
                        Chip(
                          label: Text('Автор: $_selectedAuthor'),
                          onDeleted: () {
                            setState(() {
                              _selectedAuthor = null;
                            });
                            _applyFilter();
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Books section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding.horizontal),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _currentFilter == 'new' 
                          ? 'Популярные книги'
                          : _currentFilter == 'subject' && _selectedSubject != null
                              ? 'Книги по предмету: $_selectedSubject'
                              : _currentFilter == 'author' && _selectedAuthor != null
                                  ? 'Книги автора: $_selectedAuthor'
                                  : _currentFilter == 'genre' && _selectedGenre != null
                                      ? 'Книги жанра: $_selectedGenre'
                                      : 'Все книги',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredBooks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    _currentFilter == 'subject' && _selectedSubject == null
                                        ? 'Выберите предмет'
                                        : _currentFilter == 'author' && _selectedAuthor == null
                                            ? 'Выберите автора'
                                            : _currentFilter == 'genre' && _selectedGenre == null
                                                ? 'Выберите жанр'
                                                : 'Книги не найдены',
                                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: padding.horizontal),
                              itemCount: _filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = _filteredBooks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildBookListItem(book),
                                );
                              },
                            ),
                ),
              ] else if (_isSearching)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: _searchResults.isEmpty
                      ? const Center(child: Text('Книги не найдены'))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: padding.horizontal),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final book = _searchResults[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildBookListItem(book),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWeb && isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: 0,
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
                if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LibraryMapScreen(),
                    ),
                  );
                }
              },
            ),
      floatingActionButton: isWeb && isDesktop
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'favorites',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.red.shade400,
                  child: const Icon(Icons.favorite),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'map',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LibraryMapScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue.shade700,
                  child: const Icon(Icons.map),
                ),
              ],
            )
          : null,
    );
  }


  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        setState(() {
          _currentFilter = value;
          _selectedSubject = null;
          _selectedAuthor = null;
          _selectedGenre = null;
        });
        
        if (value == 'subject') {
          await _showSubjectDialog();
        } else if (value == 'author') {
          await _showAuthorDialog();
        } else if (value == 'genre') {
          await _showGenreDialog();
        } else {
          _applyFilter();
        }
      },
    );
  }

  Future<void> _showSubjectDialog() async {
    try {
      final allBooks = await DatabaseHelper.instance.getAllBooks();
      if (allBooks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет книг в библиотеке')),
          );
        }
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
        return;
      }

      final subjects = allBooks
          .where((book) => book.subject != null && book.subject!.isNotEmpty)
          .map((book) => book.subject!)
          .toSet()
          .toList()
        ..sort();

      if (subjects.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет книг с указанными предметами')),
          );
        }
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
        return;
      }

      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите предмет'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  title: Text(subject),
                  onTap: () => Navigator.pop(context, subject),
                );
              },
            ),
          ),
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedSubject = selected;
        });
        _applyFilter();
      } else if (mounted) {
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      setState(() {
        _currentFilter = 'all';
      });
      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      setState(() {
        _currentFilter = 'all';
      });
      _applyFilter();
    }
  }

  Future<void> _showAuthorDialog() async {
    try {
      final allBooks = await DatabaseHelper.instance.getAllBooks();
      if (allBooks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет книг в библиотеке')),
          );
        }
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
        return;
      }

      final authors = allBooks
          .where((book) => book.author.isNotEmpty)
          .map((book) => book.author)
          .toSet()
          .toList()
        ..sort();

      if (authors.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет книг')),
          );
        }
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
        return;
      }

      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите автора'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: authors.length,
              itemBuilder: (context, index) {
                final author = authors[index];
                return ListTile(
                  title: Text(author),
                  onTap: () => Navigator.pop(context, author),
                );
              },
            ),
          ),
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedAuthor = selected;
        });
        _applyFilter();
      } else if (mounted) {
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      setState(() {
        _currentFilter = 'all';
      });
      _applyFilter();
    }
  }

  Future<void> _showGenreDialog() async {
    try {
      final allBooks = await DatabaseHelper.instance.getAllBooks();
      if (allBooks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет книг в библиотеке')),
          );
        }
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
        return;
      }

      final genres = allBooks
          .where((book) => book.genre != null && book.genre!.isNotEmpty)
          .map((book) => book.genre!)
          .toSet()
          .toList()
        ..sort();

      if (genres.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет книг с указанными жанрами')),
          );
        }
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
        return;
      }

      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите жанр'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return ListTile(
                  title: Text(genre),
                  onTap: () => Navigator.pop(context, genre),
                );
              },
            ),
          ),
        ),
      );

      if (selected != null && mounted) {
        setState(() {
          _selectedGenre = selected;
        });
        _applyFilter();
      } else if (mounted) {
        setState(() {
          _currentFilter = 'all';
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      setState(() {
        _currentFilter = 'all';
      });
      _applyFilter();
    }
  }

  Widget _buildBookCard(Book book, {bool isDesktop = false}) {
    final card = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(bookId: book.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: ImageHelper.buildBookCover(
                    imagePath: book.coverImagePath,
                    fit: BoxFit.cover,
                    width: null,
                    height: null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 14 : 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            'В наличии: ${book.availableCopies}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.green.shade100,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return card;
    }

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: card,
    );
  }

  Widget _buildBookListItem(Book book) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(bookId: book.id!),
            ),
          );
        },
      ),
    );
  }
}

