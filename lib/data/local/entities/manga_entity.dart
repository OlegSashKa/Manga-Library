class MangaEntity {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int volume;
  final double progress;
  final String tagsJson; // Храним теги как JSON строку
  final String status;
  final int currentPage;
  final int totalPages;
  final int? nextChapterTimestamp; // DateTime как timestamp
  final String type;
  final int createdAtTimestamp;

  MangaEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.volume,
    required this.progress,
    required this.tagsJson,
    required this.status,
    required this.currentPage,
    required this.totalPages,
    this.nextChapterTimestamp,
    required this.type,
    required this.createdAtTimestamp,
  });

  // Конвертация в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'volume': volume,
      'progress': progress,
      'tagsJson': tagsJson,
      'status': status,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'nextChapterTimestamp': nextChapterTimestamp,
      'type': type,
      'createdAtTimestamp': createdAtTimestamp,
    };
  }

  // Создание из Map (из SQLite)
  factory MangaEntity.fromMap(Map<String, dynamic> map) {
    return MangaEntity(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      coverUrl: map['coverUrl'],
      volume: map['volume'],
      progress: map['progress'],
      tagsJson: map['tagsJson'],
      status: map['status'],
      currentPage: map['currentPage'],
      totalPages: map['totalPages'],
      nextChapterTimestamp: map['nextChapterTimestamp'],
      type: map['type'],
      createdAtTimestamp: map['createdAtTimestamp'],
    );
  }
}