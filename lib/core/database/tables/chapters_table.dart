import 'package:sqflite/sqflite.dart';
import 'package:mangalibrary/core/database/database_helper.dart';
import '../../../domain/models/book.dart';

class ChapterTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertChapter(BookChapter chapter) async {
    final db = await _dbHelper.database;
    return await db.insert('chapters', chapter.toMap());
  }

  Future<List<BookChapter>> getChaptersByBookId(int bookId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'position ASC', // Сортируем по порядку
    );

    return maps.map((map) => BookChapter.fromMap(map)).toList();
  }

  Future<BookChapter?> getChapter(int chapterId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'id = ?',
      whereArgs: [chapterId],
    );

    if (maps.isNotEmpty) {
      return BookChapter.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateChapter(BookChapter chapter) async {
    final db = await _dbHelper.database;
    return await db.update(
      'chapters',
      chapter.toMap(),
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  Future<int> updateChapterCurrentPage(int chapterId, int currentPage) async {
    final db = await _dbHelper.database;
    return await db.update(
      'chapters',
      {
        'current_page': currentPage,
        'is_read': currentPage > 0 ? 1 : 0, // Помечаем как прочитанную если есть прогресс
      },
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  Future<int> deleteChapter(int chapterId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'chapters',
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  Future<int> deleteChaptersByBookId(int bookId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  Future<BookChapter?> getCurrentChapter(int bookId, int currentPage) async {
    final chapters = await getChaptersByBookId(bookId);

    // Ищем главу, в диапазон которой попадает текущая страница
    for (final chapter in chapters) {
      if (currentPage >= chapter.startPage &&
          (chapter.endPage == null || currentPage <= chapter.endPage!)) {
        return chapter;
      }
    }

    return null;
  }
}
