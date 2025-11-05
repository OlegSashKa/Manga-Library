import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/local/dao/manga_dao.dart';
import '../../domain/models/manga.dart';

class MangaRepository {
  final MangaDao _mangaDao = MangaDao();

  // Загрузить все манги из БД
  Future<List<Manga>> loadManga() async {
    try {
      return await _mangaDao.getAllManga();
    } catch (e) {
      print('Ошибка загрузки манги: $e');
      return [];
    }
  }

  // Сохранить мангу в БД
  Future<void> saveManga(Manga manga) async {
    await _mangaDao.insertManga(manga);
  }

  // Обновить прогресс чтения
  Future<void> updateReadingProgress(String mangaId, double progress, int currentPage) async {
    await _mangaDao.updateProgress(mangaId, progress, currentPage);
  }

  Future<void> exportDatabaseToDownloads() async {
    try {
      final databasesPath = await getDatabasesPath();
      final sourcePath = join(databasesPath, 'manga_library.db');

      final externalDir = await getExternalStorageDirectory();
      final destPath = join(externalDir!.path, 'manga_library_backup.db');

      // Копируем файл
      await File(sourcePath).copy(destPath);

      print('База данных экспортирована: $destPath');
    } catch (e) {
      print('Ошибка экспорта: $e');
    }
  }

  // Удалить мангу
  Future<void> removeManga(String mangaId) async {
    await _mangaDao.deleteManga(mangaId);
  }
}