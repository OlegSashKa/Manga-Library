import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mangalibrary/core/utils/recursive_text_splitter.dart';

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
      fontFamily: fontFamily,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify, // 🔥 ВЫРАВНИВАНИЕ КАК В ЧИТАЛКЕ
      maxLines: null,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: lineHeight,
        forceStrutHeight: true, // 🔥 ОБЯЗАТЕЛЬНЫЙ СТРУТ
      ),
    );

    // Лэйаутим текст с реальной шириной
    textPainter.layout(maxWidth: pageWidth);

    final totalTextHeight = textPainter.size.height;
    final pageCount = (totalTextHeight / pageHeight).ceil();

    print('🎨 TEXT PAINTER РАСЧЁТ:');
    print('   📏 Макс. ширина: ${pageWidth.toStringAsFixed(1)}px');
    print('   📐 Высота текста: ${textPainter.size.height.toStringAsFixed(1)}px');
    print('   📊 Высота страницы: ${pageHeight.toStringAsFixed(1)}px');
    print('   📖 Рассчитано страниц: $pageCount');
    print('   📈 Соотношение: ${totalTextHeight.toStringAsFixed(1)}px / ${pageHeight.toStringAsFixed(1)}px = ${(totalTextHeight / pageHeight).toStringAsFixed(2)}');

    return pageCount > 0 ? pageCount : 1;
  }
}