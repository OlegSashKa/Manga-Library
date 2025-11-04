class Manga {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int volume;
  final double progress;
  final List<String> tags;
  final String status;
  final int currentPage;
  final int totalPages;
  final DateTime? nextChapterDate;

  Manga({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.volume,
    required this.progress,
    required this.tags,
    required this.status,
    required this.currentPage,
    required this.totalPages,
    this.nextChapterDate,
  });
}