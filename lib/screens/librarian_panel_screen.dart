import 'package:flutter/material.dart';
import 'add_book_screen.dart';
import 'manage_books_screen.dart';
import 'manage_shelves_screen.dart';
import 'book_issue_return_screen.dart';

class LibrarianPanelScreen extends StatelessWidget {
  const LibrarianPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель библиотекаря'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            icon: Icons.add_circle,
            title: 'Добавить книгу',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBookScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.library_books,
            title: 'Управление книгами',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageBooksScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.shelves,
            title: 'Управление стеллажами',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageShelvesScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.swap_horiz,
            title: 'Выдача/Возврат',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookIssueReturnScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Convert Color to MaterialColor shades
    Color getShade400(Color baseColor) {
      if (baseColor == Colors.green) return Colors.green.shade400;
      if (baseColor == Colors.blue) return Colors.blue.shade400;
      if (baseColor == Colors.orange) return Colors.orange.shade400;
      if (baseColor == Colors.purple) return Colors.purple.shade400;
      return baseColor;
    }

    Color getShade700(Color baseColor) {
      if (baseColor == Colors.green) return Colors.green.shade700;
      if (baseColor == Colors.blue) return Colors.blue.shade700;
      if (baseColor == Colors.orange) return Colors.orange.shade700;
      if (baseColor == Colors.purple) return Colors.purple.shade700;
      return baseColor;
    }

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [getShade400(color), getShade700(color)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

