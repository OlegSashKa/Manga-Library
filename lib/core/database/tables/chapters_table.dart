import 'package:sqflite/sqflite.dart';
import 'package:mangalibrary/core/database/database_helper.dart';
import '../../../domain/models/book.dart';

class ChapterTable {
  final DatabaseHelper dbHelper = DatabaseHelper();
  
  Future<int> insertChapter(BookChapter chapter, int bookId) async {
    final db = await dbHelper.database;
    Map<String, dynamic> chapterMap = chapter.toMap();
    chapterMap['book_id'] = bookId;
    return await db.insert('chapters', chapterMap);
  }

  Future<List<BookChapter>> getChaptersForBook(int bookId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'start_page ASC',
    );
    return List.generate(maps.length, (i) {
      return BookChapter.fromMap(maps[i]);
    });
  }

  Future<int> updateChapter(BookChapter chapter, int bookId) async {
    final db = await dbHelper.database;
    Map<String, dynamic> chapterMap = chapter.toMap();
    chapterMap['book_id'] = bookId;
    return await db.update(
      'chapters',
      chapterMap,
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }
}
