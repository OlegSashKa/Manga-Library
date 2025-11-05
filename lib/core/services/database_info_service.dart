import '../../domain/models/manga.dart';
import '../../core/repositories/manga_repository.dart';

class DatabaseInfoService {
  final MangaRepository _mangaRepository;

  DatabaseInfoService(this._mangaRepository);

  Future<DatabaseInfo> getDatabaseInfo() async {
    try {
      final allMangas = await _mangaRepository.loadManga();

      final totalPages = allMangas.fold(0, (sum, manga) => sum + manga.totalPages);
      final readPages = allMangas.fold(0, (sum, manga) => sum + manga.currentPage);
      final progress = totalPages > 0 ? readPages / totalPages : 0.0;

      // Статистика по статусам
      final statusStats = <String, int>{};
      for (final manga in allMangas) {
        statusStats[manga.status] = (statusStats[manga.status] ?? 0) + 1;
      }

      // Статистика по тегам
      final tagStats = <String, int>{};
      for (final manga in allMangas) {
        for (final tag in manga.tags) {
          tagStats[tag] = (tagStats[tag] ?? 0) + 1;
        }
      }

      return DatabaseInfo(
        mangaCount: allMangas.length,
        totalPages: totalPages,
        readPages: readPages,
        progress: progress,
        statusStats: statusStats,
        tagStats: tagStats,
        allMangas: allMangas,
      );
    } catch (e) {
      throw Exception('Ошибка получения информации о БД: $e');
    }
  }

  void exportToConsole(List<Manga> mangas) {
    print('=== ЭКСПОРТ БАЗЫ ДАННЫХ ===');
    print('Всего манг: ${mangas.length}');
    print('---');

    for (final manga in mangas) {
      print('ID: ${manga.id}');
      print('Название: ${manga.title}');
      print('Автор: ${manga.author}');
      print('Том: ${manga.volume}');
      print('Статус: ${manga.status}');
      print('Прогресс: ${(manga.progress * 100).toStringAsFixed(1)}%');
      print('Страницы: ${manga.currentPage}/${manga.totalPages}');
      print('Теги: ${manga.tags.join(", ")}');
      print('---');
    }
  }
}

class DatabaseInfo {
  final int mangaCount;
  final int totalPages;
  final int readPages;
  final double progress;
  final Map<String, int> statusStats;
  final Map<String, int> tagStats;
  final List<Manga> allMangas;

  DatabaseInfo({
    required this.mangaCount,
    required this.totalPages,
    required this.readPages,
    required this.progress,
    required this.statusStats,
    required this.tagStats,
    required this.allMangas,
  });
}