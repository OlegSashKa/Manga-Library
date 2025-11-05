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

  // Удалить мангу
  Future<void> removeManga(String mangaId) async {
    await _mangaDao.deleteManga(mangaId);
  }
}