import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

abstract class TextPaginator {
  List<String> paginate({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  });
}

class BasicTextPaginator extends TextPaginator {
  // КЭШ для хранения всех абзацев (добавляем в начало класса)
  String str ='''The second super long continuous line continues testing the pagination system and checks how the algorithm handles text where there are no natural line breaks and all words run together without any line breaks or punctuation marks that could help in determining page boundaries which is a challenging task for any text processor especially when font size can change dynamically during reading by the user.

Third mega long string without a single line break for maximum testing of paginator capabilities which should be able to split such text into pages correctly
  ''';

  List<String>? _cachedParagraphs;
  String? _cachedText;
  // Счетчик использованных абзацев
  int _usedParagraphsCount = 0;

  @override
  List<String> paginate({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  }) {
    print('=== НАЧАЛО ИНКРЕМЕНТАЛЬНОЙ ПАГИНАЦИИ ===');
    availableWidth = availableWidth.floorToDouble();
    availableHeight = availableHeight.floorToDouble();
    // НАХОДИМ ВСЕ АБЗАЦЫ ОДИН РАЗ (заменяем старую логику)
    if (_cachedParagraphs == null || _cachedText != text) {
      print('🔍 Поиск всех абзацев в тексте...');
      _cachedParagraphs = _getAllParagraphs(text, 0);
      _cachedText = text;
      _usedParagraphsCount = 0; // ← СБРОС
    }

    final pages = <String>[];
    int pageNumber = 1;
    // ПРОСТОЙ ЦИКЛ: пока есть неиспользованные абзацы
    while (_usedParagraphsCount  < _cachedParagraphs!.length) {
      print('\n--- Создание страницы $pageNumber ---');

      String pageText = _buildPageContentFromParagraphs(
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        textStyle: textStyle,
      );


      if (pageText.isEmpty) {
        print('⚠️  Пустая страница! Прерываем.');
        break;
      }

      pages.add(pageText);
      pageNumber++;

      print('Текущий индекс абзаца: $_usedParagraphsCount из ${_cachedParagraphs!.length}');
    }
    print('=== ИЗМЕНЕННЫЙ массив параграфов: длинна ${_cachedParagraphs!.length} ===');
    for(int i = 0; i < _cachedParagraphs!.length; i++){
      print("parag[$i] " + _cachedParagraphs![i]);
    }
    print('=== ПОЛУЧЕНО СТРАНИЦ: ${pages.length} ===');
    for(int i = 0; i < pages.length; i++){
      print("page[${i+1}] " + pages[i]);
    }
    return pages;
  }

  /// Строим страницу из уже найденных абзацев
  String _buildPageContentFromParagraphs({
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  }) {
    print('Построение страницы из абзацев, начиная с индекса: $_usedParagraphsCount');

    String currentPageText = '';

    for (int i = _usedParagraphsCount; i < _cachedParagraphs!.length; i++) {
      final paragraph = _cachedParagraphs![i];
      final testText = currentPageText + paragraph;

      print('\nАБЗАЦ ${i + 1}:');
      print('   Текст: "$paragraph"');

      if (_fitsInPage(
        text: testText,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        textStyle: textStyle,
      )) {
        currentPageText = testText;
        // УВЕЛИЧИВАЕМ счетчик использованных абзацев
        _usedParagraphsCount = i + 1;
      } else {
        print('paragraph not vlez: "$paragraph"');
        List<String> words = paragraph.split(RegExp(r'(?=\n)|(?<=\n)| '));
        String trimmedText = '';
        String notVlezli = "";

        for(int i = words.length - 1; i > 0; i--){
          List<String> currentWords = words.sublist(0, i);
          String strJoint = currentWords.join(' ');
          trimmedText = currentPageText + strJoint;

          if (_fitsInPage(
            text: trimmedText,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            textStyle: textStyle,
          )) {
            // Сохраняем слова которые НЕ вошли
            List<String> notUsedWords = words.sublist(i);
            notVlezli = notUsedWords.join(' ').replaceAll(RegExp(r'^\n+'), '');
            break;
          } else {
            trimmedText = "";
          }
        }
        _usedParagraphsCount = i + 1;
        print('words vlezli: \n"${trimmedText}"');
        currentPageText = trimmedText;
        if (notVlezli.isNotEmpty) {
          _cachedParagraphs!.insert(i + 1, notVlezli);
          print('words NE vlezli: ${notVlezli == "\n" ? "\\n" : notVlezli}');
          print('words NE vlezli for chach ${i+1}: ${_cachedParagraphs![i+1] == "\n" ? "\\n" : notVlezli}');
        }
        break;
      }
    }
    return currentPageText.replaceAll(RegExp(r'\n+$'), '');
  }

  /// Получаем все абзацы из текста
  List<String> _getAllParagraphs(String text, int startPosition) {
    print('\n📖 ПОИСК И ОЧИСТКА АБЗАЦЕВ:');

    final paragraphs = text.split("\n\n")
        .map((paragraph) => "   " + paragraph + "\n\n")
        .toList();
    for(int i = 0; i < paragraphs.length; i++){
      print("parag[$i] " + paragraphs[i]);
    }

    print('📊 ИТОГО: ${paragraphs.length} абзацев\n');
    return paragraphs;
  }

  /// Проверяет, помещается ли текст в доступную область
  bool _fitsInPage({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  }) {
    if (text.isEmpty) return true;
    print('\nТекст:: \n"${text}"');
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
    );

    textPainter.layout(maxWidth: availableWidth);

    final bool fits = textPainter.height <= availableHeight;
    print('   Проверка текста (${text.length} символов): '
        'высота = ${textPainter.height.toStringAsFixed(1)} / $availableHeight '
        '→ ${fits ? 'ПОМЕЩАЕТСЯ' : 'НЕ ПОМЕЩАЕТСЯ'}');

    return fits;
  }
}

