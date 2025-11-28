import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import 'package:mangalibrary/enums/book_enums.dart';
import 'package:path/path.dart' as path;

class Book {
  int? id;
  String title; // Название книги
  String author; // Автор (может не быть)
  // ТИП КНИГИ (манга или текст)
  BookType bookType; // 'manga' или 'text'
  // ИНФОРМАЦИЯ О ФАЙЛЕ (где живет книга)
  String fileFolderPath;
  String fileFormat; // Формат: cbz, epub, txt и т.д.
  int fileSize; // Размер файла
  // ПРОГРЕСС ЧТЕНИЯ (на какой странице остановились)
  int currentPage; // Текущая страница
  int lastSymbolIndex;
  int totalPages; // Всего страниц
  // ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ
  String? coverImagePath; // Путь к обложке
  BookStatus status; // Статус: 'reading', 'planned', 'completed'
  DateTime addedDate; // Когда добавили книгу
  DateTime lastDateOpen; // Дата последнего открытия
  Duration readingTime;
  bool isFavorite; // В избранном или нет
  List<String> tags;
  List<BookVolume> volumes;

  bool get hasReadingProgress => currentPage > 0;
  String get actionButtonText => hasReadingProgress ? 'ПРОДОЛЖИТЬ' : 'НАЧАТЬ';
  double get getProgress => totalPages != 0 ? (currentPage / totalPages) : 0;
  // fileFolderPath путь к корневой папке кигин (Например: /storage/.../books/Моя_Книга/)

  String getVolumeFolderPath({required String volumeTitle}) {
    final safeVolumeTitle = FileService.safePathName(volumeTitle);
    return path.join(fileFolderPath, safeVolumeTitle);
  }

  // 💡 Метод для построения пути к папке Главы
// Путь: [AppRoot]/books/Моя_Книга/Том 1/Глава 1/
  String getChapterFolderPath({
    required String volumeTitle,
    required String chapterTitle
  }) {
    final safeVolumeTitle = FileService.safePathName(volumeTitle);
    final safeChapterTitle = FileService.safePathName(chapterTitle);

    // Объединяем корневой путь книги, название тома и название главы
    return path.join(fileFolderPath, safeVolumeTitle, safeChapterTitle);
  }

  // 💡 Метод для построения пути к конкретному файлу TXT внутри папки Главы
// Путь: [AppRoot]/books/Моя_Книга/Том 1/Глава 1/segment_1.txt
  String getChapterFilePath({
    required String volumeTitle,
    required String chapterTitle,
    int fileIndex = 1 // Для сегментации, по умолчанию 1
  }) {
    final chapterFolder = getChapterFolderPath(
        volumeTitle: volumeTitle,
        chapterTitle: chapterTitle
    );

    // Имя файла: segment_N.txt (для простоты)
    return path.join(chapterFolder, 'segment_$fileIndex.txt');
  }

  BookVolume? get currentVolume {
    for (final volume in volumes) {
      if (currentPage >= volume.startPage &&
          (volume.endPage == null || currentPage <= volume.endPage!)) {
        return volume;
      }
    }
    return null;
  }

  VolumeChapter? get currentChapter {
    final volume = currentVolume;
    if (volume == null) return null;

    for (final chapter in volume.chapters) {
      if (currentPage >= chapter.startPage &&
          (chapter.endPage == null || currentPage <= chapter.endPage!)) {
        return chapter;
      }
    }
    return null;
  }

  Book({
    this.id, // id может не быть при создании новой книги
    required this.title,
    this.author = 'Неизвестен',
    required this.bookType,
    required this.fileFolderPath,
    required this.fileFormat,
    required this.fileSize,
    this.currentPage = 0,
    this.lastSymbolIndex = 0,
    this.totalPages = 1,
    this.coverImagePath,
    this.status = BookStatus.planned,
    required this.addedDate,
    required this.lastDateOpen,
    this.readingTime = Duration.zero,
    this.isFavorite = false,
    this.tags = const [],
    this.volumes = const [],
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'author': author,
      'bookType': bookType.name,
      'file_folder_path': fileFolderPath,
      'file_format': fileFormat,
      'file_size': fileSize,
      'current_page': currentPage,
      'total_pages': totalPages,
      'last_symbol_index': lastSymbolIndex,
      'cover_image_path': coverImagePath,
      'status': status.name,
      'added_date': addedDate.millisecondsSinceEpoch,
      'last_date_open': lastDateOpen.millisecondsSinceEpoch,
      'reading_time': readingTime.inMilliseconds,
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags.isNotEmpty ? tags.join(',') : null,
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
      fileFolderPath: map['file_folder_path'],
      fileFormat: map['file_format'],
      fileSize: map['file_size'],
      currentPage: map['current_page'],
      lastSymbolIndex: map['last_symbol_index'] ?? 0,
      totalPages: map['total_pages'],
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

  static String getBookTypeByName(BookType bookTypeName) {
    switch (bookTypeName) {
      case BookType.manga:
        return 'Манга';
      case BookType.text:
        return 'Текстовая';
      default:
        return 'Текстовая';
    }
  }

  String getBookType() {
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
