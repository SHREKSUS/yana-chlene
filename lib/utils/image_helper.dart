import 'package:flutter/material.dart';

class ImageHelper {
  /// Отображает изображение обложки книги
  /// Поддерживает как локальные assets, так и сетевые URL
  static Widget buildBookCover({
    required String? imagePath,
    required BoxFit fit,
    required double? width,
    required double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return errorWidget ?? 
        Container(
          color: Colors.blue.shade100,
          child: const Icon(Icons.book, size: 50, color: Colors.blue),
        );
    }

    // Проверяем, является ли путь локальным asset
    if (imagePath.startsWith('assets/') || !imagePath.startsWith('http')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => errorWidget ??
          Container(
            color: Colors.blue.shade100,
            child: const Icon(Icons.book, size: 50, color: Colors.blue),
          ),
      );
    }

    // Сетевой URL
    return Image.network(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
          Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) => errorWidget ??
        Container(
          color: Colors.blue.shade100,
          child: const Icon(Icons.book, size: 50, color: Colors.blue),
        ),
    );
  }
}

