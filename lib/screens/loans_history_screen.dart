import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/loan.dart';
import '../models/book.dart';

class LoansHistoryScreen extends StatefulWidget {
  const LoansHistoryScreen({super.key});

  @override
  State<LoansHistoryScreen> createState() => _LoansHistoryScreenState();
}

class _LoansHistoryScreenState extends State<LoansHistoryScreen> {
  List<Loan> _loans = [];
  List<Book> _books = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'active', 'returned'
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final loans = await DatabaseHelper.instance.getAllLoans();
    final books = await DatabaseHelper.instance.getAllBooks();
    setState(() {
      _loans = loans;
      _books = books;
      _isLoading = false;
    });
  }

  List<Loan> get _filteredLoans {
    var filtered = _loans;

    // Фильтр по статусу
    if (_filter == 'active') {
      filtered = filtered.where((loan) => !loan.isReturned).toList();
    } else if (_filter == 'returned') {
      filtered = filtered.where((loan) => loan.isReturned).toList();
    }

    // Поиск по имени заёмщика
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((loan) {
        final book = _books.firstWhere(
          (b) => b.id == loan.bookId,
          orElse: () => Book(
            rackId: 0,
            title: '',
            author: '',
            totalCopies: 0,
            availableCopies: 0,
            onHandCopies: 0,
          ),
        );
        return loan.borrowerName.toLowerCase().contains(query) ||
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Book? _getBookForLoan(Loan loan) {
    try {
      return _books.firstWhere((b) => b.id == loan.bookId);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLoans = _filteredLoans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История выдачи книг'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по заёмщику, названию или автору книги',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Фильтры
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Все'),
                    selected: _filter == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'all');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Активные'),
                    selected: _filter == 'active',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'active');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Возвращённые'),
                    selected: _filter == 'returned',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'returned');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Список займов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLoans.isEmpty
                    ? const Center(child: Text('Записи не найдены'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredLoans.length,
                          itemBuilder: (context, index) {
                            final loan = filteredLoans[index];
                            final book = _getBookForLoan(loan);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: loan.isReturned
                                  ? Colors.grey.shade50
                                  : Colors.white,
                              child: ListTile(
                                leading: Icon(
                                  loan.isReturned
                                      ? Icons.check_circle
                                      : Icons.access_time,
                                  color: loan.isReturned
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 40,
                                ),
                                title: Text(
                                  book?.title ?? 'Неизвестная книга',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Автор: ${book?.author ?? "Неизвестен"}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Заёмщик: ${loan.borrowerName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text('${loan.quantity} экз.'),
                                          backgroundColor: Colors.blue.shade100,
                                          labelStyle: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Выдано: ${_formatDate(loan.issueDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (loan.returnDate != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Возвращено: ${_formatDate(loan.returnDate!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: loan.isReturned
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : const Icon(Icons.access_time, color: Colors.orange),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

