// page_manager.dart - ПОЛНАЯ ЗАМЕНА
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PageManager extends ChangeNotifier {
  List<String> _pages = [];
  int _currentPageIndex = 0;

  List<String> get pages => _pages;
  int get currentPageIndex => _currentPageIndex;
  int get totalPages => _pages.length;

  void calculatePages({
    required String text,
    required double pageWidth,
    required double pageHeight,
    required double fontSize,
    required double lineHeight,
    required String fontFamily,
  }) {
    print('📖 [PAGE_MANAGER] Запускаем УМНЫЙ расчет страниц');
    print('   📏 Размеры: ${pageWidth}x${pageHeight}');

    _pages = [];

    final textStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: fontFamily,
    );

    String remainingText = text.trim();
    int safetyCounter = 0;

    while (remainingText.isNotEmpty && safetyCounter < 1000) {
      safetyCounter++;

      // 🔥 УМНАЯ ОЦЕНКА сколько текста может поместиться
      int estimatedLimit = _estimatePageCharacterLimit(
        textStyle: textStyle,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      // 🔥 БЕРЕМ ТЕКСТ ДО ЕСТЕСТВЕННОЙ ГРАНИЦЫ
      String pageTextEstimate = _getTextToNaturalBreak(
        text: remainingText,
        characterLimit: estimatedLimit,
      );

      // 🔥 ТОЧНЫЙ РАСЧЕТ С ui.Paragraph
      String finalPageText = _calculateExactPageText(
        text: pageTextEstimate,
        textStyle: textStyle,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      if (finalPageText.isEmpty) {
        // 🔥 ЗАЩИТА ОТ ЗАВИСАНИЯ
        finalPageText = remainingText;
        remainingText = '';
      } else {
        remainingText = remainingText.substring(finalPageText.length).trimLeft();
      }

      _pages.add(finalPageText);
      print('   📄 Страница ${_pages.length}: ${finalPageText.length} символов');
    }

    _currentPageIndex = 0;
    print('✅ Расчет завершен: ${_pages.length} страниц');
    notifyListeners();
  }

  // 🔥 ОЦЕНКА ЛИМИТА СИМВОЛОВ ДЛЯ СТРАНИЦЫ
  int _estimatePageCharacterLimit({
    required TextStyle textStyle,
    required double pageWidth,
    required double pageHeight,
  }) {
    // Средняя ширина символа ~ 60% от высоты
    double avgCharWidth = textStyle.fontSize! * 0.6;
    double avgCharHeight = textStyle.fontSize! * textStyle.height!;

    int charsPerLine = (pageWidth / avgCharWidth).floor();
    int linesPerPage = (pageHeight / avgCharHeight).floor();

    return (charsPerLine * linesPerPage * 1.2).ceil(); // +20% запас
  }

  // 🔥 ПОИСК ЕСТЕСТВЕННОЙ ГРАНИЦЫ (точка, пробел, запятая)
  String _getTextToNaturalBreak({
    required String text,
    required int characterLimit,
  }) {
    if (text.length <= characterLimit) {
      return text;
    }

    String estimate = text.substring(0, math.min(characterLimit, text.length));

    // 🔥 ИЩЕМ ПОСЛЕДНЮЮ УДАЧНУЮ ТОЧКУ РАЗРЫВА
    int lastGoodBreak = estimate.lastIndexOf(RegExp(r'[.!?]\s+'));
    if (lastGoodBreak == -1) {
      lastGoodBreak = estimate.lastIndexOf(RegExp(r'[,!;]\s+'));
    }
    if (lastGoodBreak == -1) {
      lastGoodBreak = estimate.lastIndexOf(' ');
    }
    if (lastGoodBreak == -1) {
      lastGoodBreak = characterLimit - 10; // принудительный отступ
    }

    return text.substring(0, math.min(lastGoodBreak + 1, text.length));
  }

  // 🔥 ТОЧНЫЙ РАСЧЕТ С ui.Paragraph
  String _calculateExactPageText({
    required String text,
    required TextStyle textStyle,
    required double pageWidth,
    required double pageHeight,
  }) {
    String currentText = text;
    int iterations = 0;

    while (iterations < 100) {
      iterations++;

      // 🔥 ИСПОЛЬЗУЕМ ТОТ ЖЕ МЕТОД ЧТО И В ПРОВЕРКЕ
      bool fits = _textFitsInPage(
        text: currentText,
        textStyle: textStyle,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      if (fits) {
        return currentText;
      }

      // УМЕНЬШАЕМ ТЕКСТ
      String reducedText = _reduceTextToFit(currentText);
      if (reducedText == currentText || reducedText.isEmpty) {
        break;
      }
      currentText = reducedText;
    }

    return currentText;
  }

  String _reduceTextToFit(String text) {
    if (text.length < 10) return text;

    // 🔥 УМЕНЬШАЕМ НА 10% И ИЩЕМ ГРАНИЦУ
    int newLength = (text.length * 0.9).floor();
    String reduced = text.substring(0, newLength);

    // ИЩЕМ ПОСЛЕДНЮЮ ГРАНИЦУ
    int lastBreak = reduced.lastIndexOf(RegExp(r'[.!?]\s+'));
    if (lastBreak == -1) lastBreak = reduced.lastIndexOf(RegExp(r'[,;]\s+'));
    if (lastBreak == -1) lastBreak = reduced.lastIndexOf(' ');
    if (lastBreak == -1) lastBreak = newLength - 5;

    return text.substring(0, math.max(1, lastBreak + 1)).trim();
  }

  bool _textFitsInPage({
    required String text,
    required TextStyle textStyle,
    required double pageWidth,
    required double pageHeight,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      maxLines: null,
      strutStyle: StrutStyle(
        fontSize: textStyle.fontSize,
        height: textStyle.height,
        forceStrutHeight: true,
      ),
    );

    textPainter.layout(maxWidth: pageWidth);
    double textHeight = textPainter.size.height;

    // 🔥 ДОБАВЛЯЕМ ЗАПАС 5px ДЛЯ БУФЕРА
    bool fits = textHeight <= (pageHeight - 5);

    print('      📏 Проверка: ${text.length} символов = ${textHeight.toStringAsFixed(1)}px <= ${pageHeight}px = $fits');

    return fits;
  }

  // 🔥 МЕТОДЫ НАВИГАЦИИ (без изменений)
  void nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _currentPageIndex++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex--;
      notifyListeners();
    }
  }

  void goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _pages.length) {
      _currentPageIndex = pageIndex;
      notifyListeners();
    }
  }
}