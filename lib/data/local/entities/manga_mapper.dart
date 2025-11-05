import 'dart:convert';
import '../../../domain/models/manga.dart'; // путь к Manga
import 'manga_entity.dart'; // путь к MangaEntity (в той же папке)

class MangaMapper {
  // Конвертация Manga → MangaEntity (для сохранения в БД)
  static MangaEntity toEntity(Manga manga) {
    return MangaEntity(
      id: manga.id,
      title: manga.title,
      author: manga.author,
      coverUrl: manga.coverUrl,
      volume: manga.volume,
      progress: manga.progress,
      tagsJson: jsonEncode(manga.tags), // List → JSON
      status: manga.status,
      currentPage: manga.currentPage,
      totalPages: manga.totalPages,
      nextChapterTimestamp: manga.nextChapterDate?.millisecondsSinceEpoch,
      type: manga.type,
      createdAtTimestamp: manga.createdAt.millisecondsSinceEpoch,
    );
  }

  // Конвертация MangaEntity → Manga (для использования в UI)
  static Manga toModel(MangaEntity entity) {
    return Manga(
      id: entity.id,
      title: entity.title,
      author: entity.author,
      coverUrl: entity.coverUrl,
      volume: entity.volume,
      progress: entity.progress,
      tags: List<String>.from(jsonDecode(entity.tagsJson)), // JSON → List
      status: entity.status,
      currentPage: entity.currentPage,
      totalPages: entity.totalPages,
      nextChapterDate: entity.nextChapterTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(entity.nextChapterTimestamp!)
          : null,
      type: entity.type,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAtTimestamp),
    );
  }
}