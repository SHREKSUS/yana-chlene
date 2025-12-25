import 'package:flutter/material.dart';

class ImageHelper {
  /// Создает placeholder для обложки книги
  static Widget _buildPlaceholder({
    required double? width,
    required double? height,
    Widget? customWidget,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: customWidget ??
        Center(
          child: Icon(
            Icons.book,
            size: (height ?? 100) * 0.4,
            color: Colors.white,
          ),
        ),
    );
  }

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
    final defaultErrorWidget = errorWidget ?? _buildPlaceholder(width: width, height: height);
    final defaultPlaceholder = placeholder ?? _buildPlaceholder(width: width, height: height);

    if (imagePath == null || imagePath.isEmpty) {
      return defaultErrorWidget;
    }

    // Проверяем, является ли путь локальным asset
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          // Если файл не найден, показываем placeholder
          return defaultErrorWidget;
        },
      );
    }
    
    // Если путь не начинается с http/https, но и не assets, считаем его placeholder
    if (!imagePath.startsWith('http://') && !imagePath.startsWith('https://')) {
      return defaultErrorWidget;
    }

    // Сетевой URL
    return Image.network(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return defaultPlaceholder;
      },
      errorBuilder: (context, error, stackTrace) => defaultErrorWidget,
    );
  }
}

