import 'package:mangalibrary/domain/models/book_volume.dart'; // <-- НУЖНЫЙ ИМПОРТ
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import '../../domain/models/book.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class MockData {

  // 1. Создаем тестовые Главы
  static List<VolumeChapter> get _mockChapters {
    return [
      VolumeChapter(
        volumeId: 1, // ID будет присвоен при сохранении, здесь просто для примера
        title: 'Глава 1: Вступление',
        startPage: 1,
        endPage: 15,
        position: 1,
          fileFolderPath: ''
      ),
      VolumeChapter(
        volumeId: 1,
        title: 'Глава 2: Развитие',
        startPage: 16,
        endPage: 30,
        position: 2,
          fileFolderPath: ''
      ),
      VolumeChapter(
        volumeId: 2,
        title: 'Глава 3: Развязка',
        startPage: 31,
        endPage: 50,
        position: 1,
          fileFolderPath: ''
      ),
    ];
  }

  // 2. Создаем тестовые Тома и связываем их с Главами
  static List<BookVolume> get _mockVolumes {
    final chapters = _mockChapters;

    // Том 1: Главы 1 и 2
    final volume1Chapters = chapters.where((c) => c.volumeId == 1).toList();

    // Том 2: Глава 3
    final volume2Chapters = chapters.where((c) => c.volumeId == 2).toList();

    final volumes = [
      BookVolume(
        bookId: 1,
        title: 'Том 1: Начало пути',
        number: 1,
        startPage: 1,
        endPage: 30,
        chapters: volume1Chapters,
      ),
      BookVolume(
        bookId: 1,
        title: 'Том 2: Завершение',
        number: 2,
        startPage: 31,
        endPage: 50,
        chapters: volume2Chapters,
      ),
    ];

    // 💡 Важно: Гидратация в Mock-данных
    // Устанавливаем обратные ссылки на родительские объекты, как мы договаривались.
    for (var volume in volumes) {
      // Устанавливаем book-ссылку позже (в _mockManga)
      for (var chapter in volume.chapters) {
        chapter.volume = volume;
      }
    }

    return volumes;
  }

  // 3. Создаем тестовые Книги и связываем их с Томами
  static List<Book> getMockManga() {
    final volumes = _mockVolumes;

    final book = Book(
      id: 1, // Присваиваем ID для тестовых целей
      title: 'Тестовая книга с Томами',
      author: 'Александр Олегович',
      bookType: BookType.manga,
      fileFolderPath: '',
      fileFormat: 'pdf',
      fileSize: 1024 * 1024 * 50, // 50MB

      // Прогресс: находимся на 35-й странице (внутри Тома 2, Глава 3)
      currentPage: 35,
      lastSymbolIndex: 0,
      totalPages: 50, // Общее количество страниц = конец последнего Тома

      coverImagePath: null,
      status: BookStatus.reading,
      addedDate: DateTime.now(),
      lastDateOpen: DateTime.now(),
      readingTime: Duration(hours: 1, minutes: 15),
      isFavorite: true,
      tags: ['манга', 'том', 'тест'],

      // 💡 ПЕРЕДАЕМ СПИСОК ТОМОВ
      volumes: volumes,
    );

    // 💡 Гидратация: Устанавливаем ссылку на книгу в томах
    for(var volume in book.volumes) {
      volume.book = book;
    }

    return [book];
  }

  // ... (остальные методы)

  static Book getMangaById(int id) {
    return getMockManga().firstWhere((manga) => manga.id == id);
  }
}