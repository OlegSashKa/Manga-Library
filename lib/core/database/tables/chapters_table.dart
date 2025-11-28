import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import '../../../domain/models/book.dart';

class ChapterTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertChapter(VolumeChapter chapter) async {
    final db = await _dbHelper.database;
    return await db.insert('chapters', chapter.toMap());
  }

  Future<void> insertChapters(List<VolumeChapter> chapters, int volumeId) async {
    final db = await _dbHelper.database;

    final batch = db.batch();

    for (final chapter in chapters) {
      // 💡 ИЗМЕНЕНИЕ: Устанавливаем volumeId перед вставкой
      chapter.volumeId = volumeId;

      batch.insert('chapters', chapter.toMap());
    }

    await batch.commit(noResult: true);
    // print('✅ [CHAPTER_TABLE] Успешно вставлено ${chapters.length} глав для тома ID: $volumeId');
  }

  Future<List<VolumeChapter>> getChaptersByVolumeId(int volumeId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      // 💡 ИЗМЕНЕНИЕ: Запрос по volume_id
      where: 'volume_id = ?',
      whereArgs: [volumeId],
      orderBy: 'position ASC',
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

  Future<void> debugChapters() async {
    final db = await _dbHelper.database;
    final chapters = await db.query('chapters');
    final volumes = await db.query('volumes');

    print('🔍 DEBUG Chapters in DB: ${chapters.length}');
    print('🔍 DEBUG Volumes in DB: ${volumes.length}');

    for (final chapter in chapters) {
      print('🔍 Chapter: ${chapter['title']}, volume_id: ${chapter['volume_id']}');
    }

    for (final volume in volumes) {
      print('🔍 Volume: ${volume['title']}, id: ${volume['id']}, book_id: ${volume['book_id']}');
    }
  }


  //TODO незабыть узнать что делать с этим тоже
  Future<VolumeChapter?> getCurrentChapter(int bookId, int currentPage) async {
    // 💡 ИЗМЕНЕНИЕ: ЭТОТ МЕТОД НУЖНО РЕАЛИЗОВАТЬ ЧЕРЕЗ VolumesTable
    // Поскольку chapters теперь привязаны к volumes, нужен запрос сначала к volumes.
    // Пока оставим заглушку, либо переместим эту логику в сервис или BooksTable.
    // Для полноценной работы этот метод нужно переписать.
    // Временно удалим логику, чтобы не было ошибок, т.к. getChaptersByBookId удален
    // final chapters = await getChaptersByBookId(bookId); <-- ЭТОГО МЕТОДА БОЛЬШЕ НЕТ

    // Ищем главу, в диапазон которой попадает текущая страница
    // for (final chapter in chapters) {
    //   if (currentPage >= chapter.startPage &&
    //       (chapter.endPage == null || currentPage <= chapter.endPage!)) {
    //     return chapter;
    //   }
    // }

    return null;
  }

  Future<int> deleteChaptersByVolumeId(int volumeId) async {
    final db = await _dbHelper.database;
    // 💡 ИЗМЕНЕНИЕ: Удаление по volume_id
    return await db.delete(
      'chapters',
      where: 'volume_id = ?',
      whereArgs: [volumeId],
    );
  }
}
