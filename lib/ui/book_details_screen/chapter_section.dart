import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/domain/models/book.dart';

class ChapterSection extends StatefulWidget{
  final int bookId; // Добавляем ID книги для загрузки глав
  final List<BookChapter>? initialChapters; // Начальные главы (опционально)

  const ChapterSection({
    super.key,
    required this.bookId, // Обязательный параметр - ID книги
    this.initialChapters, // Необязательный параметр - начальные главы
  });

  @override
  State<ChapterSection> createState() => _ChapterSectionState();
}

class _ChapterSectionState extends State<ChapterSection> {
  int collViewBook = 5;
  List<BookChapter> _chapters = []; // Список глав (будет загружаться из БД)
  bool _isLoading = true; // Флаг загрузки
  bool _hasError = false; // Флаг ошибки

  final ChapterTable _chaptersTable = ChapterTable();

  void _showAllChapters(){
    setState(() {
      collViewBook = _chapters.length;
    });
  }

  @override
  void initState() {
    super.initState();
    // Если переданы начальные главы - используем их
    if (widget.initialChapters != null && widget.initialChapters!.isNotEmpty) {
      _chapters = widget.initialChapters!;
      _isLoading = false;
    } else {
      // Иначе загружаем главы из базы данных
      _loadChapters();
    }
  }

  Future<void> _loadChapters() async {
    try {
      setState(() {
        _isLoading = true; // Показываем индикатор загрузки
        _hasError = false; // Сбрасываем флаг ошибки
      });
      final List<BookChapter> loadedChapters = await _chaptersTable.getChaptersByBookId(widget.bookId);
      setState(() {
        _chapters = loadedChapters; // Сохраняем загруженные главы
        _isLoading = false; // Скрываем индикатор загрузки
      });
      print('✅ Загружено глав: ${_chapters.length} для книги ID: ${widget.bookId}');
    }catch (e){
      print('❌ Ошибка загрузки глав: $e');
      setState(() {
        _hasError = true; // Устанавливаем флаг ошибки
        _isLoading = false; // Скрываем индикатор загрузки
      });
    }
  }

  @override
  Widget build(BuildContext context){
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), // Крутящийся индикатор
            SizedBox(height: 16),
            Text('Загрузка глав...'), // Текст загрузки
          ],
        ),
      );
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48), // Иконка ошибки
            SizedBox(height: 16),
            Text('Ошибка загрузки глав'), // Текст ошибки
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadChapters, // Кнопка повторной загрузки
              child: Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }
    if (_chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, color: Colors.grey, size: 48), // Иконка книги
            SizedBox(height: 16),
            Text('Главы не найдены'), // Текст пустого состояния
            SizedBox(height: 8),
            Text(
              'Для этой книги еще не созданы главы',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView(
      children: [
        // Список глав (показываем только первые collViewBook штук)
        ..._chapters.take(collViewBook).map((chapter) => _buildChapterTile(chapter)),

        // Кнопка "Показать все" если глав больше чем collViewBook
        if (_chapters.length > collViewBook)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: TextButton(
              onPressed: _showAllChapters, // Обработчик нажатия
              child: Text(
                'Показать все главы (еще ${_chapters.length - collViewBook})',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChapterTile(BookChapter chapter) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: _buildChapterIcon(chapter), // Иконка статуса главы
        title: Text(
          chapter.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: chapter.currentPage > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: _buildChapterSubtitle(chapter), // Подзаголовок с информацией
        trailing: _buildChapterTrailing(chapter), // Дополнительная информация справа
        onTap: () => _openChapter(chapter), // Обработчик нажатия на главу
      ),
    );
  }

  Widget _buildChapterIcon(BookChapter chapter) {
    if(chapter.isRead){
      return Icon(Icons.check_circle, color: Colors.green);
    } else if (chapter.currentPage > 0) {
      return Icon(Icons.play_circle, color: Colors.orange);
    } else{
      return Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }

  Widget _buildChapterSubtitle(BookChapter chapter) {
    if(chapter.isRead){
      return Text('Прочитано');
    } else if (chapter.currentPage > 0){
      return Text('Страница ${chapter.currentPage}');
    } else {
      return Text('Не начато');
    }
  }

  Widget _buildChapterTrailing(BookChapter chapter) {
    // Для прочитанных глав показываем галочку
    if (chapter.isRead) {
      return Icon(Icons.done_all, color: Colors.green);
    }
    // Для глав в процессе показываем текущую страницу
    else if (chapter.currentPage > 0) {
      return Text(
        '${chapter.currentPage}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      );
    }
    // Для не начатых глав ничего не показываем
    else {
      return SizedBox.shrink(); // Пустой виджет
    }
  }

  void _openChapter(BookChapter chapter) {
    print('📖 Открыть главу: "${chapter.title}"');
    print('📄 Страницы: ${chapter.startPage}-${chapter.endPage}');
    print('📍 Текущая страница: ${chapter.currentPage}');

    // TODO: Здесь будет логика перехода к чтению конкретной главы
    // Например: Navigator.push(...) к экрану чтения с указанием главы

    // Можно показать временное уведомление
    AppGlobals.showInfo('Открываем главу: ${chapter.title}');
  }
  void updateChapters(List<BookChapter> newChapters) {
    setState(() {
      _chapters = newChapters;
      _isLoading = false;
      _hasError = false;
    });
  }
}
