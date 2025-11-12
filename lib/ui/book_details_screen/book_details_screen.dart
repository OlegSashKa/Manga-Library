import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/ui/book_details_screen/chapter_section.dart';
import '../../domain/models/book.dart';
import 'package:mangalibrary/core/data/mock_data.dart';


class BookDetailsScreen extends StatelessWidget {
  final Book book;
  final VoidCallback onDelete;

  const BookDetailsScreen({
    super.key,
    required this.book,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Детали книги"),
        actions: [
          PopupMenuButton(
            onSelected: (value){
              _handleMenuSelection(value, context);
            },
            itemBuilder: (BuildContext context) {
              return[
                PopupMenuItem<String>(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Информация о книге'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Удалить'),
                    ],
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: Column(
          children: [
            _buildHeaderSection(),
            SizedBox(height: 24),
            _buildReadingButton(),
            SizedBox(height: 8),
            _buildChapterSection(),
            SizedBox(height: 12),
          ],
        ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book,
                size: 70,
                color: Colors.grey[600],
              )
          ),

          SizedBox(width: 16), // Отступ между обложкой и текстом

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Название книги
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                //автор
                Text(
                  book.author,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: 12),

                //Прогресс чтения
                _buildProgressIndicator(),

                SizedBox(height: 12),

                //Теги
                _buildTags(),
              ],
            ),
          )
        ],
      ),
    );
  }


  void _handleMenuSelection(String value, BuildContext context) {
    switch (value){
      case 'about':
        _aboutBook(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${(book.progress * 100).toInt()}% прочитанно'
        ),
        // прогресс-бар
        LinearProgressIndicator(
          value: book.progress,
          backgroundColor: Colors.grey[300],
          color: book.statusColor,
          minHeight: 6,
        ),
        SizedBox(height: 4),

        // Страницы
        Text(
          '${book.currentPage}/${book.totalPages} стр. ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        )
      ],
    );
  }

  Widget _buildTags() {
    if(book.tags.isEmpty){
      // Если тегов нет
      return Text(
        '#Теги не добавленны',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }
    // Если теги есть
    return Wrap(
      spacing: 2,
      runSpacing: 1,
      children: book.tags.map((tag){
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[800],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReadingButton(){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: FilledButton(
        onPressed: _startReading,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 10),
          backgroundColor: book.statusColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getButtonIcon()),
            SizedBox(width: 12),
            Text(
              book.actionButtonText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if(book.hasReadingProgress) ...[
              SizedBox(width: 8),
              Text(
                '(${book.currentPage}/${book.totalPages})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              )
            ]
          ],
        )),
    );
  }
  
  void _startReading() {
    print('Начинаем читать книгу: ${book.title}');
    // Позже добавим настоящую навигацию на экран чтения
  }

  IconData _getButtonIcon() {
    if (book.hasReadingProgress) {
      return Icons.play_arrow; // Продолжить чтение
    } else {
      return Icons.read_more; // Начать чтение
    }
  }

  void _showDeleteDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить книгу?'),
        content: Text('Книга "${book.title}" будет удалена безвозвратно!'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBookCompletely(context); // Удаляем книгу
              Navigator.pop(context);
            },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
                'Удалить',
              style: TextStyle(
                color: Colors.white
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildChapterSection(){
    final chapter = MockData().testChapters;
    return Expanded(
        child: Container(
          padding: EdgeInsets.all(16),
          child: ChapterSection(chapters: chapter),
        )
    );
  }

  void _aboutBook(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.black45),
              SizedBox(width: 8),
              Text(
                'Информация о книге'.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: TextStyle( fontSize: 16, color: Colors.grey[800], fontFamily: 'sans-serif'),
                  child: Column(
                    children: [
                      Text('Название: ${book.title}'),
                      Text('Автор: ${book.author}'),
                      Text('Тип: ${book.bookType.name}'),
                      Text('Формат: ${book.fileFormat}'),
                      Text('Размер: ${(book.fileSize / 1024 / 1024).toStringAsFixed(2)}MB'),
                      Text('Страниц: ${book.totalPages}'),
                      Text('Добавлена: ${book.addedDate.day}.${book.addedDate.month}.${book.addedDate.year}'),
                      Text('Последнее открытие: ${book.lastDateOpen.day}.${book.lastDateOpen.month}.${book.lastDateOpen.year}'),
                      Text('Время чтения:  ${book.readingTime.inMinutes}мин'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Закрыть'),
            )
          ],
        )
    );
    
    
  }

  Future<void> _deleteBookCompletely(BuildContext context) async {
    // onDelete();
    try{
      final bookTable = BooksTable();

      await _deleteBookFiles();

      if(book.id != null){
        await bookTable.deleteBook(book.id!);
      }

      onDelete();

    }catch(e){
      print('Ошибка при удалении книги: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении книги: $e')),
      );
    }

  }

  Future<void> _deleteBookFiles() async {
    try{
      final bookDir = await FileService.getBookDirectory(book.title);
      // Проверяем существует ли папка
      if (await bookDir.exists()) {
        // Удаляем всю папку с содержимым рекурсивно
        await bookDir.delete(recursive: true);
        print('Папка книги удалена: ${bookDir.path}');
      } else {
        print('Папка книги не существует: ${bookDir.path}');
      }
    }catch(e){
      print('Ошибка при удалении файлов книги: $e');
    }
  }
}
