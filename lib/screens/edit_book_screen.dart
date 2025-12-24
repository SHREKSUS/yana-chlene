import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';

class EditBookScreen extends StatefulWidget {
  final int bookId;

  const EditBookScreen({super.key, required this.bookId});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subjectController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _copiesController = TextEditingController();
  final _coverImageController = TextEditingController();

  Book? _book;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final book = await DatabaseHelper.instance.getBookById(widget.bookId);
    if (book != null) {
      setState(() {
        _book = book;
        _titleController.text = book.title;
        _authorController.text = book.author;
        _subjectController.text = book.subject ?? '';
        _genreController.text = book.genre ?? '';
        _descriptionController.text = book.description ?? '';
        _copiesController.text = book.totalCopies.toString();
        _coverImageController.text = book.coverImagePath ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate() || _book == null) return;

    setState(() => _isSaving = true);

    try {
      final totalCopies = int.parse(_copiesController.text);
      final currentOnHand = _book!.onHandCopies;
      final newAvailableCopies = totalCopies - currentOnHand;
      
      // Проверяем, что новое количество не меньше уже выданных книг
      if (newAvailableCopies < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Количество экземпляров не может быть меньше количества выданных книг'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }
      
      final updatedBook = _book!.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        totalCopies: totalCopies,
        availableCopies: newAvailableCopies,
        coverImagePath: _coverImageController.text.trim().isEmpty
            ? null
            : _coverImageController.text.trim(),
      );

      final result = await DatabaseHelper.instance.updateBook(updatedBook);
      
      if (result > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Книга успешно обновлена')),
        );
        Navigator.pop(context, true); // Возвращаем true для обновления списка
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при обновлении книги'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _copiesController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактировать книгу')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Книга не найдена')),
        body: const Center(child: Text('Книга не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать книгу'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Автор *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите автора';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Предмет',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Жанр',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _copiesController,
                decoration: const InputDecoration(
                  labelText: 'Количество экземпляров *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите количество';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Введите корректное число';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coverImageController,
                decoration: const InputDecoration(
                  labelText: 'Путь к изображению',
                  hintText: 'assets/images/book_placeholder.png',
                  border: OutlineInputBorder(),
                  helperText: 'Например: assets/images/book.png',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Сохранить',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

