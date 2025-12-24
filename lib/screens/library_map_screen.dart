import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/database_helper.dart';
import '../models/building.dart';
import '../models/shelf.dart';
import '../models/rack.dart';
import '../models/book.dart';
import '../utils/responsive.dart';
import 'book_detail_screen.dart';
import 'main_screen.dart';
import 'favorites_screen.dart';

class LibraryMapScreen extends StatefulWidget {
  final int? highlightBuildingId;
  final int? highlightShelfId;

  const LibraryMapScreen({
    super.key,
    this.highlightBuildingId,
    this.highlightShelfId,
  });

  @override
  State<LibraryMapScreen> createState() => _LibraryMapScreenState();
}

class _LibraryMapScreenState extends State<LibraryMapScreen> {
  List<Building> _buildings = [];
  Building? _selectedBuilding;
  List<Shelf> _shelves = [];
  Shelf? _selectedShelf;
  List<Rack> _racks = [];
  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    final buildings = await DatabaseHelper.instance.getAllBuildings();
    setState(() {
      _buildings = buildings;
      if (buildings.isNotEmpty) {
        // Если указан building для подсветки, выбираем его
        if (widget.highlightBuildingId != null) {
          _selectedBuilding = buildings.firstWhere(
            (b) => b.id == widget.highlightBuildingId,
            orElse: () => buildings.first,
          );
        } else {
          _selectedBuilding = buildings.first;
        }
        _loadShelves();
      }
      _isLoading = false;
    });
  }

  Future<void> _loadShelves() async {
    if (_selectedBuilding == null) return;

    final shelves = await DatabaseHelper.instance.getShelvesByBuilding(_selectedBuilding!.id!);
    setState(() {
      _shelves = shelves;
      if (shelves.isNotEmpty) {
        // Если указан shelf для подсветки, выбираем его
        if (widget.highlightShelfId != null) {
          _selectedShelf = shelves.firstWhere(
            (s) => s.id == widget.highlightShelfId,
            orElse: () => shelves.first,
          );
        } else {
          _selectedShelf = shelves.first;
        }
        _loadAllRacks(); // Загружаем все полки для отображения
      }
    });
  }

  Future<void> _loadRacks() async {
    if (_selectedShelf == null) return;

    final racks = await DatabaseHelper.instance.getRacksByShelf(_selectedShelf!.id!);
    setState(() {
      _racks = racks;
      if (racks.isNotEmpty) {
        _loadBooks();
      } else {
        _books = [];
      }
    });
  }

  Future<void> _loadAllRacks() async {
    if (_selectedBuilding == null) return;
    
    final allShelves = await DatabaseHelper.instance.getShelvesByBuilding(_selectedBuilding!.id!);
    final allRacks = <Rack>[];
    for (var shelf in allShelves) {
      final racks = await DatabaseHelper.instance.getRacksByShelf(shelf.id!);
      allRacks.addAll(racks);
    }
    
    final books = await DatabaseHelper.instance.getAllBooks();
    
    setState(() {
      _racks = allRacks;
      _books = books.where((book) => allRacks.any((rack) => rack.id == book.rackId)).toList();
    });
  }

  Future<void> _loadBooks() async {
    if (_selectedShelf == null) return;

    final allBooks = await DatabaseHelper.instance.getAllBooks();
    final shelfRacks = _racks.map((r) => r.id).toList();
    setState(() {
      _books = allBooks.where((book) => shelfRacks.contains(book.rackId)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Карта библиотеки')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDesktop = Responsive.isDesktop(context);
    final maxWidth = Responsive.getMaxWidth(context);
    final padding = Responsive.getPadding(context);
    final crossAxisCount = Responsive.isDesktop(context) ? 8 : Responsive.isTablet(context) ? 6 : 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта библиотеки'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Building selector
              Container(
                padding: padding,
                color: Colors.blue.shade50,
                child: Row(
                  children: _buildings.map((building) {
                    final isSelected = _selectedBuilding?.id == building.id;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBuilding = building;
                            });
                            _loadShelves();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.blue.shade700 : Colors.white,
                            foregroundColor: isSelected ? Colors.white : Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            building.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Library map with realistic shelf layout
              Expanded(
                child: _shelves.isEmpty
                    ? const Center(child: Text('Нет стеллажей'))
                    : SingleChildScrollView(
                        padding: padding,
                        child: _buildRealisticLibraryLayout(),
                      ),
              ),
              // Books list grouped by racks
              if (_selectedShelf != null && _books.isNotEmpty)
                Container(
                  height: isDesktop ? 300 : 250,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Книги на стеллаже ${_selectedShelf!.letter}:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 20 : 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBooksByRacks(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritesScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRealisticLibraryLayout() {
    if (_shelves.isEmpty) return const SizedBox();

    // Группируем стеллажи по парам для создания рядов
    final shelfPairs = <List<Shelf>>[];
    for (int i = 0; i < _shelves.length; i += 2) {
      if (i + 1 < _shelves.length) {
        shelfPairs.add([_shelves[i], _shelves[i + 1]]);
      } else {
        shelfPairs.add([_shelves[i]]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Схема библиотеки
        ...shelfPairs.asMap().entries.map((entry) {
          final index = entry.key;
          final pair = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              children: [
                // Ряд стеллажей
                Row(
                  children: [
                    // Левый стеллаж
                    Expanded(
                      child: _buildShelfCard(pair[0], isLeft: true),
                    ),
                    // Проход
                    Container(
                      width: 60,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.directions_walk,
                          color: Colors.grey.shade400,
                          size: 30,
                        ),
                      ),
                    ),
                    // Правый стеллаж (если есть)
                    if (pair.length > 1)
                      Expanded(
                        child: _buildShelfCard(pair[1], isLeft: false),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
                // Номер ряда
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ряд ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildShelfCard(Shelf shelf, {required bool isLeft}) {
    final isSelected = _selectedShelf?.id == shelf.id;
    final isHighlighted = widget.highlightShelfId != null && shelf.id == widget.highlightShelfId;
    
    // Получаем полки для этого стеллажа
    final shelfRacks = _racks.where((rack) => rack.shelfId == shelf.id).toList();
    
    // Подсчитываем общее количество книг на стеллаже
    final totalBooks = shelfRacks.fold<int>(
      0,
      (sum, rack) => sum + _books.where((book) => book.rackId == rack.id).length,
    );
    shelfRacks.sort((a, b) => a.number.compareTo(b.number));
    
    // Подсчитываем книги на каждой полке
    final rackBookCounts = <int, int>{};
    for (var rack in shelfRacks) {
      final bookCount = _books.where((book) => book.rackId == rack.id).length;
      rackBookCounts[rack.number] = bookCount;
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedShelf = shelf;
        });
        _loadRacks();
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.orange.shade50
              : isSelected
                  ? Colors.brown.shade50
                  : Colors.brown.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted
                ? Colors.orange.shade700
                : isSelected
                    ? Colors.brown.shade900
                    : Colors.brown.shade700,
            width: isHighlighted ? 3 : 2,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    spreadRadius: 4,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Заголовок стеллажа
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Colors.orange.shade400
                    : isSelected
                        ? Colors.brown.shade700
                        : Colors.brown.shade800,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Text(
                'Стеллаж ${shelf.letter}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Информация о стеллаже
            Expanded(
              child: Center(
                child: Icon(
                  Icons.library_books,
                  size: 50,
                  color: Colors.brown.shade600,
                ),
              ),
            ),
            if (isHighlighted)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  'ЗДЕСЬ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksByRacks() {
    if (_books.isEmpty || _racks.isEmpty) {
      return const Center(child: Text('Нет книг'));
    }

    // Группируем книги по полкам
    final booksByRack = <int, List<Book>>{};
    for (var rack in _racks) {
      final rackBooks = _books.where((book) => book.rackId == rack.id).toList();
      if (rackBooks.isNotEmpty) {
        booksByRack[rack.number] = rackBooks;
      }
    }

    // Сортируем полки по номеру
    final sortedRackNumbers = booksByRack.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedRackNumbers.length,
      itemBuilder: (context, index) {
        final rackNumber = sortedRackNumbers[index];
        final rackBooks = booksByRack[rackNumber]!;
        final rack = _racks.firstWhere((r) => r.number == rackNumber);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок полки
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shelves,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Полка ${rack.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${rackBooks.length} ${_getBookWord(rackBooks.length)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Список книг на полке
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rackBooks.map((book) {
                    return SizedBox(
                      width: 150,
                      child: Card(
                        elevation: 1,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(bookId: book.id!),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.author,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (book.subject != null) ...[
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(
                                      book.subject!,
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getBookWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'книга';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'книги';
    } else {
      return 'книг';
    }
  }
}

