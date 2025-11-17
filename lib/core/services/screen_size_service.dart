import 'package:flutter/material.dart';

class ScreenSizeService {
  static late double screenWidth;
  static late double screenHeight;
  static late double statusBarHeight;
  static late double appBarHeight;
  static late double safeAreaHeight;

  static void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    statusBarHeight = mediaQuery.padding.top;
    appBarHeight = kToolbarHeight; // Стандартная высота AppBar - 56.0

    // Вычисляем безопасную высоту для контента
    safeAreaHeight = screenHeight - statusBarHeight - appBarHeight;

    print('''
📱 Размеры экрана инициализированы:
   Ширина: ${screenWidth.toStringAsFixed(1)}
   Высота: ${screenHeight.toStringAsFixed(1)}
   StatusBar: ${statusBarHeight.toStringAsFixed(1)}
   StatusBar: ${statusBarHeight.toStringAsFixed(1)}
   AppBar: $appBarHeight
   SafeArea: ${safeAreaHeight.toStringAsFixed(1)}
''');
  }

  // Метод для получения размеров страницы книги (с учетом отступов)
  static ({double width, double height}) getBookPageDimensions() {
    const double horizontalPadding = 32.0; // 16 + 16
    const double verticalPadding = 32.0;   // 16 + 16

    final double pageWidth = screenWidth - horizontalPadding;
    final double pageHeight = safeAreaHeight - verticalPadding;

    return (width: pageWidth, height: pageHeight);
  }

  // Метод для обновления размеров при изменении ориентации
  static void updateDimensions(BuildContext context) {
    initialize(context);
  }
}