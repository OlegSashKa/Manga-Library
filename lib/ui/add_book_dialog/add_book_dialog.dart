import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/services/app_utils.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/core/services/page_calculator_service.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/enums/book_enums.dart';
import 'package:mangalibrary/ui/add_book_dialog/tag_input_widget.dart';
import 'package:path/path.dart' as path;
import 'package:mangalibrary/domain/models/book.dart';

class AddBookDialog extends StatefulWidget {

  final Function(Book) onBookAdded;

  const AddBookDialog({
    super.key,
    required this.onBookAdded,
  });

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final _tagInputController = TextEditingController();

  String? _selectedFilePath;
  String? _fileName;
  int? _fileSize;

  BookType _selectedType = BookType.manga;
  List<String> _tags = []; // Список тегов

  @override
  void initState() {
    super.initState();
    // Слушаем изменения в поле названия для обновления кнопки
    _titleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Перерисовываем виджет при изменении текста
  }

  @override
  Widget build(BuildContext context){
    return AlertDialog(
      constraints: BoxConstraints(
        minWidth: 300,
        maxWidth: 380,
      ),
      shape: RoundedRectangleBorder( // ← ДОБАВЛЯЕМ ФОРМУ
        borderRadius: BorderRadius.circular(12), // ← ОДИНАКОВОЕ СКРУГЛЕНИЕ ВСЕХ УГЛОВ
      ),
      titlePadding: EdgeInsets.zero, // ← УБИРАЕМ ОТСТУПЫ У ЗАГОЛОВКА
      insetPadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.deepPurple[100],
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Text(
          'Добавить книгу',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[900],
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поле для названия книги
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Название книги',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            Text(
              '* - обязательное поле',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            SizedBox(height: 3),
            // Поле для автора
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Автор',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: 16),
            TagInputWidget(
              initialTags: _tags,
              onTagsChanged: (newTags) {
                setState(() {
                  _tags = newTags;
                });
                },
              labelText: 'Введите тег',
              hintText: 'фэнтези, приключения, роман',
            ),
            SizedBox(height: 16),
            // Кнопка выбора файла
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.attach_file),
                label: Text('Выбрать файл'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Информация о выбранном файле
            if(_fileName != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName!,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if(_fileSize != null) ...[
                            SizedBox(width: 4),
                            Text(
                              'Размер: ${AppUtils.formatFileSize(_fileSize!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        // Кнопка отмены
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Отмена'),
        ),
        // Кнопка сохранения
        ElevatedButton(
          onPressed: _canSave() ? _saveBook : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
          child: Text(
              'Сохранить',
              style: TextStyle(
                color: Colors.white,
              ),
          ),
        )
      ],
    );
  }

  void _pickFile() async {
    try{
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'txt', 'cbz', 'cbr'],
        allowMultiple: false,
      );

      if(result == null){
        // Пользователь отменил выбор - это не ошибка
        print('Пользователь отменил выбор файла');
        return; // Просто выходим из функции
      }

      final file = result.files.single; // Получаем первый файл

      if (file.path == null || file.path!.isEmpty) {
        AppGlobals.showError('Не удалось получить путь к файлу');
        return;
      }

      final fileObject = File(file.path!);
      if (!await fileObject.exists()) {
        AppGlobals.showError('Файл не существует или недоступен');
        return;
      }

      setState(() {
        _selectedFilePath = file.path!;
        _fileName = file.name;
        _fileSize = file.size;
      });

      _autoFillBookTitle(file.name);

      print('''
✅ Файл выбран успешно:
   Путь: $_selectedFilePath
   Имя: $_fileName
   Размер: $_fileSize байт
   Расширение: ${file.extension}
''');

    } catch (e){
      print('Ошибка выбора файла: $e');
      AppGlobals.showError('Не удалось выбрать файл');
    }
  }

  void _autoFillBookTitle(String fileName) {
    // Убираем расширение файла
    String title = path.withoutExtension(fileName);

    // Заменяем подчеркивания и дефисы на пробелы
    title = title.replaceAll('_', ' ').replaceAll('-', ' ');

    // Убираем лишние пробелы
    title = title.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Делаем первую букву заглавной для каждого слова
    title = title.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    // Обновляем поле ввода
    _titleController.text = title;

    // 🔥 ОБЯЗАТЕЛЬНО ВЫЗЫВАЕМ setState ДЛЯ ПЕРЕРИСОВКИ КНОПКИ
    setState(() {});
  }

