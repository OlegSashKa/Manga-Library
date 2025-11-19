import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/app_globals.dart';

class TagInputWidget extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;
  final String? hintText;
  final String? labelText;

  const TagInputWidget({
    super.key,
    this.initialTags = const [],
    required this.onTagsChanged,
    this.hintText,
    this.labelText,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _tagInputController = TextEditingController();
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.initialTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ПОЛЕ ВВОДА ТЕГА + КНОПКА
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagInputController,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: widget.labelText ?? 'Введите тег',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tag),
                  hintText: widget.hintText ?? 'Например: фэнтези',
                  counterText:  "",
                ),
                onFieldSubmitted: (value) {
                  _addTagFromInput();
                },
                onChanged: (value) {
                  setState(() {
                    // Обновляем счётчик при вводе
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                onPressed: _addTagFromInput,
              ),
            ),
          ],
        ),
        // const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '* нажмите "+" чтобы добавить тег',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Spacer(),
            Text(
                '(${_tagInputController.text.length}/20)',
                style: TextStyle(fontSize: 12),
            )
          ],
        ),

        const SizedBox(height: 16),

        // ОТОБРАЖЕНИЕ ДОБАВЛЕННЫХ ТЕГОВ
        if (_tags.isNotEmpty) ...[
          Text(
            'Добавленные теги:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 2,
            runSpacing: 1,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue[50],
                deleteIcon: const Icon(Icons.close, size: 14),
                shape: RoundedRectangleBorder( // ← ДОБАВЛЯЕМ ФОРМУ
                  borderRadius: BorderRadius.circular(20), // ← РАДИУС СКРУГЛЕНИЯ
                  side: BorderSide(color: Colors.blue[100]!, width: 0.5), // ← ОПЦИОНАЛЬНО: ГРАНИЦА
                ),
                onDeleted: () {
                  _removeTag(tag);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _addTagFromInput() {
    final inputTag = _tagInputController.text.trim();

    if (inputTag.isEmpty) {
      AppGlobals.showWarning('Введите тег');
      return;
    }

    String originalTag = inputTag;
    String filteredTag = _filterTag(inputTag);

    if (filteredTag != originalTag) {
      AppGlobals.showSuccess('Тег отфильтрован: "$filteredTag"');
    }

    if (filteredTag.isEmpty) {
      AppGlobals.showWarning('Тег не может быть пустым после фильтрации');
      return;
    }

    if (_tags.contains(filteredTag)) {
      AppGlobals.showWarning('Тег "$filteredTag" уже добавлен');
      return;
    }

    // Ограничение длины
    final finalTag = filteredTag.length > 20 ? filteredTag.substring(0, 20) : filteredTag;

    setState(() {
      _tags.add(finalTag);
      _tagInputController.clear();
      widget.onTagsChanged(_tags);
    });
  }

  String _filterTag(String inputTag) {
    // Убираем все специальные символы, оставляем только буквы, цифры и пробелы
    String filtered = inputTag.replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9\s]'), '');

    // Убираем лишние пробелы
    filtered = filtered.trim().replaceAll(RegExp(r'\s+'), ' ');

    return filtered;
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      widget.onTagsChanged(_tags); // Уведомляем родителя об изменении
    });
  }

  @override
  void dispose() {
    _tagInputController.dispose();
    super.dispose();
  }
}