import '../../domain/models/book.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class MockData {
  static List<Book> getMockManga() {
    return [
      Book(
        id: 1,
        title: 'Test book',
        author: 'Alexandr OlegSashka',
        bookType: BookType.manga,
        filePath: '',
        fileFormat: 'pdf',
        fileSize: 0,
        currentChapterIndex: 0,
        currentPage: 0,
        totalPages: 0,
        progress: 0,
        status: BookStatus.planned,
        tags: ['текстовая','тестовая'],
        addedDate: DateTime.now(),
        lastDateOpen: DateTime.now(),
        readingTime: Duration(hours: 99, minutes: 60, seconds: 60),
      ),
    ];
  }

  List<BookChapter> get testChapters {
    return [];
  }

  static Book getMangaById(int id) {
    return getMockManga().firstWhere((manga) => manga.id == id);
  }
}