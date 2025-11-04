import '../../domain/models/schedule.dart';

class MockScheduleData {
  static List<ScheduleItem> getMockSchedule() {
    final now = DateTime.now();

    return [
      // Сегодня
      ScheduleItem(
        id: '1',
        title: 'One Piece',
        chapter: 'Глава 1124',
        releaseDate: now,
        time: '12:00 JST',
        magazine: 'Shonen Jump',
        isToday: true,
        isTomorrow: false,
      ),
      // Завтра
      ScheduleItem(
        id: '2',
        title: 'My Hero Academia',
        chapter: 'Глава 412',
        releaseDate: now.add(const Duration(days: 1)),
        time: '09:00 JST',
        magazine: 'Shonen Jump',
        isToday: false,
        isTomorrow: true,
      ),
      // Послезавтра
      ScheduleItem(
        id: '3',
        title: 'Jujutsu Kaisen',
        chapter: 'Глава 255',
        releaseDate: now.add(const Duration(days: 2)),
        time: '14:00 JST',
        magazine: 'Jump GIGA',
        isToday: false,
        isTomorrow: false,
      ),
      // Будущие выходы
      ScheduleItem(
        id: '4',
        title: 'Chainsaw Man',
        chapter: 'Глава 169',
        releaseDate: now.add(const Duration(days: 5)),
        time: '10:00 JST',
        magazine: 'Shonen Jump+',
        isToday: false,
        isTomorrow: false,
      ),
      ScheduleItem(
        id: '5',
        title: 'Tokyo Revengers',
        chapter: 'Глава 245',
        releaseDate: now.add(const Duration(days: 8)),
        time: '11:00 JST',
        magazine: 'Magazine',
        isToday: false,
        isTomorrow: false,
      ),
      ScheduleItem(
        id: '6',
        title: 'Spy × Family',
        chapter: 'Глава 89',
        releaseDate: now.add(const Duration(days: 11)),
        time: '13:00 JST',
        magazine: 'Jump SQ',
        isToday: false,
        isTomorrow: false,
      ),
    ];
  }

  // Расписание на этой неделе
  static List<ScheduleItem> getThisWeekSchedule() {
    return getMockSchedule().where((item) {
      final difference = item.releaseDate.difference(DateTime.now()).inDays;
      return difference <= 7;
    }).toList();
  }

  // Будущие выходы (после этой недели)
  static List<ScheduleItem> getFutureSchedule() {
    return getMockSchedule().where((item) {
      final difference = item.releaseDate.difference(DateTime.now()).inDays;
      return difference > 7;
    }).toList();
  }
}