import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/favorite.dart';
import '../utils/responsive.dart';
import '../utils/image_helper.dart';
import 'library_map_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  Map<String, dynamic>? _location;
  bool _isLoading = true;
  bool _isFavorite = false;
  final String _userId = 'guest'; // In real app, get from auth

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  Future<void> _loadBookDetails() async {
    final book = await DatabaseHelper.instance.getBookById(widget.bookId);
    final location = await DatabaseHelper.instance.getBookLocation(widget.bookId);
    final favorite = await DatabaseHelper.instance.isFavorite(widget.bookId, _userId);

    setState(() {
      _book = book;
      _location = location;
      _isFavorite = favorite;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_book == null) return;

    if (_isFavorite) {
      await DatabaseHelper.instance.removeFavorite(_book!.id!, _userId);
    } else {
      await DatabaseHelper.instance.addFavorite(
        Favorite(bookId: _book!.id!, userId: _userId),
      );
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Книга не найдена')),
        body: const Center(child: Text('Книга не найдена')),
      );
    }

    final building = _location?['building'];
    final shelf = _location?['shelf'];
    final rack = _location?['rack'];

    final isDesktop = Responsive.isDesktop(context);
    final maxWidth = Responsive.getMaxWidth(context);
    final padding = Responsive.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали книги'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image on left
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 500,
                          margin: padding,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageHelper.buildBookCover(
                              imagePath: _book!.coverImagePath,
                              fit: BoxFit.cover,
                              width: null,
                              height: 500,
                              errorWidget: Container(
                                color: Colors.blue.shade100,
                                child: const Icon(Icons.book, size: 100, color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Details on right
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: padding,
                          child: _buildBookDetails(building, shelf, rack, isDesktop),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image
                      Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey.shade300,
                        child: ImageHelper.buildBookCover(
                          imagePath: _book!.coverImagePath,
                          fit: BoxFit.cover,
                          width: null,
                          height: 300,
                          errorWidget: const Icon(Icons.book, size: 100),
                        ),
                      ),
                      Padding(
                        padding: padding,
                        child: _buildBookDetails(building, shelf, rack, isDesktop),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetails(dynamic building, dynamic shelf, dynamic rack, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _book!.title,
          style: TextStyle(
            fontSize: isDesktop ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Author
        Text(
          _book!.author,
          style: TextStyle(
            fontSize: isDesktop ? 22 : 18,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        // Location
        if (building != null && shelf != null && rack != null)
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Местоположение:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 18 : 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${building.name} → Стеллаж ${shelf.letter} → Полка ${rack.number}',
                    style: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Status
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
                  child: Column(
                    children: [
                      const Text(
                        'В наличии',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${_book!.availableCopies}',
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
                  child: Column(
                    children: [
                      const Text(
                        'На руках',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${_book!.onHandCopies}',
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Description
        if (_book!.description != null) ...[
          Text(
            'Описание:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 20 : 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _book!.description!,
            style: TextStyle(fontSize: isDesktop ? 16 : 14),
          ),
          const SizedBox(height: 24),
        ],
        // Subject
        if (_book!.subject != null) ...[
          Chip(
            label: Text(
              'Предмет: ${_book!.subject}',
              style: TextStyle(fontSize: isDesktop ? 14 : 12),
            ),
            backgroundColor: Colors.blue.shade100,
            padding: EdgeInsets.all(isDesktop ? 8 : 4),
          ),
          const SizedBox(height: 24),
        ],
        // Show on map button
        if (building != null && shelf != null && rack != null)
          SizedBox(
            width: double.infinity,
            height: isDesktop ? 56 : 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LibraryMapScreen(
                      highlightBuildingId: building.id,
                      highlightShelfId: shelf.id,
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.map,
                size: isDesktop ? 28 : 24,
              ),
              label: Text(
                'Просмотреть на карте',
                style: TextStyle(fontSize: isDesktop ? 18 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Add to favorites button
        SizedBox(
          width: double.infinity,
          height: isDesktop ? 56 : 50,
          child: ElevatedButton.icon(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              size: isDesktop ? 28 : 24,
            ),
            label: Text(
              _isFavorite ? 'В избранном' : 'Добавить в избранное',
              style: TextStyle(fontSize: isDesktop ? 18 : 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFavorite ? Colors.red.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

