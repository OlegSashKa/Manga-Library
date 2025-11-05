import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../entities/manga_entity.dart';
import '../entities/manga_mapper.dart';
import '../../../domain/models/manga.dart';

class MangaDao {
  final AppDatabase _database = AppDatabase();

  // Добавить мангу
  Future<void> insertManga(Manga manga) async {
    final db = await _database.database;
    final entity = MangaMapper.toEntity(manga);
    await db.insert('manga', entity.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Получить все манги
  Future<List<Manga>> getAllManga() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query('manga');
    return maps.map((map) => MangaMapper.toModel(MangaEntity.fromMap(map))).toList();
  }

  // Получить мангу по ID
  Future<Manga?> getMangaById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'manga',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MangaMapper.toModel(MangaEntity.fromMap(maps.first));
    }
    return null;
  }

  // Обновить прогресс манги
  Future<void> updateProgress(String id, double progress, int currentPage) async {
    final db = await _database.database;
    await db.update(
      'manga',
      {'progress': progress, 'currentPage': currentPage},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Удалить мангу
  Future<void> deleteManga(String id) async {
    final db = await _database.database;
    await db.delete('manga', where: 'id = ?', whereArgs: [id]);
  }
}