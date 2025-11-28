
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class VolumeChapter {
  int? id;
  int volumeId; // Foreign Key к новой таблице volumes
  BookVolume? volume;
  String title;
  int startPage;      // С какой страницы начинается
  int? endPage;       // На какой заканчивается (опционально)
  BookStatus isRead;        // Прочитана ли глава
  Duration? readTime; // Время чтения главы
  int position;       // Порядковый номер главы
  String fileFolderPath;

  Book? get book => volume?.book;
  int? get bookId => volume?.bookId;

  int get pageInChapter {
    if (book == null) return 0;
    // Текущая страница в главе = текущая страница книги - начальная страница главы + 1
    // Но ограничиваем диапазоном от 1 до общего количества страниц в главе
    final currentInChapter = book!.currentPage - startPage + 1;
    final totalInChapter = totalPagesInChapter ?? 1;
    return currentInChapter.clamp(1, totalInChapter);
  }

  VolumeChapter({
    this.id,
    required this.volumeId,
    this.volume,
    required this.title,
    required this.startPage,
    this.endPage,
    this.isRead = BookStatus.planned,
    this.readTime,
    required this.position,
    required this.fileFolderPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volume_id': volumeId,
      'title': title,
      'start_page': startPage,
      'end_page': endPage,
      'is_read': isRead.name,
      'read_time': readTime?.inMilliseconds,
      'position': position,
      'file_folder_path': fileFolderPath,
    };
  }

  factory VolumeChapter.fromMap(Map<String, dynamic> map) {
    return VolumeChapter(
      id: map['id'],
      volumeId: map['volume_id'],
      title: map['title'],
      startPage: map['start_page'],
      endPage: map['end_page'],
      isRead: BookStatus.values.firstWhere(
            (status) => status.name == map['is_read'],
        orElse: () => BookStatus.planned, // Если не нашли - ставим по умолчанию
      ),
      readTime: map['read_time'] != null
          ? Duration(milliseconds: map['read_time'])
          : null,
      position: map['position'] ?? 0,
      fileFolderPath: map['file_folder_path'] ?? '',
    );
  }


  double get progress {
    if (endPage == null || endPage == startPage) return 0.0;
    final totalPagesInChapter = endPage! - startPage + 1;
    final pagesReadInChapter = 1 - startPage; // pageInChapter
    return pagesReadInChapter / totalPagesInChapter;
  }

  int? get totalPagesInChapter {
    if (endPage == null) return null;
    return endPage! - startPage + 1;
  }
}