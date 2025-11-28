import 'package:epub_pro/epub_pro.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/core/database/tables/volume_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/services/app_utils.dart';
import 'package:mangalibrary/core/services/book_content_importer.dart';
import 'package:mangalibrary/core/services/file_service.dart';
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

  Map<String, double>? availableSize;

  BookType _selectedType = BookType.manga;
  List<String> _tags = []; // Список тегов

  @override
  void initState() {
    super.initState();
    // Слушаем изменения в поле названия для обновления кнопки
    _titleController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_){
      final mediaQuery = MediaQuery.of(context);
      const double horizontalPadding = 16.0 * 2;
      const double verticalPadding = 32.0 + 16.0;

      setState(() {
        availableSize = {
          'width': mediaQuery.size.width - horizontalPadding,
          'height': mediaQuery.size.height - verticalPadding - mediaQuery.padding.top - mediaQuery.padding.bottom,
        };
      });
    });
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

      _autoFillBookTitle(file);


    } catch (e){
      AppGlobals.showError('Не удалось выбрать файл');
    }
  }

  void _autoFillBookTitle(PlatformFile file) async {
    // Убираем расширение файла
    final fileName = file.name;
    final extension = path.extension(fileName);

    String title = "";
    String author = "";
    if(path.extension(fileName) == ".epub"){
      try{
        final epubBook = await EpubReader.openBook(File(file.path!).readAsBytes());
        title = epubBook.title ?? path.withoutExtension(fileName);
        author = epubBook.authors.isEmpty ? '' : epubBook.authors.length == 1 ? epubBook.authors.first : epubBook.authors.join(', ');
      }catch (e){
        title = path.withoutExtension(fileName);
        AppGlobals.showError("Ошибка в четнии названия книги и автора ошибка $e");
      }
    }else{
      title = path.withoutExtension(fileName);
    }
    //
    title = path.withoutExtension(fileName);
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
    if(author.isNotEmpty){
      _authorController.text = author;
    }
    // 🔥 ОБЯЗАТЕЛЬНО ВЫЗЫВАЕМ setState ДЛЯ ПЕРЕРИСОВКИ КНОПКИ
    setState(() {});
  }

  bool _canSave() {
    return _titleController.text.isNotEmpty && _selectedFilePath != null;
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

    if (!mounted) return;
    AppGlobals.showInfo('Импортируем книгу...'); // Включаем индикатор загрузки

    final String bookTitle = _titleController.text;

    final BooksTable booksTable = BooksTable();
    final VolumesTable volumesTable = VolumesTable(); // 💡 Предполагаем, что класс импортирован
    final ChapterTable chapterTable = ChapterTable();

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

    int? bookId;
    Book? newBook;
    int calculatedTotalPages = 0;

    try {
      final File file = File(_selectedFilePath!);
      final int fileSize = _fileSize != null ? _fileSize! : await file.length();
      final String fileFormat = path.extension(_selectedFilePath!).toLowerCase();
      final BookType bookType = FileService.determineBookType(_selectedFilePath!);

      // 3. ПЕРВИЧНОЕ СОХРАНЕНИЕ
      newBook = Book(
        title: bookTitle,
        author: _authorController.text.isEmpty ? 'Неизвестен' : _authorController.text,
        bookType: bookType,
        fileFolderPath: '',
        fileFormat: '',
        fileSize: fileSize,
        addedDate: DateTime.now(),
        lastDateOpen: DateTime.now(),
        totalPages: 1,
        isFavorite: false,
        tags: [],
        volumes: [],
      );

      bookId = await booksTable.insertBook(newBook);
      newBook.id = bookId;
      print("AddBookDialog newBook.id $bookId");

      bool importSuccess = false;
      BookContentResult? importResult;

      try {
        importResult = await BookContentImporter.importContent(
          book: newBook,
          sourceFilePath: _selectedFilePath!,
          availableSize: availableSize!,
          nameBook: bookTitle,
        );

        newBook.tags = [importResult.fileFormat.substring(1), ..._tags];
        newBook.fileFormat = importResult.fileFormat;
        newBook.totalPages = importResult.totalPages;
        newBook.volumes = importResult.bookVolumes;
        newBook.fileFolderPath = importResult.fileFolderPath;
        newBook.fileSize = importResult.filseSize;

        if (newBook.volumes.isNotEmpty) {
          // 7.1. Сохраняем Тома
          await volumesTable.insertVolumes(newBook.volumes, newBook.id!);

          // 7.2. Сохраняем Главы
          for (final volume in newBook.volumes) {
            if (volume.id != null && volume.chapters.isNotEmpty) {
              await chapterTable.insertChapters(volume.chapters, volume.id!);
            }
          }
        }

        await booksTable.updateBook(newBook);
        importSuccess = true;

      } catch (e) {
        // ОШИБКА ИМПОРТА - ВЫПОЛНЯЕМ ОТКАТ
        print('❌ Ошибка импорта: $e');

        // 1. Удаляем книгу из БД
        if (bookId != null) {
          try {
            await booksTable.deleteBook(bookId);
            print('✅ Книга удалена из БД после ошибки импорта');
          } catch (deleteError) {
            print('⚠️ Не удалось удалить книгу из БД: $deleteError');
          }
        }

        // 2. Удаляем файлы книги (если они были созданы)
        if (newBook.fileFolderPath.isNotEmpty) {
          try {
            final bookDir = Directory(newBook.fileFolderPath);
            if (await bookDir.exists()) {
              await bookDir.delete(recursive: true);
              print('✅ Файлы книги удалены после ошибки импорта');
            }
          } catch (fileError) {
            print('⚠️ Не удалось удалить файлы книги: $fileError');
          }
        }

        // 3. Показываем ошибку пользователю
        if (!mounted) return;
        AppGlobals.showError('Ошибка импорта книги: ${e.toString()}');
        return;
      }

      // УСПЕШНЫЙ ИМПОРТ
      if (!mounted) return;
      AppGlobals.showSuccess('Книга \"${newBook.title}\" успешно добавлена!');
      widget.onBookAdded(newBook);
      Navigator.pop(context);

    } catch (e) {
      // ОБЩАЯ ОШИБКА (не связанная с импортом)
      if (context.mounted) {
        Navigator.pop(context); // Закрываем индикатор
      }
      AppGlobals.showError('Ошибка: ${e.toString()}');
      print('Ошибка: ${e.toString()}');
    }
  }

  static void _showFullScreenContent(StringBuffer buffer, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Содержимое EPUB'),
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SelectableText( // ← Можно выделять и копировать текст
              buffer.toString(),
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}