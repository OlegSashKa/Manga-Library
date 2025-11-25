import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import '../../../domain/models/book.dart';

class ChapterTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertChapter(VolumeChapter chapter) async {
    final db = await _dbHelper.database;
    return await db.insert('chapters', chapter.toMap());
  }

  Future<void> insertChapters(List<VolumeChapter> chapters, int bookId) async {
    final db = await _dbHelper.database;

    // Создаем батч для более быстрой вставки
    final batch = db.batch();

    for (final chapter in chapters) {
      // Устанавливаем корректный bookId перед вставкой
      chapter.bookId = bookId;

      batch.insert('chapters', chapter.toMap());
    }

    // Выполняем все операции вставки
    await batch.commit(noResult: true);
    // print('✅ [CHAPTER_TABLE] Успешно вставлено ${chapters.length} глав для книги ID: $bookId');
  }

  Future<List<VolumeChapter>> getChaptersByBookId(int bookId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'position ASC', // Сортируем по порядку
    );

    return maps.map((map) => VolumeChapter.fromMap(map)).toList();
  }

  Future<VolumeChapter?> getChapter(int chapterId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'id = ?',
      whereArgs: [chapterId],
    );

    if (maps.isNotEmpty) {
      return VolumeChapter.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateChapter(VolumeChapter chapter) async {
    final db = await _dbHelper.database;
    return await db.update(
      'chapters',
      chapter.toMap(),
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  Future<void> updateChapters(List<VolumeChapter> chapters) async {
    final db = await _dbHelper.database;

    // Используем батч для повышения производительности
    final batch = db.batch();

    for (final chapter in chapters) {
      // Обновляем главу по ее ID
      if (chapter.id != null) {
        batch.update(
          'chapters',
          chapter.toMap(),
          where: 'id = ?',
          whereArgs: [chapter.id],
        );
      }
    }
    // Выполняем все операции обновления
    await batch.commit(noResult: true);
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

  Future<VolumeChapter?> getCurrentChapter(int bookId, int currentPage) async {
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
