import 'package:flutter/material.dart';
import '../../core/data/mock_schedule_data.dart';
import '../../domain/models/schedule.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final thisWeekSchedule = MockScheduleData.getThisWeekSchedule();
    final futureSchedule = MockScheduleData.getFutureSchedule();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('📅 Расписание'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Токийское время
            _buildTokyoTime(),
            const SizedBox(height: 24),

            // На этой неделе
            _buildScheduleSection(
              title: 'НА ЭТОЙ НЕДЕЛЕ',
              schedule: thisWeekSchedule,
            ),
            const SizedBox(height: 24),

            // Будущие выходы
            _buildScheduleSection(
              title: 'БУДУЩИЕ ВЫХОДЫ',
              schedule: futureSchedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokyoTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🗾 Токийское время: $hour:$minute',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Сегодня: ${_formatDate(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection({
    required String title,
    required List<ScheduleItem> schedule,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (schedule.isEmpty)
          const Text(
            'Нет запланированных выходов',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...schedule.map((item) => _buildScheduleItem(item)).toList(),
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконка статуса
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor(item),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(item),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayLabel(item),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(item),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.chapter,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.menu_book, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.magazine,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (!item.isToday && !item.isTomorrow) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.daysLeft,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(ScheduleItem item) {
    if (item.isToday) return '🔥 Сегодня';
    if (item.isTomorrow) return '📖 Завтра';
    return '🎯 ${_formatDate(item.releaseDate)}';
  }

  Color _getStatusColor(ScheduleItem item) {
    if (item.isToday) return Colors.red;
    if (item.isTomorrow) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(ScheduleItem item) {
    if (item.isToday) return Icons.flash_on;
    if (item.isTomorrow) return Icons.today;
    return Icons.calendar_today;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}