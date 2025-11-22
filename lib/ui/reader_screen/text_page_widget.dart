// text_page_widget.dart - ШАГ 12 (полноэкранный со свайпом)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangalibrary/core/utils/textPaginator.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/bookView.dart';

class TextPageWidget extends StatefulWidget {
  final BookView bookView;
  final Book book;

  const TextPageWidget({
    super.key,
    required this.bookView,
    required this.book
  });

  @override
  State<TextPageWidget> createState() => _TextPageWidgetState();
}

class _TextPageWidgetState extends State<TextPageWidget> {
  String filePathToBook = "";
  List<String>? _pages;
  bool _isInitialized = false;

  TextStyle get textStyle {
    return TextStyle(
      fontSize: widget.bookView.fontSize,
      color: widget.bookView.getTextColor,
      height: widget.bookView.lineHeight,
      fontFamily: 'Times New Roman'
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TextPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 3.0),
      ),
      child: PageView.builder(
        itemCount: _pages != null ? _pages!.length : 1,
        itemBuilder: (context, index) {
          return LayoutBuilder(
            builder: (context, pageConstraints) {
              return Container(
                color: widget.bookView.getBackgroundColor,
                padding: EdgeInsets.only(top:32, bottom: 16,left: 16,right: 16),
                child: LayoutBuilder(
                  builder: (context, textConstraints) {
                    if (!_isInitialized) {
                      _isInitialized = true;
                      _loadAndPaginateText(textConstraints);
                    }

                    if (_pages == null) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // УБИРАЕМ FutureBuilder - _pages![index] это просто String
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3.0),
                      ),
                      child: SelectableText(
                        _pages![index], // ← ПРОСТО БЕРЕМ СТРОКУ ИЗ СПИСКА
                        style: textStyle,
                        textAlign: TextAlign.justify,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String> readBookText(String filePath) async {
    try {
      final file = File(filePath);

      // Проверяем существование файла
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      // Читаем весь текст из файла
      String text = await file.readAsString();

      print('✅ Текст успешно прочитан из файла');
      print('📁 Путь: $filePath');
      print('📝 Длина текста: ${text.length} символов');

      return text;
    } catch (e) {
      print('❌ Ошибка чтения файла: $e');
      rethrow;
    }
  }

  void _loadAndPaginateText(BoxConstraints constraints) async {
    try {
      final availableWidth = constraints.maxWidth;
      final availableHeight = constraints.maxHeight;
      // 1. Читаем текст из файла
      String text = await readBookText(widget.book.filePath);

      // 3. Передаем ВСЕ параметры в пагинатор
      final paginator = BasicTextPaginator();
      List<String> pages = paginator.paginate(
        text: text,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        textStyle: textStyle,
      );

      setState(() {
        _pages = pages;
      });

    } catch (e) {
      print('Ошибка: $e');
    }
  }
}

