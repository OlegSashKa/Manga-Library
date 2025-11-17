import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/enums/book_enums.dart';
import 'package:mangalibrary/ui/book_details_screen/chapter_section.dart';
import 'package:mangalibrary/ui/reader_screen/text_reader_screen.dart';
import '../../domain/models/book.dart';
import 'package:mangalibrary/core/data/mock_data.dart';


class BookDetailsScreen extends StatefulWidget {
  final Book book;
  final VoidCallback onDelete;

  const BookDetailsScreen({
    super.key,
    required this.book,
    required this.onDelete,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  @override
  Widget build(BuildContext context){
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(
        title: Text("Детали книги"),
        actions: [
          PopupMenuButton(
            onSelected: (value){
              _handleMenuSelection(value, context, book);
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
          _buildHeaderSection(book),
          SizedBox(height: 24),
          _buildReadingButton(context, book),
          SizedBox(height: 8),
          _buildChapterSection(book),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Book book) {
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
                _buildProgressIndicator(book),

                SizedBox(height: 12),

                //Теги
                _buildTags(book),
              ],
            ),
          )
        ],
      ),
    );
  }


  void _handleMenuSelection(String value, BuildContext context, Book book) {
    switch (value){
      case 'about':
        _aboutBook(context, book);
        break;
      case 'delete':
        _showDeleteDialog(context, book);
        break;
    }
  }

  Widget _buildProgressIndicator(Book book) {
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

  Widget _buildTags(Book book) {
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

  Widget _buildReadingButton (BuildContext context, Book book){
    print('🎨 [BUTTON_COLOR] Статус: ${book.status.name}, Цвет: ${book.statusColor}');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: FilledButton(
          onPressed: () async {
            _startReading(context, book);
          },
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 10),
            backgroundColor: book.statusColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getButtonIcon(book)),
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

  void _startReading(BuildContext context, Book book) async {
    if (book.bookType == BookType.text) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextReaderScreen(book: book),
        ),
      ).then((_) async {
        final BooksTable booksTable = BooksTable();
        final Book? updatedBook = await booksTable.getBookById(book.id!);

        if (updatedBook != null) {
          print('🔄 [BOOK_DETAILS] Обновление данных книги после чтения:');
          print('   📊 Старый totalPages: ${widget.book.totalPages}');
          print('   📊 Новый totalPages: ${updatedBook.totalPages}');
          print('   📊 Старый currentPage: ${widget.book.currentPage}');
          print('   📊 Новый currentPage: ${updatedBook.currentPage}');
          print('   🎨 Старый статус: ${widget.book.status.name}');
          print('   🎨 Новый статус: ${updatedBook.status.name}');

          setState(() {
            widget.book.currentPage = updatedBook.currentPage;
            widget.book.progress = updatedBook.progress;
            widget.book.totalPages = updatedBook.totalPages;
            widget.book.status = updatedBook.status;

            print('🎨 [BOOK_DETAILS] Финальный статус: ${widget.book.status.name}');
          });
        }
      });

    } else if (book.bookType == BookType.manga) {
      // Для манги оставляем старый функционал
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Открытие манги еще не реализованно')),
      );
    }
  }

  IconData _getButtonIcon(Book book) {
    if (book.hasReadingProgress) {
      return Icons.play_arrow; // Продолжить чтение
    } else {
      return Icons.read_more; // Начать чтение
    }
  }

  void _showDeleteDialog(BuildContext context, Book book) async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Удалить книгу?'),
          content: Text('Книга "${book.title}" будет удалена безвозвратно!'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteBookCompletely(context, book); // Удаляем книгу
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

  Widget _buildChapterSection(Book book){
    final chapter = MockData().testChapters;
    return Expanded(
        child: Container(
          padding: EdgeInsets.all(16),
          child: ChapterSection(bookId: book.id!, initialChapters: chapter),
        )
    );
  }

  void _aboutBook(BuildContext context, Book book) {
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

  Future<void> _deleteBookCompletely(BuildContext context, Book book) async {
    // onDelete();
    try{
      final bookTable = BooksTable();

      await _deleteBookFiles(book);

      if(book.id != null){
        await bookTable.deleteBook(book.id!);
      }

      widget.onDelete();

    }catch(e){
      print('Ошибка при удалении книги: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении книги: $e')),
      );
    }

  }

  Future<void> _deleteBookFiles(Book book) async {
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


