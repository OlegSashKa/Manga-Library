// Выносим в отдельный виджет
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BookTags extends StatelessWidget {
  final List<String> tags;

  const BookTags({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return SizedBox.shrink();

    final displayTags = tags.take(2).toList();
    final hasMoreTags = tags.length > 2;

    return Wrap(
      spacing: 3,
      runSpacing: 1,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...displayTags.map((tag) => Container(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1), // ← Минимальный вертикальный паддинг
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue[100]!, width: 1),
          ),

          child: Text(
            '#${tag.length > 12 ? '${tag.substring(0, 12)}...' : tag}',
            style: TextStyle(
              fontSize: 8,
              color: Colors.blue[800],
              height: 2, // ← Убираем лишнюю высоту
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),

        // Счётчик оставшихся тегов
        if (hasMoreTags)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: BoxConstraints(
              maxHeight: 16,
            ),
            child: Text(
              '+${tags.length - 2}',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[700],
                height: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}