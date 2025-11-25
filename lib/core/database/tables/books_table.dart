import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/core/services/book_cache_service.dart';
import 'package:mangalibrary/core/services/chapter_service.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import '../../../domain/models/book.dart';

class BooksTable{
  final DatabaseHelper dbHelper = DatabaseHelper();
  final ChapterTable _chapterTable = ChapterTable();

  Future<int> insertBook(Book book) async {
    final db = await dbHelper.database;

    int bookId;

    if (book.id == null) {
      // Новая книга - вставляем и получаем ID
      bookId = await db.insert('books', book.toMap());
    } else {
      // Книга с ID - проверяем существование
      final existingBook = await getBookById(book.id!);
      if (existingBook == null) {
        bookId = await db.insert('books', book.toMap());
      } else {
        // Если существует - обновляем и возвращаем ID
        await updateBook(book);
        return book.id!;
      }
    }
    // После успешного сохранения книги создаем главы
    // if (bookId > 0) {
    //   _createChaptersForBook(book, bookId, chapterService);
    // }
    return bookId;
  }

  void _createChaptersForBook(Book book, int bookId, ChapterService chapterService) async {
    try {
      // Создаем копию книги с установленным ID
      final bookWithId = Book(
        id: bookId,
        title: book.title,
        author: book.author,
        bookType: book.bookType,
        fileFolderPath: book.fileFolderPath,
        filePath: book.filePath,
        fileFormat: book.fileFormat,
        fileSize: book.fileSize,
        currentPage: book.currentPage,
        totalPages: book.totalPages,
        progress: book.progress,
        coverImagePath: book.coverImagePath,
        status: book.status,
        addedDate: book.addedDate,
        lastDateOpen: book.lastDateOpen,
        readingTime: book.readingTime,
        isFavorite: book.isFavorite,
        tags: book.tags,
      );

      await chapterService.createChapterForBook(bookWithId);
      // print('✅ Автоматически созданы главы для: "${book.title}"');
    } catch (e) {
      // print('⚠️ Ошибка создания глав для "${book.title}": $e');
      // Продолжаем работу даже если главы не создались
    }
  }

  Future<List<Book>> getAllBooks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> bookMaps = await db.query(
      'books',
    );

    List<Book> books = bookMaps.map((map) => Book.fromMap(map)).toList();

    // 🔥 Загрузка глав для ВСЕХ книг (цикл N+1)
    for (final book in books) {
      if (book.id != null) {
        final List<VolumeChapter> chapters = await _chapterTable.getChaptersByBookId(book.id!);
        book.chapters = chapters;
      }
    }
    return books;
  }

  // Future<List<Book>> getAllBooks() async {
  //   final db = await dbHelper.database;
  //   final List<Map<String, dynamic>> maps = await db.query('books');
  //   return List.generate(maps.length, (i){
  //     return Book.fromMap(maps[i]);
  //   });
  // }

  Future<Book?> getBookById(int id) async{
    final db = await dbHelper.database;
    final List<Map<String,dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    final Book book = Book.fromMap(maps.first);

    final List<VolumeChapter> chapters = await _chapterTable.getChaptersByBookId(book.id!);

    book.chapters = chapters;

    return null;
  }

  Future<List<Book>> getBooks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> bookMaps = await db.query(
      'books',
    );

    List<Book> books = bookMaps.map((map) => Book.fromMap(map)).toList();

    // 🔥 Загрузка глав для ВСЕХ книг (цикл N+1)
    for (final book in books) {
      if (book.id != null) {
        final List<VolumeChapter> chapters = await _chapterTable.getChaptersByBookId(book.id!);
        book.chapters = chapters;
      }
    }

    return books;
  }

  Future<bool> doesBookExist(String title) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title = ?',
      whereArgs: [title],
    );
    return maps.isNotEmpty;
  }

  Future<bool> doesFileExist(String filePath) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
    return maps.isNotEmpty;
  }

  Future<int> updateBook(Book book) async {
    final db = await dbHelper.database;
//     print('🔄 [BOOKS_TABLE] Обновляем книгу в БД:');
//     print('   📖 ID: ${book.id}');
//     print('   📄 Текущая страница: ${book.currentPage}');
//     print('   📊 Всего страниц: ${book.totalPages}');
//     print('   📍 Позиция в тексте: ${book.lastSymbolIndex}');
//     print('   📈 Прогресс: ${book.progress}');

    int result = await db.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id]
    );

    if (book.chapters.isNotEmpty) {
      await _chapterTable.updateChapters(book.chapters);
      // print('✅ [BOOKS_TABLE] Обновлена информация о ${book.chapters.length} главах.');
    }

    // print('✅ [BOOKS_TABLE] Книга обновлена. Строк изменено: $result');
    return result;
  }

  Future<int>? updateBookField({
    required int bookId,
    required String fieldName,
    required dynamic value,
  }) async {
    final db = await dbHelper.database;

    return await db.update(
      'books',
      {fieldName: value},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await dbHelper.database;


    int chaptersDeleted = await _chapterTable.deleteChaptersByBookId(id);
//     print('✅ [BOOKS_TABLE] Удалено $chaptersDeleted глав для книги ID: $id');

    BookCacheService().removeFromCache(id);
//     print('🧹 Книга ID: $id удалена из кэша');

    return await db.delete(
        'books',
        where: 'id = ?',
        whereArgs: [id]
    );
  }
}