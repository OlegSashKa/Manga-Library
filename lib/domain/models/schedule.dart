class ScheduleItem {
  final String id;
  final String title;
  final String chapter;
  final DateTime releaseDate;
  final String time;
  final String magazine;
  final bool isToday;
  final bool isTomorrow;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.chapter,
    required this.releaseDate,
    required this.time,
    required this.magazine,
    required this.isToday,
    required this.isTomorrow,
  });

  String get daysLeft {
    final now = DateTime.now();
    final difference = releaseDate.difference(now);
    final days = difference.inDays;

    if (days == 0) return 'Сегодня';
    if (days == 1) return 'Завтра';
    return 'Через $days ${_getDayText(days)}';
  }

  String _getDayText(int days) {
    if (days == 1) return 'день';
    if (days >= 2 && days <= 4) return 'дня';
    return 'дней';
  }
}