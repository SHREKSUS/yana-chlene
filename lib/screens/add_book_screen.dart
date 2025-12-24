import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/building.dart';
import '../models/shelf.dart';
import '../models/rack.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _copiesController = TextEditingController(text: '1');
  final _coverImageController = TextEditingController();

  List<Building> _buildings = [];
  Building? _selectedBuilding;
  List<Shelf> _shelves = [];
  Shelf? _selectedShelf;
  List<Rack> _racks = [];
  Rack? _selectedRack;
  bool _isLoading = false;

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
        _selectedBuilding = buildings.first;
        _loadShelves();
      }
    });
  }

  Future<void> _loadShelves() async {
    if (_selectedBuilding == null) return;

    final shelves = await DatabaseHelper.instance.getShelvesByBuilding(_selectedBuilding!.id!);
    setState(() {
      _shelves = shelves;
      if (shelves.isNotEmpty) {
        _selectedShelf = shelves.first;
        _loadRacks();
      } else {
        _racks = [];
        _selectedRack = null;
      }
    });
  }

  Future<void> _loadRacks() async {
    if (_selectedShelf == null) return;

    final racks = await DatabaseHelper.instance.getRacksByShelf(_selectedShelf!.id!);
    setState(() {
      _racks = racks;
      if (racks.isNotEmpty) {
        _selectedRack = racks.first;
      } else {
        _selectedRack = null;
      }
    });
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите полку')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalCopies = int.parse(_copiesController.text);
      final book = Book(
        rackId: _selectedRack!.id!,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        totalCopies: totalCopies,
        availableCopies: totalCopies,
        onHandCopies: 0,
        coverImagePath: _coverImageController.text.trim().isEmpty
            ? null
            : _coverImageController.text.trim(),
      );

      await DatabaseHelper.instance.insertBook(book);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Книга успешно добавлена')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _copiesController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить книгу'),
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
              // Building selection
              const Text(
                '1. Выберите корпус:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Building>(
                value: _selectedBuilding,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Корпус',
                ),
                items: _buildings.map((building) {
                  return DropdownMenuItem(
                    value: building,
                    child: Text(building.name),
                  );
                }).toList(),
                onChanged: (building) {
                  setState(() {
                    _selectedBuilding = building;
                  });
                  _loadShelves();
                },
              ),
              const SizedBox(height: 24),
              // Shelf selection
              const Text(
                '2. Выберите стеллаж и полку:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Shelf>(
                      value: _selectedShelf,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Стеллаж',
                      ),
                      items: _shelves.map((shelf) {
                        return DropdownMenuItem(
                          value: shelf,
                          child: Text('Стеллаж ${shelf.letter}'),
                        );
                      }).toList(),
                      onChanged: (shelf) {
                        setState(() {
                          _selectedShelf = shelf;
                        });
                        _loadRacks();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Rack>(
                      value: _selectedRack,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Полка',
                      ),
                      items: _racks.map((rack) {
                        return DropdownMenuItem(
                          value: rack,
                          child: Text('Полка ${rack.number}'),
                        );
                      }).toList(),
                      onChanged: (rack) {
                        setState(() {
                          _selectedRack = rack;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Book data
              const Text(
                '3. Заполните данные о книге:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
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
                  labelText: 'Путь к изображению (например: assets/images/book.png)',
                  hintText: 'assets/images/book_placeholder.png',
                  border: OutlineInputBorder(),
                  helperText: 'Оставьте пустым для использования placeholder',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
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

