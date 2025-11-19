import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

class TextPaginator {
  List<String> paginate({
    required String fullText,
    required TextStyle textStyle,
    required Size pageSize,
    EdgeInsets padding = const EdgeInsets.all(16.0),
  }) {
    List<String> pages = <String>[];
    String remainingText = fullText;

    final availableSize = _calculateAvailableSize(
      size: pageSize,
      padding: padding,
    );

    print('📐 TextPaginator - Доступный размер: $availableSize');

    double widthFactor = 0.5;
    int retries = 0;
    final int upperLayoutRunsLimit = 20;

    int pageCharacterLimit = _estimatePageCharacterLimit(
      size: availableSize,
      textStyle: textStyle,
      widthFactor: widthFactor,
    );

    while (remainingText.isNotEmpty) {
      final String pageTextEstimate = _getPageTextEstimate(
        text: remainingText,
        pageCharacterLimit: pageCharacterLimit,
      );

      final PageProperties pageProperties = _getPageText(
        text: pageTextEstimate,
        textStyle: textStyle,
        size: availableSize,
      );

      // Оптимизация оценок (как в оригинальном коде)
      if (_shouldOptimizeEstimates(pageProperties.layoutRuns, upperLayoutRunsLimit)) {
        widthFactor = _updateWidthFactor(
          widthFactor: widthFactor,
          layoutRuns: pageProperties.layoutRuns,
          upperLayoutRunsLimit: upperLayoutRunsLimit,
        );

        pageCharacterLimit = _estimatePageCharacterLimit(
          size: availableSize,
          textStyle: textStyle,
          widthFactor: widthFactor,
        );
      }

      if (_performRetry(pageProperties.layoutRuns, retries)) {
        retries++;
        continue;
      }

      pages.add(pageProperties.text);
      remainingText = remainingText.substring(pageProperties.text.length).trimLeft();
      retries = 0;

      print('📄 Создана страница ${pages.length}: ${pageProperties.text.length} символов');
    }

    print('✅ TextPaginator - Всего страниц: ${pages.length}');
    return pages;
  }

  bool _shouldOptimizeEstimates(int layoutRuns, int upperLayoutRunsLimit) {
    return layoutRuns > upperLayoutRunsLimit || layoutRuns == 1;
  }

  bool _performRetry(int layoutRuns, int retries) {
    return layoutRuns == 1 && retries <= 0;
  }

  double _updateWidthFactor({
    required double widthFactor,
    required int layoutRuns,
    required int upperLayoutRunsLimit,
  }) {
    final double newWidthFactor = layoutRuns >= upperLayoutRunsLimit
        ? widthFactor + 0.05
        : widthFactor - 0.05;
    return newWidthFactor.clamp(0.3, 0.8);
  }

  PageProperties _getPageText({
    required String text,
    required TextStyle textStyle,
    required Size size,
  }) {
    double paragraphHeight = 10000;
    String currentText = text;
    int layoutRuns = 0;
    final RegExp regExp = RegExp(r"\S+[\W]*$");

    print('📏 _getPageText - Макс. высота: ${size.height}px');

    while (paragraphHeight > size.height && currentText.isNotEmpty) {
      final paragraph = _layoutParagraph(
        text: currentText,
        textStyle: textStyle,
        size: size,
      );
      paragraphHeight = paragraph.height;

      print('   🔄 layoutRun $layoutRuns: height = ${paragraphHeight}px');

      if (paragraphHeight > size.height) {
        final beforeTrim = currentText.length;
        currentText = currentText.replaceFirst(regExp, '').trimRight();
        final afterTrim = currentText.length;
        print('   ✂️ Обрезано ${beforeTrim - afterTrim} символов');
      }
      layoutRuns = layoutRuns + 1;

      if (layoutRuns > 50) {
        print('   ⚠️ Прервано: слишком много итераций');
        break;
      }
    }

    print('   ✅ Финальный текст: ${currentText.length} символов, высота: ${paragraphHeight}px');
    return PageProperties(currentText, layoutRuns);
  }

  String _getPageTextEstimate({
    required String text,
    required int pageCharacterLimit,
  }) {
    final initialPageTextEstimate =
    text.substring(0, math.min(pageCharacterLimit + 1, text.length));

    final substringIndex =
    initialPageTextEstimate.lastIndexOf(RegExp(r"\s+\b|\b\s+|[\.?!]"));

    if (substringIndex == -1) {
      return initialPageTextEstimate;
    }

    final pageTextEstimate =
    text.substring(0, math.min(substringIndex + 1, text.length));
    return pageTextEstimate;
  }

  Size _calculateAvailableSize({
    required Size size,
    required EdgeInsets padding,
  }) {
    final double availableHeight = size.height -
        (padding.top + padding.bottom);
    final double availableWidth = size.width -
        (padding.left + padding.right);
    return Size(availableWidth, availableHeight);
  }

  int _estimatePageCharacterLimit({
    required Size size,
    required TextStyle textStyle,
    required double widthFactor,
  }) {
    final characterHeight = textStyle.fontSize!;
    final characterWidth = characterHeight * widthFactor;
    return ((size.height * size.width) / (characterHeight * characterWidth)).ceil();
  }

  ui.Paragraph _layoutParagraph({
    required String text,
    required TextStyle textStyle,
    required Size size,
  }) {
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: textStyle.fontSize,
        fontFamily: textStyle.fontFamily,
        fontStyle: textStyle.fontStyle,
        fontWeight: textStyle.fontWeight,
        textAlign: TextAlign.left,
      ),
    )
      ..pushStyle(textStyle.getTextStyle())
      ..addText(text);

    final ui.Paragraph paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width));

    return paragraph;
  }
}

class PageProperties {
  final String text;
  final int layoutRuns;

  PageProperties(this.text, this.layoutRuns);
}