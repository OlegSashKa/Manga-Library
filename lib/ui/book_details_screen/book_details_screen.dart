import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/services/app_utils.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import 'package:mangalibrary/enums/book_enums.dart';
import 'package:mangalibrary/ui/book_details_screen/chapter_section.dart';
import 'package:mangalibrary/ui/reader_screen/text_reader_screen.dart';
import '../../domain/models/book.dart';


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
  late Book _currentBook;

  final BooksTable _booksTable = BooksTable();

  late final Future<Book> _bookFuture = _booksTable.getFullBookDetails(widget.book.id!);

  BookVolume? get currentVolume {
    // Используем ранее созданные геттеры из модели Book
    return _currentBook.currentVolume;
  }

  VolumeChapter? get currentChapter {
    // Используем ранее созданные геттеры из модели Book
    return _currentBook.currentChapter;
  }

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
  }

  // Future<Book> _loadBookData() async {
  //   try {
  //     // 💡 Загружаем книгу с полной гидратацией (с Томами и Главами)
  //     final loadedBook = await _booksTable.getBookById(widget.book.id!);
  //
  //     // 💡 Обновляем состояние после успешной загрузки
  //     setState(() {
  //       if (loadedBook != null) {
  //         _currentBook = loadedBook;
  //       }
  //     });
  //     return _currentBook;
  //   } catch (e) {
  //     // ⚠️ Если была ошибка БД, нужно обработать.
  //     // Главное: установить _isLoading = false, чтобы избежать вечного прогресса.
  //     AppGlobals.showError('Не удалось загрузить данные книги: $e');
  //     return _currentBook;
  //   }
  // }

  @override
  Widget build(BuildContext context){
    return FutureBuilder<Book>(
      future: _bookFuture,
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return Center(child: CircularProgressIndicator());
        }
        if(snapshot.hasError){
          return Center(child: Text('Ошибка ${snapshot.error}', style: TextStyle(fontSize: 12)));
        }
        if(snapshot.hasData){
          final book = snapshot.data!;
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
                //TODO здесь информаци подгружаеться верная
                _buildHeaderSection(book),
                SizedBox(height: 24),
                //TODO в этом коде есть причина по которой кнопка имеет анимацию загрузки, если нет укажи какой код скинуть
                _buildReadingButton(context, book),
                SizedBox(height: 8),
                //TODO пишется правильный том, правильные страницы но пишется глава 0, хотя по идее номерация начинаетсься с 1
                //TODO так же при развороте не риуються chapters
                //TODO помоги прологировать что бы понять какие там данные
                _buildChapterSection(book),
                SizedBox(height: 12),
              ],
            ),
          );
        };
        return Center(child: Text('Книга не найдена.'));
      },
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
        Text('${(book.getProgress * 100).toInt()}% прочитано'),
        LinearProgressIndicator(
          value: book.getProgress,
          backgroundColor: Colors.grey[300],
          color: book.statusColor,
          minHeight: 6,
        ),
        SizedBox(height: 4),
        Text(
          '${book.currentPage}/${book.totalPages} стр.',
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

  Widget _buildReadingButton(BuildContext context, Book book) {
    return FutureBuilder<Book>(
      future: _bookFuture,
      builder: (context, snapshot) {
        // Пока загружаем - показываем кнопку с индикатором
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingButton();
        }

        // Если ошибка - показываем обычную кнопку
        if (snapshot.hasError) {
          print('❌ Ошибка загрузки данных для кнопки: ${snapshot.error}');
          return _buildNormalButton(book);
        }

        // Если данные загружены - используем актуальную книгу
        final updatedBook = snapshot.data!;
        return _buildNormalButton(updatedBook);
      },
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 10),
          backgroundColor: Colors.grey,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Загрузка...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalButton(Book book) {
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
            if (book.hasReadingProgress) ...[
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
        ),
      ),
    );
  }

  //TODO работаем над эим методом
  void _startReading(BuildContext context, Book book, {int targetPage = -1}) async {
    if (book.bookType == BookType.text) {
      // ✅ ПЕРЕДАЕМ КОЛБЭК ДЛЯ ПОЛУЧЕНИЯ ОБНОВЛЕННОЙ КНИГИ
      await Navigator.of(context).push<Book>(
        MaterialPageRoute(
          builder: (context) => TextReaderScreen(
            book: book,
            targetPage: targetPage,
          ),
        ),
      );

     // ✅ Принудительно обновляем состояние
     if (mounted) {
       setState(() {});
     }
    } else if (book.bookType == BookType.manga) {
      AppGlobals.showInfo('Открытие манги еще не реализованно');
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
    print('📖 BOOK_DETAILS_SCREEN - _buildChapterSection:');
    print('📖 Book ID: ${book.id}');
    print('📖 Book title: ${book.title}');
    print('📖 Volumes count: ${book.volumes.length}');
    print('📖 Book pags: ${book.totalPages}');

    for (int i = 0; i < book.volumes.length; i++) {
      final volume = book.volumes[i];
      print('📖 Volume $i: ${volume.title} (id: ${volume.id}) (start page: ${volume.startPage}) (end page: ${volume.endPage}) (count page: ${volume.endPage! - volume.startPage + 1})');
      print('📖   Chapters count: ${volume.chapters.length}');

      for (int j = 0; j < volume.chapters.length; j++) {
        final chapter = volume.chapters[j];
        print('📖   Chapter $j: ${chapter.title} (id: ${chapter.id})');
        print('📖     startPage: ${chapter.startPage}, endPage: ${chapter.endPage}');
        print('📖     volumeId: ${chapter.volumeId}, position: ${chapter.position}');
      }
    }

    return Expanded(
        child: Container(
          padding: EdgeInsets.all(16),
          child: ChapterSection(
            bookId: book.id!,
            initialVolumes: book.volumes,
            // 🔥 ПЕРЕДАЕМ КОЛЛБЭК, который вызывает _navigateToReaderScreen
            onChapterSelected: (targetPage) {
             _startReading(context, book, targetPage: targetPage);
            },
          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: TextStyle(fontSize: 16, color: Colors.grey[800], fontFamily: 'sans-serif'),
                  textAlign: TextAlign.left,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.start, // ← ВЫРАВНИВАНИЕ ПО ЛЕВОМУ КРАЮ
                          runAlignment: WrapAlignment.start, // ← ВЫРАВНИВАНИЕ СТРОК
                          children: [
                            Text('Название: '),
                            Text(
                              book.title,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              softWrap: true,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.start, // ← ВЫРАВНИВАНИЕ ПО ЛЕВОМУ КРАЮ
                          runAlignment: WrapAlignment.start, // ← ВЫРАВНИВАНИЕ СТРОК
                          children: [
                            Text('Автор: '),
                            Text(
                              book.author,
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text('Тип: ${book.bookType.name}'),
                      Text('Формат: ${book.fileFormat}'),
                      Text('Размер: ${AppUtils.formatFileSize(book.fileSize)}'),
                      Text('Страниц: ${book.totalPages}'),
                      Text('Добавлена: ${book.addedDate.day}.${book.addedDate.month}.${book.addedDate.year}'),
                      Text('Последнее открытие: ${book.lastDateOpen.day}.${book.lastDateOpen.month}.${book.lastDateOpen.year}'),
                      Text('Время чтения:  ${AppUtils.formatDuration(book.readingTime)}'),
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

      await FileService.deleteBookFiles(book);

      if(book.id != null){
        await bookTable.deleteBook(book.id!);
      }

      widget.onDelete();

    }catch(e){
//       print('Ошибка при удалении книги: $e');
      AppGlobals.showError('Ошибка при удалении книги: $e');
    }
  }
}


