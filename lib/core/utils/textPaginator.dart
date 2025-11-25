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

  PaginationResult({
    required this.pages,
    required this.targetPageIndex,
  });
}

class CoolTextPaginator extends TextPaginator {

  String formatBookTextOptimized(String text) {
    final buffer = StringBuffer('\u00A0\u00A0\u00A0\u00A0\u00A0');
    const String indent = '\u00A0\u00A0\u00A0\u00A0\u00A0';

    // Флаги состояния
    bool inParagraph = false;
    bool previousWasNewline = false;

    // Новый флаг для пропуска пробелов после \n
    bool shouldSkipSpace = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Символы, которые нужно игнорировать всегда
      if (char == '\r' || char == '\t' || char == '\u00A0') {
        continue;
      }

      // Если мы должны пропустить пробел, и текущий символ - пробел, пропускаем его.
      if (shouldSkipSpace && char == ' ') {
        continue;
      }

      if (char == '\n') {
        // Мы встретили \n, сбрасываем флаг, который мог быть установлен пробелом
        shouldSkipSpace = true;

        if (previousWasNewline && inParagraph) {
          // Двойной \n - конец абзаца
          buffer.write('\n$indent'); // Используем \n\n для вертикального интервала
          inParagraph = false;
          previousWasNewline = false;
        } else {
          // Одинарный \n (мягкий перенос строки)
          buffer.write('\n');
          previousWasNewline = true;
        }

      } else {
        // Обычный символ (включая ' ')

        // Как только мы видим любой контентный символ (включая ' '),
        // мы больше не пропускаем пробелы в начале (так как они уже внутри абзаца)
        shouldSkipSpace = false;

        if (!inParagraph) {
          inParagraph = true;
        }

        // ВАЖНОЕ ИЗМЕНЕНИЕ: Отступ добавляется только при ДВОЙНОМ \n
        if (previousWasNewline && inParagraph) {
          // Если предыдущий был \n, а текущий символ - НЕ \n,
          // это означает, что предыдущий \n был одиночным переносом строки.
          // В вашей старой логике здесь добавлялся отступ,
          // что и приводило к отступу при мягком переносе.
          // Мы просто пропускаем этот блок, чтобы не добавлять отступ.

          // Если вы хотите, чтобы одиночный \n всегда давал отступ (как в старой логике):
          buffer.write(indent);
        }

        buffer.write(char);
        previousWasNewline = false;
      }
    }
    return buffer.toString();
  }


  @override
  PaginationResult paginate({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
  }) {
    text = formatBookTextOptimized(text);
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

      String newRemainingText = remainingText.substring(pageText.length);


      int index = 0;
      while (index < newRemainingText.length && whitespaceCharacters.contains(newRemainingText[index])) {
        index++;
      }
      remainingText = newRemainingText.substring(index);
      if (remainingText.isEmpty && pageNumber < pages.length) {
        break;
      }
      pageNumber++;
    }

    return PaginationResult(
      pages: pages,
      targetPageIndex: 0,
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