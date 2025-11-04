import '../../domain/models/manga.dart';

class MockData {
  static List<Manga> getMockManga() {
    final now = DateTime.now();

    return [
      Manga(
        id: '1',
        title: 'Наруто',
        author: 'Масаши Кишимото',
        coverUrl: '',
        volume: 1,
        progress: 0.6,
        tags: ['сёнэн', 'приключения', 'ниндзя'],
        status: 'Читаю',
        currentPage: 150,
        totalPages: 250,
        nextChapterDate: now.add(const Duration(days: 3)),
      ),
      Manga(
        id: '2',
        title: 'One Piece',
        author: 'Эйитиро Ода',
        coverUrl: '',
        volume: 104,
        progress: 0.8,
        tags: ['сёнэн', 'пираты', 'комедия'],
        status: 'Читаю',
        currentPage: 320,
        totalPages: 400,
        nextChapterDate: now.add(const Duration(days: 1)),
      ),
      Manga(
        id: '3',
        title: 'Токийский Гул',
        author: 'Суи Ишида',
        coverUrl: '',
        volume: 1,
        progress: 0.2,
        tags: ['сэйнэн', 'ужасы', 'драма'],
        status: 'В планах',
        currentPage: 50,
        totalPages: 250,
        nextChapterDate: null,
      ),
      Manga(
        id: '4',
        title: 'Атака Титанов',
        author: 'Хадзиме Исаяма',
        coverUrl: '',
        volume: 34,
        progress: 0.9,
        tags: ['сэйнэн', 'фэнтези', 'экшен'],
        status: 'Прочитано',
        currentPage: 450,
        totalPages: 500,
        nextChapterDate: null,
      ),
    ];
  }

  static Manga getMangaById(String id) {
    return getMockManga().firstWhere((manga) => manga.id == id);
  }
}