import 'dart:io';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class ChapterService {
  final ChapterTable _chaptersTable = ChapterTable();

  Future<void> createChapterForBook(Book book) async {
    switch (book.bookType) {
      case BookType.text:
        await _createSingleChapterForTxt(book);
        break;
      case BookType.manga:
      // Для манги пока заглушка - одна глава
        await _createSingleChapterForManga(book);
        break;
    }
  }

  Future<void> _createSingleChapterForTxt(Book book) async {
    final chapter = BookChapter(
      bookId: book.id!, // Должен быть установлен после сохранения книги
      title: 'Вся книга',
      startPage: 1,
      endPage: book.totalPages,
      currentPage: book.currentPage,
      isRead: book.currentPage > 0,
      position: 0,
    );

    await _chaptersTable.insertChapter(chapter);
    print('Создана одна глава для TXT книги: ${book.title}');
  }

  Future<void> _createSingleChapterForManga(Book book) async {
    final chapter = BookChapter(
      bookId: book.id!,
      title: 'Том 1',
      startPage: 1,
      endPage: book.totalPages,
      currentPage: book.currentPage,
      isRead: book.currentPage > 0,
      position: 0,
    );

    await _chaptersTable.insertChapter(chapter);
    print('Создана одна глава для манги: ${book.title}');
  }

  /// Заглушка для EPUB - будем реализовывать позже
  Future<void> _createChaptersForEpub(Book book) async {
    // TODO: Реализовать парсинг EPUB для получения глав
    print('Создание глав для EPUB еще не реализовано для книги: ${book.title}');

    // Временная заглушка - одна глава
    await _createSingleChapterForTxt(book);
  }

  Future<List<BookChapter>> getBookChapters(int bookId) async {
    return await _chaptersTable.getChaptersByBookId(bookId);
  }

  Future<void> updateReadingProgress(int bookId, int currentPage) async {
    final chapters = await getBookChapters(bookId);

    for (final chapter in chapters) {
      if (currentPage >= chapter.startPage &&
          (chapter.endPage == null || currentPage <= chapter.endPage!)) {
        await _chaptersTable.updateChapterCurrentPage(
            chapter.id!,
            currentPage
        );
        for (final prevChapter in chapters) {
          if (prevChapter.position < chapter.position &&
              prevChapter.endPage != null &&
              currentPage > prevChapter.endPage!) {
            await _chaptersTable.updateChapterCurrentPage(
                prevChapter.id!,
                prevChapter.endPage!);
          }
        }
        break;
      }
    }
  }
}