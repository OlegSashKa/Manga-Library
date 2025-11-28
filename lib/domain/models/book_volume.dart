import 'package:flutter/material.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class BookVolume {
  int? id; // Primary Key
  int bookId; // Foreign Key
  Book? book;
  String title; // Название тома, например "Том 1"
  String? fileFolderPath;
  int number; // Порядковый номер тома, для сортировки

  int startPage; // Начальная страница тома в общей нумерации книги
  int? endPage; // Конечная страница тома
  List<VolumeChapter> chapters; // Список глав в этом томе — только для модели в коде, не для базы данных

  BookVolume({
    this.id,
    required this.bookId, // id может не быть при создании новой книги
    this.book,
    required this.title,
    required this.number,
    this.fileFolderPath,
    required this.startPage,
    this.endPage,
    this.chapters = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'title': title,
      'number': number,
      'file_folder_path': fileFolderPath,
      'start_page': startPage,
      'end_page': endPage,
    };
  }

  factory BookVolume.fromMap(Map<String, dynamic> map) {
    return BookVolume(
      id: map['id'] ?? 0,
      bookId: map['book_id'],
      title: map['title'],
      number: map['number'],
      fileFolderPath: map['file_folder_path'],
      startPage: map['start_page'],
      endPage: map['end_page'] ?? 0,
    );
  }
}
