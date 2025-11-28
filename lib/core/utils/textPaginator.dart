import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

abstract class TextPaginator {
  PaginationResult paginate({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  });
}

class PaginationResult {
  final List<String> pages;
  final int targetPageIndex;
  final int countPage;

  PaginationResult({
    required this.pages,
    required this.targetPageIndex,
    required this.countPage
  });
}

class CoolTextPaginator extends TextPaginator {

  @override
  PaginationResult paginate({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  }) {
    // text = formatBookTextOptimized(text);
    // print("text: \n$text");

    availableWidth = (availableWidth * 0.955).floorToDouble();
    // ЗАДАЧА 1: Вычисляем высоту строки и максимальное количество строк
//     print("PAGINTE availableWidth $availableWidth");
//     print("PAGINTE availableHeight $availableHeight");

    final lineHeight = _calculateLineHeight(textStyle);
    final maxLines = _calculateMaxLines(availableHeight, lineHeight);
    
    final pages = <String>[];
    String remainingText = text;
    int pageNumber = 1;
    int accumulatedLength = 0;
    bool targetPageFound = false;

    const Set<String> whitespaceCharacters = {
      '\n', '\r', ' ', '\t',
    };

    // ЗАДАЧА 3: Повторяем пока есть текст
    while (remainingText.isNotEmpty) {

      // ЗАДАЧА 2: Извлекаем текст для одной страницы
      final pageText = _extractPageText(
        text: remainingText,
        availableWidth: availableWidth,
        maxLines: maxLines,
        textStyle: textStyle,
      );

      if (pageText.isEmpty) {
//         print('⚠️ Остановка пагинации: _extractPageText вернул пустую строку (возможно, слишком мало места).');
        break;
      }

      // ДОБАВЛЯЕМ СТРАНИЦУ
      pages.add(pageText);

      // print("СТРАНИЦА ${pages.length} ${pageText.substring(0,min(100, pageText.length))}");

      String newRemainingText = remainingText.substring(pageText.length);
      // print("ОСТАВШИЙСЯ ТЕКСТ: ${pages.length} ${newRemainingText.substring(0,min(100, newRemainingText.length))}");
      int index = 0;
      while (index < newRemainingText.length && whitespaceCharacters.contains(newRemainingText[index])) {
        index++;
      }
      remainingText = newRemainingText.substring(index);
      // print("ПОСЛЕ ПРОВЕРКИ НА ПРОБЕЛЫ: ${pages.length} ${remainingText.substring(0,min(100, remainingText.length))}");
      if (remainingText.isEmpty && pageNumber < pages.length) {
        break;
      }
      pageNumber++;
    }

    return PaginationResult(
      pages: pages,
      targetPageIndex: 0,
      countPage: pages.length
    );
  }

  // ЗАДАЧА 1: Вычисляем высоту одной строки
  double _calculateLineHeight(TextStyle textStyle) {
    final textPainter = TextPainter(
      text: TextSpan(text: "A", style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    textPainter.layout(maxWidth: double.infinity);
    return textPainter.size.height;
  }

  // ЗАДАЧА 1: Вычисляем максимальное количество строк
  int _calculateMaxLines(double availableHeight, double lineHeight) {
    return (availableHeight / lineHeight).floor();
  }

  // ЗАДАЧА 2: Извлекаем текст для одной страницы
  String _extractPageText({
    required String text,
    required double availableWidth,
    required int maxLines,
    required TextStyle textStyle,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      maxLines: maxLines,
    );

    textPainter.layout(maxWidth: availableWidth);

    // Если текста меньше, чем может уместиться - возвращаем весь текст
    if(!textPainter.didExceedMaxLines){
      return text;
    }

    final TextPosition position = textPainter.getPositionForOffset(
        Offset(availableWidth, textPainter.size.height)
    );

    final int offset = position.offset;

    if (offset == 0) {
      // Если offset = 0, значит, даже один символ не поместился.
      return '';
    }

    final int safeOffset = offset > 0 ? offset - 1 : 0;

    final TextRange lastLineBoundary = textPainter.getLineBoundary(TextPosition(offset: safeOffset));
    final int localEndIndex = lastLineBoundary.end;

    // Гарантируем, что индекс корректен
    if (localEndIndex > 0 && localEndIndex <= text.length) {
      return text.substring(0, localEndIndex);
    } else if (localEndIndex == 0 && text.isNotEmpty) {
      // Если localEndIndex = 0, значит, даже одна строка не поместилась,
      // или это граница пустой строки. Возвращаем пустую строку для
      // завершения цикла пагинации.
      return '';
    } else {
      // Запасной вариант для некорректных localEndIndex (например, -1)
      return '';
    }

    // Ваша предыдущая (и менее точная) логика для FlowLayout:
    /*
    final position = textPainter.getPositionForOffset(
        Offset(availableWidth, textPainter.size.height)
    );
    final pageText = text.substring(0, position.offset);
    return pageText;
    */
  }
}