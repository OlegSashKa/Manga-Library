// Выносим в отдельный виджет
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BookTags extends StatelessWidget {
  final List<String> tags;

  const BookTags({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: tags.take(2).map((tag) => Chip(
        label: Text(tag, style: TextStyle(fontSize: 8)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      )).toList(),
    );
  }
}