  bool _canSave() {
    return _titleController.text.isNotEmpty &&
        _selectedFilePath != null;
  }

  void _saveBook() async {
    // Показываем индикатор загрузки
    if (_selectedFilePath == null || _selectedFilePath!.isEmpty) {
      AppGlobals.showError('Файл не выбран');
      return;
    }

    if (_titleController.text.isEmpty) {
      AppGlobals.showError('Введите название книги');
      return;
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
    );

    try{
      final booksTable = BooksTable();

      bool bookExists = await booksTable.doesBookExist(_titleController.text);
      if (bookExists) {
        Navigator.pop(context); // Закрываем индикатор
        AppGlobals.showError('Книга с названием "${_titleController.text}" уже существует в библиотеке');
        return;
      }

      BookImportResult importResult  = await FileService.importBook(
          _selectedFilePath!,
          _titleController.text
      );

      BookView bookViewSettings = await BookViewTable.getSettings();

      int totalPages = 1;
      if (importResult.filePath.endsWith('.txt')) {
        try {
          final file = File(importResult.filePath);
          if (await file.exists()) {
            final content = await file.readAsString();

            final mediaQuery = MediaQuery.of(context);
            const double horizontalPadding = 16.0;
            const double verticalPadding = 16.0;

            final double availableHeight = mediaQuery.size.height
                - mediaQuery.padding.top
                - kToolbarHeight
                - mediaQuery.padding.bottom
                - (verticalPadding * 2);

            final double availableWidth = mediaQuery.size.width - (horizontalPadding * 2);

            totalPages = PageCalculatorService.calculatePageCount(
              text: content,
              pageWidth: availableWidth,
              pageHeight: availableHeight,
              fontSize: bookViewSettings.fontSize,
              lineHeight: bookViewSettings.lineHeight,
              horizontalPadding: 16.0,
              verticalPadding: 16.0,
              fontFamily: 'Roboto',
            );

            print('📖 Для книги "${_titleController.text}" рассчитано страниц: $totalPages');
            print('Использованы настройки: шрифт ${bookViewSettings.fontSize}, интервал ${bookViewSettings.lineHeight}');
          }
        } catch (e) {
          print('⚠️ Ошибка расчёта страниц: $e');
          // Не прерываем процесс из-за ошибки расчёта
        }
      }

      BookStatus calculateStatus(double progress) {
        if (progress < 0.1) return BookStatus.planned;
        if (progress < 1.0) return BookStatus.reading;
        return BookStatus.completed;
      }

      Book newBook = Book(
        title: _titleController.text,
        author: _authorController.text.isEmpty ? 'Неизвестен' : _authorController.text,
        bookType: importResult.bookType,      // Тип определился автоматически!
        fileFolderPath: importResult.bookPath,      // Путь к скопированному файлу
        filePath: importResult.filePath,      // Путь к скопированному файлу
        fileFormat: path.extension(importResult.filePath).replaceFirst('.', ''),
        fileSize: importResult.fileSize,      // Реальный размер файла
        addedDate: DateTime.now(),
        lastDateOpen: DateTime.now(),
        // Добавляем недостающие поля по умолчанию:
        currentPage: 0,
        totalPages: totalPages,
        progress: 0.0,
        status: calculateStatus(0.0),
        readingTime: Duration.zero,
        isFavorite: false,
        tags: [Book.getBookTypeByName(importResult.bookType.name), ..._tags],
        chapters: const [],
        currentChapterIndex: 0,
      );

      final bookId = await BooksTable().insertBook(newBook);

      newBook.id = bookId; // Сохраняем ID из базы

      Navigator.pop(context);

      AppGlobals.showSuccess('Книга "${newBook.title}" успешно добавлена!');

      widget.onBookAdded(newBook);
      Navigator.pop(context);

    }catch (e, stackTrace){
      Navigator.pop(context); // Закрываем индикатор
      print('❌ КРИТИЧЕСКАЯ ОШИБКА: $e');
      print('📋 Stack trace: $stackTrace');
      AppGlobals.showError('Ошибка: ${e.toString()}');
    }
  }
}