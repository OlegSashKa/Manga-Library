import 'package:flutter/material.dart';

class PageCalculatorService {
  static int calculatePageCount({
    required String text,
    required double pageWidth,
    required double pageHeight,
    required double fontSize,
    required double lineHeight,
    required double horizontalPadding,
    required double verticalPadding,
    String? fontFamily, // 🔥 ДОБАВЛЯЕМ ШРИФТ
  }) {
    if (text.isEmpty) return 1;

    final textStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: fontFamily, // 🔥 ПЕРЕДАЁМ ШРИФТ
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left, // 🔥 ВЫРАВНИВАНИЕ КАК В ЧИТАЛКЕ
      maxLines: null,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: lineHeight,
        forceStrutHeight: true, // 🔥 ОБЯЗАТЕЛЬНЫЙ СТРУТ
      ),
    );

    // Лэйаутим текст с реальной шириной
    textPainter.layout(maxWidth: pageWidth);

    final didExceedMaxLines = textPainter.didExceedMaxLines;
    final minIntrinsicWidth = textPainter.minIntrinsicWidth;
    final maxIntrinsicWidth = textPainter.maxIntrinsicWidth;

    print('🎨 TEXT PAINTER РАСЧЁТ:');
    print('   📏 Макс. ширина: ${pageWidth.toStringAsFixed(1)}px');
    print('   📐 Высота текста: ${textPainter.size.height.toStringAsFixed(1)}px');
    print('   📐 Ширина текста: ${textPainter.size.width.toStringAsFixed(1)}px');
    print('   📐 Min intrinsic: ${minIntrinsicWidth.toStringAsFixed(1)}px');
    print('   📐 Max intrinsic: ${maxIntrinsicWidth.toStringAsFixed(1)}px');
    print('   📊 Высота страницы: ${pageHeight.toStringAsFixed(1)}px');
    print('   ⚠️  Превышение лимита: $didExceedMaxLines');
    print('   🔤 Шрифт: $fontFamily');

    final totalTextHeight = textPainter.size.height;
    final pageCount = (totalTextHeight / pageHeight).ceil();

    print('   📖 Рассчитано страниц: $pageCount');
    print('   📈 Соотношение: ${totalTextHeight.toStringAsFixed(1)}px / ${pageHeight.toStringAsFixed(1)}px = ${(totalTextHeight / pageHeight).toStringAsFixed(2)}');

    return pageCount > 0 ? pageCount : 1;
  }

  static List<String> splitTextIntoPages({
    required String text,
    required double pageWidth,
    required double pageHeight,
    required double fontSize,
    required double lineHeight,
    required String fontFamily,
  }) {
    if (text.isEmpty) return [text];

    final List<String> pages = [];
    int startIndex = 0;
    String remainingText = text;

    final textStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: fontFamily,
    );

    while (startIndex < text.length) {

      // Находим, какой текст помещается на одну страницу
      final endIndex = _findPageBreak(
        text: text,
        startIndex: startIndex,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        textStyle: textStyle,
      );

      if (endIndex == startIndex) break;

      final pageText = text.substring(startIndex, endIndex).trim();
      pages.add(pageText);

      startIndex = endIndex;

      print('📄 Страница ${pages.length}: символы $startIndex-$endIndex (${pageText.length} символов)');
    }
    print('🧪 ПРОВЕРКА РАЗМЕРОВ СТРАНИЦ:');
    for (int i = 0; i < pages.length; i++) {
      final testPainter = TextPainter(
        text: TextSpan(text: pages[i], style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );
      testPainter.layout(maxWidth: pageWidth);

      final fits = testPainter.size.height <= pageHeight;
      print('   📄 Страница ${i + 1}: ${testPainter.size.height.toStringAsFixed(1)}px / ${pageHeight.toStringAsFixed(1)}px - ${fits ? '✅' : '❌'}');
    }
    print('📄 Разбито на ${pages.length} страниц');
    print('🔍 ПРОВЕРКА ГРАНИЦ СТРАНИЦ:');
    for (int i = 0; i < pages.length - 1; i++) {
      final currentPageEnd = pages[i];
      final nextPageStart = pages[i + 1];

      // Проверяем последний символ текущей страницы и первый символ следующей
      final lastChar = currentPageEnd.isNotEmpty ? currentPageEnd[currentPageEnd.length - 1] : '';
      final firstChar = nextPageStart.isNotEmpty ? nextPageStart[0] : '';

      print('   📄 Страница ${i + 1} → ${i + 2}: "$lastChar" → "$firstChar"');
    }
    return pages;
  }

  static _findPageBreak({
    required String text,
    required int startIndex,
    required double pageWidth,
    required double pageHeight,
    required TextStyle textStyle,
  }) {
    int low = startIndex + 1;
    int high = text.length;
    int result = startIndex;

    final double tolerance = pageHeight * 0.05;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final testText = text.substring(startIndex, mid);

      final textPainter = TextPainter(
        text: TextSpan(text: testText, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      // 🔥 ИСПРАВЛЯЕМ: используем pageWidth
      textPainter.layout(maxWidth: pageWidth);

      if (textPainter.size.height <= pageHeight - tolerance) {
        // Текст помещается - пробуем взять больше
        result = mid;
        low = mid + 1;
      } else {
        // Текст не помещается - берем меньше
        high = mid - 1;
      }
    }
    if (result < text.length) {
      result = _findNearestBreak(text, result);
    }

    if (result == startIndex && startIndex < text.length) {
      result = text.length;
    }
    // 🔥 ДОБАВЛЯЕМ: если не нашли разрыв, берем до конца
    if (result == startIndex && startIndex < text.length) {
      result = text.length;
    }

    return result;
  }

  static int _findNearestBreak(String text, int suggestedBreak) {
    // Ищем назад до начала строки или пробела
    for (int i = suggestedBreak; i > 0; i--) {
      final char = text[i];

      // 🔥 ГРАНИЦЫ РАЗРЫВА
      if (char == '\n') {
        return i + 1; // перенос строки - идеальная граница
      }
      if (char == ' ' || char == '\t') {
        return i + 1; // пробел - хорошая граница
      }
      if (char == '.' || char == '!' || char == '?' || char == ',' || char == ';' || char == ':') {
        return i + 1; // знак препинания - приемлемая граница
      }
    }

    // Если не нашли границу, ищем вперёд
    for (int i = suggestedBreak; i < text.length; i++) {
      final char = text[i];

      if (char == '\n') {
        return i + 1;
      }
      if (char == ' ' || char == '\t') {
        return i + 1;
      }
    }

    // Если совсем не нашли границ, возвращаем исходный разрыв
    return suggestedBreak;
  }
}