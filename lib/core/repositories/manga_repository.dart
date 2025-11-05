import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:downloadsfolder/downloadsfolder.dart';
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

  Future<String> exportDatabaseToDownloads() async {
    try {
      final databasesPath = await getDatabasesPath();
      final sourcePath = join(databasesPath, 'manga_library.db');

      // Получаем корневую папку Download
      final downloadDirectory = await getDownloadDirectory();
      if (downloadDirectory == null) {
        throw Exception('Не удалось получить папку Download');
      }

      // Создаем папку приложения внутри Download
      final appFolder = Directory(join(downloadDirectory.path, 'MangaLibrary'));
      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }

      final destPath = join(appFolder.path, 'manga_library_backup.db');

      // Копируем файл
      await File(sourcePath).copy(destPath);

      print('База данных экспортирована: $destPath');
      return destPath;
    } catch (e) {
      print('Ошибка экспорта: $e');
      throw e;
    }
  }

  // Удалить мангу
  Future<void> removeManga(String mangaId) async {
    await _mangaDao.deleteManga(mangaId);
  }
}