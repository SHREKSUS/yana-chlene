import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/building.dart';
import '../models/shelf.dart';
import '../models/rack.dart';

class ManageShelvesScreen extends StatefulWidget {
  const ManageShelvesScreen({super.key});

  @override
  State<ManageShelvesScreen> createState() => _ManageShelvesScreenState();
}

class _ManageShelvesScreenState extends State<ManageShelvesScreen> {
  List<Building> _buildings = [];
  Building? _selectedBuilding;
  List<Shelf> _shelves = [];
  List<Rack> _racks = [];
  Shelf? _selectedShelf;

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
    });
  }

  Future<void> _loadRacks() async {
    if (_selectedShelf == null) return;

    final racks = await DatabaseHelper.instance.getRacksByShelf(_selectedShelf!.id!);
    setState(() {
      _racks = racks;
    });
  }

  Future<void> _addShelf() async {
    final letterController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить стеллаж'),
        content: TextField(
          controller: letterController,
          decoration: const InputDecoration(
            labelText: 'Буква стеллажа (A, B, C...)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, letterController.text),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && _selectedBuilding != null) {
      final shelf = Shelf(
        buildingId: _selectedBuilding!.id!,
        letter: result.toUpperCase(),
      );
      await DatabaseHelper.instance.insertShelf(shelf);
      _loadShelves();
    }
  }

  Future<void> _addRack() async {
    if (_selectedShelf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите стеллаж')),
      );
      return;
    }

    final numberController = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить полку'),
        content: TextField(
          controller: numberController,
          decoration: const InputDecoration(
            labelText: 'Номер полки',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final number = int.tryParse(numberController.text);
              if (number != null) {
                Navigator.pop(context, number);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null && _selectedShelf != null) {
      final rack = Rack(
        shelfId: _selectedShelf!.id!,
        number: result,
      );
      await DatabaseHelper.instance.insertRack(rack);
      _loadRacks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление стеллажами и полками'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Building selector
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: DropdownButtonFormField<Building>(
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
                  _selectedShelf = null;
                  _racks = [];
                });
                _loadShelves();
              },
            ),
          ),
          // Shelves section
          Expanded(
            child: Row(
              children: [
                // Shelves list
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Стеллажи',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addShelf,
                              tooltip: 'Добавить стеллаж',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _shelves.isEmpty
                            ? const Center(child: Text('Нет стеллажей'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _shelves.length,
                                itemBuilder: (context, index) {
                                  final shelf = _shelves[index];
                                  final isSelected = _selectedShelf?.id == shelf.id;
                                  return Card(
                                    color: isSelected ? Colors.blue.shade100 : null,
                                    child: ListTile(
                                      title: Text('Стеллаж ${shelf.letter}'),
                                      selected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          _selectedShelf = shelf;
                                        });
                                        _loadRacks();
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Racks list
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedShelf == null
                                  ? 'Полки'
                                  : 'Полки (Стеллаж ${_selectedShelf!.letter})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedShelf != null)
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _addRack,
                                tooltip: 'Добавить полку',
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedShelf == null
                            ? const Center(child: Text('Выберите стеллаж'))
                            : _racks.isEmpty
                                ? const Center(child: Text('Нет полок'))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: _racks.length,
                                    itemBuilder: (context, index) {
                                      final rack = _racks[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text('Полка ${rack.number}'),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

