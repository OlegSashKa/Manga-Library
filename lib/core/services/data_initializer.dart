import '../repositories/manga_repository.dart';
import '../../domain/models/manga.dart';
import '../data/mock_data.dart';

class DataInitializer {
  final MangaRepository _mangaRepository = MangaRepository();

  Future<void> initializeDefaultData() async {
    final existingManga = await _mangaRepository.loadManga();

    // Если БД пустая - загружаем данные из MockData
    if (existingManga.isEmpty) {
      final demoManga = MockData.getMockManga();

      for (final manga in demoManga) {
        await _mangaRepository.saveManga(manga);
      }

      print('✅ Загружено ${demoManga.length} демо-манги в БД');
    } else {
      print('✅ В БД уже есть ${existingManga.length} манг');
    }
  }
}