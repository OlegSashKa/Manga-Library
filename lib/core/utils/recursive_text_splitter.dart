import 'dart:math';
import 'package:flutter/material.dart';

class RecursiveTextSplitter {
  static List<String> splitText({
    required String text,
    required double pageWidth,
    required double pageHeight,
    required double fontSize,
    required double lineHeight,
    required String fontFamily,
  }) {
    print('🎯 НАЧАЛО РУЧНОЙ РАЗБИВКИ');
    print('   📏 Страница: ${pageWidth}x${pageHeight}px');
    print('   🔤 Шрифт: ${fontSize}px, межстрочный: $lineHeight');

    // Создаем TextPainter для измерений
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
    );

    final textStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: fontFamily,
    );

    List<String> pages = [];
    int currentPosition = 0;

    // Шаг 1: Понять высоту одной строки
    double singleLineHeight = _calculateSingleLineHeight(textPainter, textStyle, pageWidth);
    print('   📐 Высота одной строки: ${singleLineHeight}px');

    // Шаг 2: Посчитать сколько строк помещается на странице
    int maxLinesPerPage = (pageHeight / singleLineHeight).floor();
    print('   📊 Максимум строк на странице: $maxLinesPerPage');

    // Шаг 3: Разбиваем текст постранично
    while (currentPosition < text.length) {
      String pageText = _extractTextForPage(
        text: text,
        start: currentPosition,
        textPainter: textPainter,
        textStyle: textStyle,
        pageWidth: pageWidth,
        maxLines: maxLinesPerPage,
      );

      pages.add(pageText);
      currentPosition += pageText.length;

      print('   📄 Страница ${pages.length}: ${pageText.length} символов');
    }

    print('✅ РАЗБИВКА ЗАВЕРШЕНА: ${pages.length} страниц');
    return pages;
  }

  // Шаг 1: Вычисляем высоту одной строки
  static double _calculateSingleLineHeight(
      TextPainter painter,
      TextStyle style,
      double maxWidth,
      ) {
    painter.text = TextSpan(text: 'A', style: style); // Любой символ
    painter.layout(maxWidth: maxWidth);
    return painter.size.height;
  }


  static String _extractTextForPage({
    required String text,
    required int start,
    required TextPainter textPainter,
    required TextStyle textStyle,
    required double pageWidth,
    required int maxLines,
  }) {
    print('\n🔍 Поиск текста для страницы, начиная с символа $start');

    int currentEnd = start + 1;
    String bestFitText = '';

    while (currentEnd <= text.length) {
      String testText = text.substring(start, currentEnd);

      textPainter.text = TextSpan(text: testText, style: textStyle);
      textPainter.layout(maxWidth: pageWidth);

      double textHeight = textPainter.size.height;
      double singleLineHeight = textPainter.preferredLineHeight;
      int actualLines = (textHeight / singleLineHeight).ceil();

      if (actualLines <= maxLines) {
        bestFitText = testText;
        currentEnd++;
      } else {
        bestFitText = _findBeautifulBreak(text, start, currentEnd - 1);
        break;
      }

      if (currentEnd > text.length) {
        break;
      }
    }

    print('   ✅ Выбран текст: ${bestFitText.length} символов');

    return bestFitText;
  }

  static String _findBeautifulBreak(String text, int start, int roughEnd) {
    print('   🎯 Ищем красивый разрыв в диапазоне $start-$roughEnd');

    for (int i = roughEnd; i > start; i--) {
      if (text[i] == '\n') {
        print('     💫 Найден разрыв по переносу строки');
        return text.substring(start, i + 1);
      } else if (text[i] == '.') {
        print('     💫 Найден разрыв по точке');
        return text.substring(start, i + 1);
      } else if (text[i] == ' ') {
        print('     💫 Найден разрыв по пробелу');
        return text.substring(start, i + 1);
      }
    }

    print('     ⚠️  Красивый разрыв не найден, берем как есть');
    return text.substring(start, roughEnd);
  }
}