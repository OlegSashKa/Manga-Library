// core/utils/epub_parser_utils.dart
import 'package:epub_pro/epub_pro.dart';
import 'package:flutter/cupertino.dart';
import 'package:html/parser.dart' show parse;
import 'package:mangalibrary/core/utils/textPaginator.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';

class PagedEpubContent {
  final List<String> allBookPages;
  final List<VolumeChapter> chapters;
  final int initialPageIndex;

  PagedEpubContent({
    required this.allBookPages,
    required this.chapters,
    required this.initialPageIndex,
  });
}

class EpubParserUtils {

  /// Извлекает первое предложение (или фрагмент) для краткого заголовка.
// core/utils/epub_parser_utils.dart (внутри класса EpubParserUtils)

  static PagedEpubContent extractAndPaginateBook({
    required EpubBook epubBook,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
    required int idBook,
  }) {
    final List<String> allBookPages = [];
    final List<VolumeChapter> chapters = [];
    final initialPageIndex = 0; // Эта переменная используется только для возврата

    // 🔥 ИСПРАВЛЕННАЯ ЛОГИКА ОБХОДА
    if (epubBook.chapters.isNotEmpty) {

      // Проходим по всем основным главам, начиная с chapter[0]
      for (int i = 0; i < epubBook.chapters.length; i++) {
        final EpubChapter chapter = epubBook.chapters[i];

        if (i == 0) {
          // 🔴 Игнорируем chapter[0] и его subChapters по требованию.
          print('ℹ️ [EPUB_PARSER] Пропускаем первую главу и ее подглавы (chapter[0]).');
          continue;
        }

        // 🟢 Для всех последующих глав (chapter[1], chapter[2]...)
        // Обрабатываем ТОЛЬКО их subChapters.
        if (chapter.subChapters.isNotEmpty) {
          print('ℹ️ [EPUB_PARSER] Обрабатываем ${chapter.subChapters.length} подглав из главы ${i}.');

          // Вызываем рекурсивную функцию, передавая СПИСОК подглав:
          _processAndPaginateChapterRecursive(
            chapter.subChapters, // Список EpubChapter для обработки
            chapters,
            allBookPages,
            availableWidth,
            availableHeight,
            textStyle,
            initialPageIndex, // Передаем, хотя она и не используется для рекурсии
            idBook,
          );
        } else {
          // Если у главы (кроме chapter[0]) нет подглав, мы ее пропускаем,
          // так как нам нужны только subChapters.
          print('ℹ️ [EPUB_PARSER] Глава ${i} не имеет подглав и будет проигнорирована.');
          continue;
        }
      }
    }

    // Возвращаем результат
    return PagedEpubContent(
      allBookPages: allBookPages,
      chapters: chapters,
      initialPageIndex: initialPageIndex,
    );
  }

  /// Рекурсивный метод для обработки одной главы и ее подглав.
  static void _processAndPaginateChapterRecursive(
      List<EpubChapter> epubChapters,
      List<VolumeChapter> chapters,
      List<String> allBookPages,
      double availableWidth,
      double availableHeight,
      TextStyle textStyle,
      int initialPageIndex,
      int idBook,
      ) {
    for (final epubChapter in epubChapters) {
      // 1. Извлечение и очистка текста
      final String rawChapterText = parse(epubChapter.htmlContent ?? '').body?.text ?? '';

      // 2. ПАГИНАЦИЯ ТЕКСТА ТЕКУЩЕЙ ГЛАВЫ
      final chapterPages = CoolTextPaginator().paginate(
        text: rawChapterText,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        textStyle: textStyle,
      ).pages;

      // 3. Индексация: Запоминаем начальную страницу (0-based)
      final int startPageIndex = allBookPages.length;
      final int newChapterPagesCount = chapterPages.length;

      // 4. Добавляем главу в плоский список
      // Важно: startPage и endPage - это индексы в List<String> allBookPages
      chapters.add(VolumeChapter(
        bookId: idBook, // ID будет присвоен позже
        title: epubChapter.title?.trim() ?? 'Глава без названия',
        startPage: startPageIndex,
        endPage: startPageIndex + newChapterPagesCount - 1, // Конечный индекс
        position: chapters.length, // Позиция в плоском списке
      ));

      // 5. Добавляем страницы главы в общий список
      allBookPages.addAll(chapterPages);

      // 6. Рекурсивный вызов для подглав
      if (epubChapter.subChapters.isNotEmpty) {
        _processAndPaginateChapterRecursive(
          epubChapter.subChapters,
          chapters,
          allBookPages,
          availableWidth,
          availableHeight,
          textStyle,
          initialPageIndex,
          idBook,
        );
      }
    }
  }
}