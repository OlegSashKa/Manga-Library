import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mangalibrary/enums/book_enums.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as downloadsfolder;

class BookImportResult{
  final String bookPath;     // Путь к папке книги
  final String filePath;     // Путь к скопированному файлу
  final BookType bookType;   // Определенный тип книги
  final int fileSize;        // Размер файла в байтах

  BookImportResult({
    required this.bookPath,
    required this.filePath,
    required this.bookType,
    required this.fileSize,
  });
}

class FileService{
  static Future<Directory> getBooksDirectory() async {

    final appDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory('${appDir.path}/books');

    if(!await bookDir.exists()){
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  static String _sanitizeFileName(String name) {
    // Заменяем недопустимые символы в именах файлов на _
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static Future<Directory> getBookDirectory(String bookTitle) async {
    final booksDir = await getBooksDirectory();
    final bookDir = Directory('${booksDir.path}/${_sanitizeFileName(bookTitle)}');

    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  /// Просто копирует все книги в Downloads без лишней информации
  static Future<void> exportBooksToDownloadsSimple() async {
    print('🟡 НАЧИНАЕМ ЭКСПОРТ КНИГ В DOWNLOADS...');

    // 1. Получаем папку книг приложения
    final booksDir = await getBooksDirectory();
    print('🟡 Исходная папка: ${booksDir.path}');

    if (!await booksDir.exists()) {
      print('❌ Папка книг не существует!');
      return;
    }

    // 2. Получаем папку Downloads
    final Directory downloadDirectory;
    downloadDirectory = await downloadsfolder.getDownloadDirectory();

    // 3. Создаем папку для экспорта
    final exportDir = Directory(path.join(downloadDirectory.path, 'MangaLibrary_Books'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
      print('🟡 Создана папка экспорта: ${exportDir.path}');
    }

    // 4. Копируем ВСЕ содержимое папки books
    await _copyAllContents(booksDir, exportDir);

    print('✅ ЭКСПОРТ КНИГ ЗАВЕРШЕН!');
  }

  /// Копирует все содержимое папки с детальным логированием
  static Future<void> _copyAllContents(Directory sourceDir, Directory targetDir) async {
    print('🟡 Начинаем копирование из ${sourceDir.path} в ${targetDir.path}');

    try {
      // Получаем ВСЕ файлы и папки
      final List<FileSystemEntity> allEntities = await sourceDir.list(recursive: true).toList();
      print('🟡 Найдено элементов: ${allEntities.length}');

      int filesCopied = 0;
      int foldersCreated = 0;

      for (final entity in allEntities) {
        // Получаем относительный путь (без исходной папки)
        final relativePath = path.relative(entity.path, from: sourceDir.path);
        final targetPath = path.join(targetDir.path, relativePath);

        if (entity is File) {
          // КОПИРУЕМ ФАЙЛ
          try {
            // Создаем папку для файла если нужно
            final parentDir = Directory(path.dirname(targetPath));
            if (!await parentDir.exists()) {
              await parentDir.create(recursive: true);
              foldersCreated++;
              print('📁 СОЗДАНА ПАПКА: ${parentDir.path}');
            }

            // Копируем файл
            await entity.copy(targetPath);
            filesCopied++;
            print('✅ СКОПИРОВАН ФАЙЛ: ${entity.path} -> $targetPath');

          } catch (e) {
            print('❌ ОШИБКА КОПИРОВАНИЯ ФАЙЛА ${entity.path}: $e');
          }

        } else if (entity is Directory) {
          // СОЗДАЕМ ПАПКУ
          try {
            final targetFolder = Directory(targetPath);
            if (!await targetFolder.exists()) {
              await targetFolder.create(recursive: true);
              foldersCreated++;
              print('📁 СОЗДАНА ПАПКА: $targetPath');
            }
          } catch (e) {
            print('❌ ОШИБКА СОЗДАНИЯ ПАПКИ $targetPath: $e');
          }
        }
      }

      print('✅ КОПИРОВАНИЕ ЗАВЕРШЕНО: файлов=$filesCopied, папок=$foldersCreated');

    } catch (e) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА ПРИ КОПИРОВАНИИ: $e');
      rethrow;
    }
  }

  // ОПРЕДЕЛЯЕМ ТИП КНИГИ ПО РАСШИРЕНИЮ ФАЙЛА
  static BookType _determineBookType(String filePath) {
    // path.extension получает расширение файла: .cbz, .epub и т.д.
    final extension = path.extension(filePath).toLowerCase();

    // switch проверяет расширение и возвращает соответствующий BookType
    switch (extension) {
      case '.cbz':
      case '.cbr':
      case '.zip':
        return BookType.manga;  // Это манга
      case '.epub':
      case '.txt':
      case '.pdf':
      case '.fb2':
        return BookType.text;   // Это текстовая книга
      default:
        return BookType.text;   // По умолчанию считаем текстовой
    }
  }

  static Future<BookImportResult> importBook(String sourcePath, String bookTitle) async {
    try{
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Исходный файл не существует');
      }
      // Определяем тип книги
      final BookType bookType = _determineBookType(sourcePath);
      // Получаем папку для этой книги
      final bookDir = await getBookDirectory(bookTitle);

      // Копируем файл в папку книги
      final fileName = path.basename(sourcePath); // Получаем имя файла
      final destinationPath = '${bookDir.path}/$fileName';

      final destinationFile = File(destinationPath);
      if (await destinationFile.exists()) {
        throw Exception('Файл "$fileName" уже существует в библиотеке');
      }

      final copiedFile = await sourceFile.copy(destinationPath);

      clearFilePickerCache();

      // Получаем размер файла
      final fileSize = await copiedFile.length();

      // ЕСЛИ ЭТО МАНГА - создаем папку chapters
      if (bookType == BookType.manga) {
        await _createChaptersDirectory(bookTitle);
      }
      return BookImportResult(
        bookPath: bookDir.path,
        filePath: copiedFile.path,
        bookType: bookType,
        fileSize: fileSize,
      );
    }catch (e) {
      print('Ошибка импорта книги: $e');
      rethrow; // Перебрасываем ошибку дальше
    }
  }

  // Создаем папку chapters для манги
  static Future<Directory> _createChaptersDirectory(String bookTitle) async {
    final bookDir = await getBookDirectory(bookTitle);
    final chaptersDir = Directory('${bookDir.path}/chapters');

    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }
    return chaptersDir;
  }

  static Future<Map<String, dynamic>> getBookFileInfo(String bookTitle) async {
    final bookDir = await getBookDirectory(bookTitle);
    final files = bookDir.listSync(); // Получаем список файлов в папке

    // Ищем основной файл книги (первый файл в папке)
    for (var file in files) {
      if (file is File) {
        final filePath = file.path;
        return {
          'filePath': filePath,
          'fileFormat': path.extension(filePath).replaceFirst('.', ''), // Убираем точку
          'fileSize': await file.length(),
          'bookType': _determineBookType(filePath),
        };
      }
    }

    throw Exception('Файл книги не найден в папке $bookTitle');
  }

  static Future<void> clearFilePickerCache() async {
    try {
      // Получаем корневую директорию приложения
      final appDir = await getApplicationDocumentsDirectory();
      final appPath = appDir.parent.path; // Поднимаемся на уровень выше

      final cacheDir = Directory('$appPath/cache/file_picker');
      print("путь до кэша: ${cacheDir.path}");
      print("путь до кэша существует: ${await cacheDir.exists()}");

      if (await cacheDir.exists()) {
        // Сначала посмотрим что внутри
        final files = await cacheDir.list(recursive: true).toList();
        print("Найдено файлов/папок в кеше: ${files.length}");

        await cacheDir.delete(recursive: true);
        print('✅ Кеш файлового пикера очищен');
      } else {
        print('❌ Папка кеша не найдена');
      }
    } catch (e) {
      print('❌ Ошибка очистки кеша файлового пикера: $e');
    }
  }

}