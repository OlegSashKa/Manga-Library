import 'package:epub_pro/epub_pro.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:html/parser.dart' show parse;
import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/services/app_utils.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/core/utils/epub_parser_utils.dart';
import 'package:mangalibrary/core/utils/textPaginator.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titlePadding: EdgeInsets.zero,
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
        allowedExtensions: ['epub', 'txt'],
        allowMultiple: false,
      );

      if(result == null){
        // Пользователь отменил выбор - это не ошибка
//         print('Пользователь отменил выбор файла');
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

//       print('''
// ✅ Файл выбран успешно:
//    Путь: $_selectedFilePath
//    Имя: $_fileName
//    Размер: $_fileSize байт
//    Расширение: ${file.extension}
// ''');

    } catch (e){
//       print('Ошибка выбора файла: $e');
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
    if (_selectedFilePath == null || _selectedFilePath!.isEmpty) {
      AppGlobals.showError('Файл не выбран');
      return;
    }

    if (_titleController.text.isEmpty) {
      AppGlobals.showError('Введите название книги');
      return;
    }

    final String bookTitle = _titleController.text;
    final BooksTable booksTable = BooksTable();

    try {
      bool bookExists = await booksTable.doesBookExist(bookTitle);
      if (bookExists) {
        AppGlobals.showError('Книга с названием "$bookTitle" уже существует в библиотеке');
        return;
      }
    } catch (e) {
      AppGlobals.showError('Ошибка проверки существования книги');
      return;
    }

    // Показываем индикатор загрузки после всех синхронных проверок
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    int? bookId;
    Book? newBook;

    try {
      // 2. ИМПОРТ ФАЙЛА
      BookImportResult importResult = await FileService.importBook(
          _selectedFilePath!,
          bookTitle
      );

      // 3. ПЕРВИЧНОЕ СОХРАНЕНИЕ
      // Инициализируем newBook с базовыми значениями (totalPages=1, chapters=[])
      newBook = Book(
        title: bookTitle,
        author: _authorController.text.isEmpty ? 'Неизвестен' : _authorController.text,
        bookType: importResult.bookType,
        fileFolderPath: importResult.bookPath,
        filePath: importResult.filePath,
        fileFormat: path.extension(importResult.filePath).replaceFirst('.', ''),
        fileSize: importResult.fileSize,
        addedDate: DateTime.now(),
        lastDateOpen: DateTime.now(),
        totalPages: 1,
        isFavorite: false,
        tags: [Book.getBookTypeByName(importResult.bookType.name), ..._tags],
        chapters: [], // Временно пустой список
        currentChapterIndex: 0,
      );

      bookId = await booksTable.insertBook(newBook);
      newBook.id = bookId;
//       print('✅ [DB] Книга временно сохранена. ID: $bookId');


      // 4. ОБРАБОТКА КОНТЕНТА И ПАГИНАЦИЯ (Только если bookId успешно получен)
      final chaptersTable = ChapterTable(); // Объявляем внутри try
      int calculatedTotalPages = 1;
      BookView bookViewSettings = await BookViewTable.getSettings();

      // РАСЧЕТ ДОСТУПНОЙ ОБЛАСТИ
      final mediaQuery = MediaQuery.of(context);
      const double horizontalPadding = 16.0 * 2;
      const double verticalPadding = 32.0 + 16.0;

      final double availableWidth = mediaQuery.size.width - horizontalPadding;
      final double availableHeight = mediaQuery.size.height - verticalPadding - mediaQuery.padding.top - mediaQuery.padding.bottom;

      if (importResult.filePath.endsWith('.txt')) {
        // Логика пагинации для TXT
        final file = File(importResult.filePath);
        if (await file.exists()) {
          final content = await file.readAsString();

          final paginator = CoolTextPaginator();
          final pages = paginator.paginate(
            text: content,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            textStyle: TextStyle(
              fontSize: bookViewSettings.fontSize,
              height: bookViewSettings.lineHeight,
              fontFamily: 'Roboto',
            ),
          ).pages;

          calculatedTotalPages = pages.length; // Обновляем

          final VolumeChapter defaultChapter = VolumeChapter(
            bookId: bookId,
            title: 'Начало книги',
            startPage: 1,
            endPage: calculatedTotalPages, // Используем рассчитанный totalPages
            position: 0,
            isRead: BookStatus.planned,
            readTime: Duration(seconds: 0),
            currentPage: 0,
          );

          await chaptersTable.insertChapter(defaultChapter);
          newBook.chapters.add(defaultChapter); // Обновляем объект
//
          print('✅ Рассчитано страниц: $calculatedTotalPages');
        }

      } else if (importResult.filePath.endsWith('.epub')) {
        // Логика пагинации для EPUB
        final bytes = await File(importResult.filePath).readAsBytes();
        final epubBook = await EpubReader.readBook(bytes);
        final parsedContent = EpubParserUtils.extractAndPaginateBook(
            epubBook: epubBook,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            textStyle: TextStyle(
              fontSize: bookViewSettings.fontSize,
              height: bookViewSettings.lineHeight,
              fontFamily: 'Roboto',
            ),
          idBook: bookId,
        );

        newBook.chapters = parsedContent.chapters;
        calculatedTotalPages = parsedContent.allBookPages.length;
        newBook.title = epubBook.title != null ? epubBook.title! : bookTitle;
        // 🔴 ВАЖНО: Главы вставляются здесь, если это EPUB
        await chaptersTable.insertChapters(newBook.chapters, newBook.id!);

      } else {
//         print('📘 Формат ${importResult.bookType} - расчет страниц не реализован');
      }

      // 5. ОБНОВЛЕНИЕ КНИГИ В БД
      newBook.totalPages = calculatedTotalPages; // Устанавливаем итоговое значение
      // 🔴 ИСПРАВЛЕНИЕ #3: Обновление записи в БД
      await booksTable.updateBook(newBook);
//       print('✅ [DB] Книга ID $bookId успешно обновлена с totalPages: $calculatedTotalPages');

      // 6. ЗАВЕРШЕНИЕ
      Navigator.pop(context); // Закрываем индикатор
      AppGlobals.showSuccess('Книга "${newBook.title}" успешно добавлена!');
      widget.onBookAdded(newBook);
      Navigator.pop(context); // Закрываем диалог AddBookDialog

    } catch (e, stackTrace) {
      // 7. ОБРАБОТКА ОШИБОК И ОТКАТ
      Navigator.pop(context); // Закрываем индикатор
//       print('❌ КРИТИЧЕСКАЯ ОШИБКА: $e');
//       print('📋 Stack trace: $stackTrace');
      AppGlobals.showError('Ошибка: ${e.toString()}');

      // Если книга была сохранена, но произошла ошибка при обработке контента/обновлении
      if (bookId != null) {
        // Удаляем запись из таблицы books
        await booksTable.deleteBook(bookId);
        // Удаляем скопированный файл и папку книги
        if (newBook != null) {
          await FileService.deleteBookFiles(newBook);
        }
//         print('🗑️ [ROLLBACK] Книга ID $bookId и ее файлы были удалены.');
      }
    }
  }
}