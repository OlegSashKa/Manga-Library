import 'package:flutter/material.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class Book {
  int? id;
  String title;      // Название книги

  String author;    // Автор (может не быть)

  // ТИП КНИГИ (манга или текст)
  BookType bookType;       // 'manga' или 'text'

  // ИНФОРМАЦИЯ О ФАЙЛЕ (где живет книга)
  String filePath;   // Путь к файлу на телефоне(скопированый файл в папке приложения)
  String fileFormat; // Формат: cbz, epub, txt и т.д.
  int fileSize;      // Размер файла

  // ПРОГРЕСС ЧТЕНИЯ (на какой странице остановились)
  int currentPage;   // Текущая страница
  int totalPages;    // Всего страниц
  double progress;   // Прогресс в процентах (0.0 до 1.0)

  // ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ
  String? coverImagePath; // Путь к обложке
  BookStatus status;          // Статус: 'reading', 'planned', 'completed'
  DateTime addedDate;     // Когда добавили книгу
  DateTime lastDateOpen;     // Дата последнего открытия
  Duration readingTime;
  bool isFavorite;        // В избранном или нет
  List<String> tags;

  List<BookChapter> chapters;
  int currentChapterIndex;

  bool get hasReadingProgress => currentPage > 0;
  String get actionButtonText => hasReadingProgress ? 'ПРОДОЛЖИТЬ' : 'НАЧАТЬ';

  Book({
    this.id,              // id может не быть при создании новой книги
    required this.title,
    this.author = 'Неизвестен',
    required this.bookType,
    required this.filePath,
    required this.fileFormat,
    required this.fileSize,
    this.currentPage = 0,
    this.totalPages = 0,
    this.chapters = const [],
    this.currentChapterIndex = 0,
    this.progress = 0.0,
    this.coverImagePath,
    this.status = BookStatus.planned,
    required this.addedDate,
    required this.lastDateOpen,
    this.readingTime = Duration.zero,
    this.isFavorite = false,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    final map =  <String, dynamic>{
      'title': title,
      'author': author,
      'bookType': bookType.name,
      'file_path': filePath,
      'file_format': fileFormat,
      'file_size': fileSize,
      'current_page': currentPage,
      'total_pages': totalPages,
      'progress': progress,
      'cover_image_path': coverImagePath,
      'status': status.name,
      'added_date': addedDate.millisecondsSinceEpoch,
      'last_date_open': lastDateOpen.millisecondsSinceEpoch,
      'reading_time': readingTime.inMilliseconds,
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags.join(','),
      'current_chapter_index': currentChapterIndex,
      // chapters нужно сохранять отдельно, так как это список объектов
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'] ?? 'Неизвестен',
      bookType: BookType.values.firstWhere(
            (bookType) => bookType.name == map['bookType'],
        orElse: () => BookType.text, // По умолчанию текстовая
      ),
      filePath: map['file_path'],
      fileFormat: map['file_format'],
      fileSize: map['file_size'],
      currentPage: map['current_page'],
      totalPages: map['total_pages'],
      progress: map['progress'],
      coverImagePath: map['cover_image_path'],
      status: BookStatus.values.firstWhere(
            (status) => status.name == map['status'],
        orElse: () => BookStatus.planned, // Если не нашли - ставим по умолчанию
      ),
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['added_date']),
      lastDateOpen: DateTime.fromMillisecondsSinceEpoch(map['last_date_open']),
      readingTime: Duration(milliseconds: map['reading_time'] ?? 0),
      isFavorite: map['is_favorite'] == 1,
      tags: map['tags']?.toString().split(',') ?? [],
      currentChapterIndex: map['current_chapter_index'] ?? 0,
      // chapters нужно загружать отдельно
    );
  }

  Color get statusColor {
    switch (status) {
      case BookStatus.reading:
        return Colors.green;
      case BookStatus.completed:
        return Colors.purple;
      case BookStatus.paused:
        return Colors.orange;
      case BookStatus.planned:
        return Colors.blue;
    }
  }

// И метод для красивого названия статуса:
  String get statusDisplayName {
    switch (status) {
      case BookStatus.reading:
        return 'Читаю';
      case BookStatus.planned:
        return 'В планах';
      case BookStatus.completed:
        return 'Прочитано';
      case BookStatus.paused:
        return 'Отложено';
    }
  }

   String getBookType(){
    switch (bookType.name) {
      case BookType.manga:
        return 'Манга';
      case BookType.text:
        return 'Текстовая';
      default:
        return 'Текстовая';
    }
  }
}

class BookChapter {
  int? id;
  String title;
  int startPage;      // С какой страницы начинается
  int? endPage;       // На какой заканчивается (опционально)
  int currentPage;    // Текущая страница в главе
  bool isRead;        // Прочитана ли глава
  Duration? readTime; // Время чтения главы

  BookChapter({
    this.id,
    required this.title, // Сделано обязательным
    required this.startPage, // Сделано обязательным
    this.endPage,
    this.currentPage = 0,
    this.isRead = false,
    this.readTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_page': startPage,
      'end_page': endPage,
      'current_page': currentPage,
      'is_read': isRead ? 1 : 0,
      'read_time': readTime?.inMilliseconds,
    };
  }

  factory BookChapter.fromMap(Map<String, dynamic> map) {
    return BookChapter(
      id: map['id'],
      title: map['title'],
      startPage: map['start_page'],
      endPage: map['end_page'],
      currentPage: map['current_page'] ?? 0,
      isRead: map['is_read'] == 1,
      readTime: map['read_time'] != null
          ? Duration(milliseconds: map['read_time'])
          : null,
    );
  }
}