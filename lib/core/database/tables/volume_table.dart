import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';

class VolumesTable {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertVolume(BookVolume volume) async {
    final db = await _dbHelper.database;
    return await db.insert('volumes', volume.toMap());
  }

  Future<void> insertVolumes(List<BookVolume> volumes, int bookId) async {
    final db = await _dbHelper.database;

    for (final volume in volumes) {
      volume.bookId = bookId;

      // ✅ ВСТАВЛЯЕМ КАЖДЫЙ ТОМ ОТДЕЛЬНО И ПОЛУЧАЕМ ID
      final volumeId = await db.insert('volumes', volume.toMap());
      volume.id = volumeId; // ⚠️ КРИТИЧЕСКИ ВАЖНО!
    }
  }

  Future<List<BookVolume>> getVolumesByBookId(int bookId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'volumes',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'number ASC', // Сортируем по порядковому номеру тома
    );

    return maps.map((map) => BookVolume.fromMap(map)).toList();
  }

  Future<int> updateVolume(BookVolume volume) async {
    final db = await _dbHelper.database;
    return await db.update(
      'volumes',
      volume.toMap(),
      where: 'id = ?',
      whereArgs: [volume.id],
    );
  }

  Future<void> updateVolumes(List<BookVolume> volumes) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final volume in volumes) {
      if (volume.id != null) {
        batch.update(
          'volumes',
          volume.toMap(),
          where: 'id = ?',
          whereArgs: [volume.id],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<int> deleteVolumesByBookId(int bookId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'volumes',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }
}