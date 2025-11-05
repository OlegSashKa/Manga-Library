import 'package:flutter/material.dart';
import '../../domain/models/manga.dart';

class MangaDetailsScreen extends StatelessWidget {
  final Manga manga;
  final VoidCallback onDelete;

  const MangaDetailsScreen({
    super.key,
    required this.manga,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(manga.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
              const PopupMenuItem(value: 'delete', child: Text('Удалить')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Обложка и основная информация
            _buildCoverAndInfo(),
            const SizedBox(height: 24),

            // Кнопка продолжения чтения
            _buildContinueButton(context),
            const SizedBox(height: 24),

            // Информация
            _buildInfoSection(),
            const SizedBox(height: 24),

            // Главы
            _buildChaptersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverAndInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Обложка
        Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 50,
            color: Colors.deepPurple.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 16),

        // Информация
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              _buildInfoRow('👤 Автор:', manga.author),
              const SizedBox(height: 4),

              _buildInfoRow('🏷️ Статус:', manga.status),
              const SizedBox(height: 4),

              _buildInfoRow('📊 Прогресс:',
                  '${manga.currentPage}/${manga.totalPages} стр. (${(manga.progress * 100).toInt()}%)'),
              const SizedBox(height: 8),

              // Теги
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: manga.tags.map((tag) => Chip(
                  label: Text(
                    '#$tag',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _openReader(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ПРОДОЛЖИТЬ ЧТЕНИЕ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ИНФОРМАЦИЯ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (manga.nextChapterDate != null) ...[
          _buildNextChapterInfo(),
          const SizedBox(height: 12),
        ],

        _buildTagsInfo(),
      ],
    );
  }

  Widget _buildNextChapterInfo() {
    final nextChapter = manga.nextChapterDate!;
    final now = DateTime.now();
    final difference = nextChapter.difference(now);
    final daysLeft = difference.inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              'Следующая глава:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatDate(nextChapter)} (через $daysLeft ${_getDayText(daysLeft)})',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_offer, size: 16, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              'Теги:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          manga.tags.map((tag) => '#$tag').join(' '),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ГЛАВЫ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Список глав
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) => _buildChapterItem(index + 1),
        ),
      ],
    );
  }

  Widget _buildChapterItem(int chapterNumber) {
    final isRead = chapterNumber < 3;
    final isCurrent = chapterNumber == 3;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.deepPurple
              : Colors.grey.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRead ? Icons.check : Icons.menu_book,
          color: isCurrent ? Colors.white : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        'Глава $chapterNumber',
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent ? Colors.deepPurple : Colors.black87,
        ),
      ),
      subtitle: Text(
        isRead ? 'прочитано' :
        isCurrent ? 'текущая' : 'не прочитано',
        style: TextStyle(
          color: isCurrent ? Colors.deepPurple : Colors.grey,
        ),
      ),
      trailing: isCurrent ? const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.deepPurple,
      ) : null,
      onTap: () => _openChapter(chapterNumber),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getDayText(int days) {
    if (days == 1) return 'день';
    if (days >= 2 && days <= 4) return 'дня';
    return 'дней';
  }

  void _handleMenuAction(String value, BuildContext context) {
    switch (value) {
      case 'edit':
        print('Редактировать: ${manga.title}');
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
      case 'share':
        print('Поделиться: ${manga.title}');
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мангу?'),
        content: Text('Вы уверены, что хотите удалить "${manga.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('УДАЛИТЬ'),
          ),
        ],
      ),
    );
  }

  void _openReader(BuildContext context) {
    // TODO: Переход на экран читалки
    print('Открываем читалку для: ${manga.title}');
  }

  void _openChapter(int chapterNumber) {
    // TODO: Переход на чтение конкретной главы
    print('Открываем главу $chapterNumber: ${manga.title}');
  }
}