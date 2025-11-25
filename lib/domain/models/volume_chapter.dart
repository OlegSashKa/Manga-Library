
import 'package:mangalibrary/enums/book_enums.dart';

class VolumeChapter {
  int? id;
  int bookId; // ID книги, к которой относится глава
  String title;
  int startPage;      // С какой страницы начинается
  int? endPage;       // На какой заканчивается (опционально)
  int currentPage;    // Текущая страница в главе
  BookStatus isRead;        // Прочитана ли глава
  Duration? readTime; // Время чтения главы
  int position;       // Порядковый номер главы

  VolumeChapter({
    this.id,
    required this.bookId,
    required this.title, // Сделано обязательным
    required this.startPage, // Сделано обязательным
    this.endPage,
    this.currentPage = 0,
    this.isRead = BookStatus.planned,
    this.readTime,
    required this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'title': title,
      'start_page': startPage,
      'end_page': endPage,
      'current_page': currentPage,
      'is_read': isRead.name,
      'read_time': readTime?.inMilliseconds,
      'position': position,
    };
  }

  factory VolumeChapter.fromMap(Map<String, dynamic> map) {
    return VolumeChapter(
      id: map['id'],
      bookId: map['book_id'],
      title: map['title'],
      startPage: map['start_page'],
      endPage: map['end_page'],
      currentPage: map['current_page'] ?? 0,
      isRead: BookStatus.values.firstWhere(
            (status) => status.name == map['status'],
        orElse: () => BookStatus.planned, // Если не нашли - ставим по умолчанию
      ),
      readTime: map['read_time'] != null
          ? Duration(milliseconds: map['read_time'])
          : null,
      position: map['position'] ?? 0,
    );
  }


  double get progress {
    if (endPage == null || endPage == startPage) return 0.0;
    final totalPagesInChapter = endPage! - startPage + 1;
    final pagesReadInChapter = currentPage - startPage;
    return pagesReadInChapter / totalPagesInChapter;
  }

  int? get totalPagesInChapter {
    if (endPage == null) return null;
    return endPage! - startPage + 1;
  }
}