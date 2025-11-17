import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/core/services/chapter_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import '../../../domain/models/book.dart';

class BooksTable{
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<int> insertBook(Book book) async {
    final db = await dbHelper.database;
    final ChapterService chapterService = ChapterService();

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
    if (bookId > 0) {
      _createChaptersForBook(book, bookId, chapterService);
    }
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
      print('✅ Автоматически созданы главы для: "${book.title}"');
    } catch (e) {
      print('⚠️ Ошибка создания глав для "${book.title}": $e');
      // Продолжаем работу даже если главы не создались
    }
  }

  Future<List<Book>> getAllBooks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('books');
    return List.generate(maps.length, (i){
      return Book.fromMap(maps[i]);
    });
  }

  Future<Book?> getBookById(int id) async{
    final db = await dbHelper.database;
    final List<Map<String,dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if(maps.isNotEmpty){
      return Book.fromMap(maps.first);
    }
    return null;
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
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id]
    );
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
    return await db.delete(
        'books',
        where: 'id = ?',
        whereArgs: [id]
    );
  }
}