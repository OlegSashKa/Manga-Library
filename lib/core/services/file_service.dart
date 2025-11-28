import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:mangalibrary/domain/models/book.dart';
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

  // ОПРЕДЕЛЯЕМ ТИП КНИГИ ПО РАСШИРЕНИЮ ФАЙЛА
  static BookType determineBookType(String filePath) {
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
      case '.fb2':
        return BookType.text;
      case '.pdf':// Это текстовая книга
      default:
        return BookType.text;   // По умолчанию считаем текстовой
    }
  }

// 2. КОПИРОВАНИЕ ФАЙЛА ГЛАВЫ (Обновленный)
  static Future<File> copyChapterFile({
    required String sourceFilePath,
    required Book book,
    required String volumeTitle,
    required String chapterTitle,
    int fileIndex = 1, // Для сегментации, по умолчанию 1
  }) async {
    final targetPath = book.getChapterFilePath(
      volumeTitle: volumeTitle,
      chapterTitle: chapterTitle,
      fileIndex: fileIndex,
    );
    final sourceFile = File(sourceFilePath);

    if (!(await sourceFile.exists())) {
      throw FileSystemException('Исходный файл не найден: $sourceFilePath');
    }

    // Убеждаемся, что целевая папка главы существует: books/Книга/Том/Глава/
    final targetDir = Directory(path.dirname(targetPath));
    if (!(await targetDir.exists())) {
      await targetDir.create(recursive: true);
    }

    // Копируем файл
    final newFile = await sourceFile.copy(targetPath);
    return newFile;
  }

  static Future<String> readChapterContent({
    required Book book,
    required String volumeTitle,
    required String chapterTitle,
    int fileIndex = 1,
  }) async {
    final filePath = book.getChapterFilePath(
      volumeTitle: volumeTitle,
      chapterTitle: chapterTitle,
      fileIndex: fileIndex,
    );
    final file = File(filePath);

    if (!(await file.exists())) {
      throw FileSystemException('Файл главы не найден: $filePath');
    }

    return await file.readAsString();
  }

  static Future<Directory> getBooksDirectory() async {

    final appDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory('${appDir.path}/books');

    if(!await bookDir.exists()){
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  static Future<Directory> getBooksVolume(Book book, String titleVolume) async {

    final appDir = book.fileFolderPath;
    final bookDir = Directory('$appDir/$titleVolume');
    print("getBooksVolume bookDir^ $bookDir");

    if(!await bookDir.exists()){
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  static Future<Directory> getBooksVolumeChapter(Book book, String titleVolume, String titleChapter) async {

    final appDir = book.fileFolderPath;
    final bookDir = Directory('$appDir/${FileService.safePathName(titleVolume)}/${FileService.safePathName(titleChapter)}');

    if(!await bookDir.exists()){
      await bookDir.create(recursive: true);
    }
    return bookDir;
  }

  /// Просто копирует все книги в Downloads без лишней информации
  static Future<void> exportBooksToDownloadsSimple() async {
    // print('🟡 НАЧИНАЕМ ЭКСПОРТ КНИГ В DOWNLOADS...');

    // 1. Получаем папку книг приложения
    final booksDir = await getBooksDirectory();
    // print('🟡 Исходная папка: ${booksDir.path}');

    if (!await booksDir.exists()) {
      // print('❌ Папка книг не существует!');
      return;
    }

    // 2. Получаем папку Downloads
    final Directory downloadDirectory;
    downloadDirectory = await downloadsfolder.getDownloadDirectory();

    // 3. Создаем папку для экспорта
    final exportDir = Directory(path.join(downloadDirectory.path, 'MangaLibrary_Books'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
//       print('🟡 Создана папка экспорта: ${exportDir.path}');
    }

    // 4. Копируем ВСЕ содержимое папки books
    await _copyAllContents(booksDir, exportDir);
//
//     print('✅ ЭКСПОРТ КНИГ ЗАВЕРШЕН!');
  }

  static String safePathName(String name) {
    if (name.isEmpty) return 'unnamed';

    final _name = name.replaceAll(RegExp(r'[<>:"/\\|?*,.]'), '_')  // Основные запрещенные символы
        .replaceAll(RegExp(r"'"), '')          // Апострофы просто удаляем
        .replaceAll(RegExp(r'\s+'), '_')           // Пробелы в подчеркивания
        .trim();


    return _name.isNotEmpty ? _name.substring(0, min(50,_name.length)) : "unnamed";                          // Убираем пробелы по краям
  }

  /// Копирует все содержимое папки с детальным логированием
  static Future<void> _copyAllContents(Directory sourceDir, Directory targetDir) async {
//     print('🟡 Начинаем копирование из ${sourceDir.path} в ${targetDir.path}');

    try {
      // Получаем ВСЕ файлы и папки
      final List<FileSystemEntity> allEntities = await sourceDir.list(recursive: true).toList();
//       print('🟡 Найдено элементов: ${allEntities.length}');

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
//               print('📁 СОЗДАНА ПАПКА: ${parentDir.path}');
            }

            // Копируем файл
            await entity.copy(targetPath);
            filesCopied++;
//             print('✅ СКОПИРОВАН ФАЙЛ: ${entity.path} -> $targetPath');

          } catch (e) {
//             print('❌ ОШИБКА КОПИРОВАНИЯ ФАЙЛА ${entity.path}: $e');
          }

        } else if (entity is Directory) {
          // СОЗДАЕМ ПАПКУ
          try {
            final targetFolder = Directory(targetPath);
            if (!await targetFolder.exists()) {
              await targetFolder.create(recursive: true);
              foldersCreated++;
//               print('📁 СОЗДАНА ПАПКА: $targetPath');
            }
          } catch (e) {
//             print('❌ ОШИБКА СОЗДАНИЯ ПАПКИ $targetPath: $e');
          }
        }
      }
//
//       print('✅ КОПИРОВАНИЕ ЗАВЕРШЕНО: файлов=$filesCopied, папок=$foldersCreated');

    } catch (e) {
      // print('❌ КРИТИЧЕСКАЯ ОШИБКА ПРИ КОПИРОВАНИИ: $e');
      rethrow;
    }
  }


  static Future<void> deleteBookFiles(Book book) async {
    final bookDir = Directory(book.fileFolderPath);
    if (await bookDir.exists()) {
      await bookDir.delete(recursive: true);
      // print('✅ Папка книги "${book.title}" успешно удалена.');
    }
  }

  static Future<void> clearFilePickerCache() async {
    try {
      // Получаем корневую директорию приложения
      final appDir = await getApplicationDocumentsDirectory();
      final appPath = appDir.parent.path; // Поднимаемся на уровень выше

      final cacheDir = Directory('$appPath/cache/file_picker');

      if (await cacheDir.exists()) {
        // Сначала посмотрим что внутри
        final files = await cacheDir.list(recursive: true).toList();
//         print("Найдено файлов/папок в кеше: ${files.length}");

        await cacheDir.delete(recursive: true);
//         print('✅ Кеш файлового пикера очищен');
      } else {
//         print('❌ Папка кеша не найдена');
      }
    } catch (e) {
//       print('❌ Ошибка очистки кеша файлового пикера: $e');
    }
  }

  static Future<void> writeChapterFile({
    required String content,
    required Book book,
    required String volumeTitle,
    required String chapterTitle,
    required int fileIndex,
  }) async {
    final String chapterFolderPath = book.getChapterFolderPath(
      volumeTitle: volumeTitle,
      chapterTitle: chapterTitle,
    );
    final String chapterFilePath = path.join(chapterFolderPath, 'segment_$fileIndex.txt');

    // Создаем папку, если не существует
    await Directory(chapterFolderPath).create(recursive: true);

    // Записываем content в файл
    await File(chapterFilePath).writeAsString(content);
  }

  static String formatWithLeadingZeros(int number, {int totalDigits = 3}) {
    return number.toString().padLeft(totalDigits, '0');
  }

  static const String indent = '\u00A0\u00A0\u00A0\u00A0\u00A0';

  static String formatBookTextOptimized(String text) {
    if (text.isEmpty) return text;

    // 1. Очистка и Нормализация
    String cleanText = text
        .replaceAll('\r', '') // Убираем Windows-перенос
        .replaceAll('\t', ' ') // Убираем табуляцию
        .replaceAll(RegExp(r'[ \u00A0]+'), ' '); // Схлопываем множественные пробелы

    // 2. Разбиваем на строки и очищаем каждую от лишних пробелов по краям.
    List<String> lines = cleanText.split('\n').map((e) => e.trim()).toList();

    final buffer = StringBuffer();
    bool needsIndent = true;

    for (int i = 0; i < lines.length; i++) {
      String currentLine = lines[i];

      // 3. Обработка пустых строк (множественные \n в исходнике)
      if (currentLine.isEmpty) {
        if (!needsIndent) {
          buffer.write('\n'); // Добавляем фактический перенос
          needsIndent = true; // Устанавливаем флаг для отступа
        }
        continue;
      }

      // 4. Обработка начала нового абзаца (первая строка или после множественных \n)
      if (needsIndent) {
        if (buffer.isNotEmpty) buffer.write('\n'); // Если буфер не пуст, добавляем перенос
        buffer.write(indent);
        buffer.write(currentLine);
        needsIndent = false;
      } else {
        // 5. Обработка одиночного \n (склеить или начать новый абзац)
        String prevLine = lines[i - 1];

        if (_shouldStartNewParagraph(prevLine, currentLine)) {
          // Начинаем новый абзац
          buffer.write('\n');
          buffer.write(indent);
          buffer.write(currentLine);
        } else {
          // Склеиваем с пробелом
          buffer.write(' ');
          buffer.write(currentLine);
        }
      }
    }

    return buffer.toString();
  }

  // --- Вспомогательные функции ---

  /**
   * Принимает решение: должен ли одиночный \n превратиться в \n + отступ (true) или в пробел (false).
   */
  static bool _shouldStartNewParagraph(String prev, String curr) {
    if (prev.isEmpty) return true; // Страховка

    // 1. Проверка на Диалоги, Списки, Маркеры (Принудительный перенос)
    // Если новая строка начинается с тире, цифры с точкой, маркера.
    if (RegExp(r'^[—–-]|^\d+\.|^[•*]').hasMatch(curr)) {
      return true;
    }

    // 2. Проверка на Заголовки (Эвристика)
    // Если предыдущая строка вся в CAPS LOCK и короткая (вероятно, заголовок).
    bool isPrevCaps = prev == prev.toUpperCase() && prev != prev.toLowerCase();
    if (isPrevCaps && prev.length < 60) return true;

    // 3. Проверка конца предложения (Точка, Воскл. знак и т.д.)
    final lastChar = prev[prev.length - 1];
    const terminators = {'.', '!', '?', '…', '»', '"', '”'};

    bool endsWithTerminator = terminators.contains(lastChar);

    if (!endsWithTerminator) {
      // Если строка не кончается точкой/терминатором - склеиваем (пробел)
      return false;
    }

    // 4. Умная проверка Сокращений и Инициалов (Предотвращение ложного разрыва)
    // Если строка кончается на точку, но это "г." или "Д.Б." - это НЕ конец абзаца.
    if (_isAbbreviation(prev)) {
      return false;
    }

    // Если ничего из вышеперечисленного - считаем, что это конец предложения и нужен новый абзац.
    return true;
  }

  /**
   * Определяет, является ли последнее "слово" в строке сокращением или инициалами.
   */
  static bool _isAbbreviation(String line) {
    if (line.isEmpty) return false;

    // Извлекаем последнее "слово" (включая точку) для анализа.
    int lastSpace = line.lastIndexOf(' ');
    String candidate = (lastSpace == -1) ? line : line.substring(lastSpace + 1).trim();

    if (!candidate.endsWith('.')) {
      return false;
    }

    // Проверка на фиксированный список сокращений (Case-insensitive)
    const abbreviations = {
      // Русские
      'г.', 'ул.', 'д.', 'кв.', 'проф.', 'им.', 'т.', 'п.', 'с.', 'пос.', 'обл.', 'ст.', 'в.', 'гг.',
      'пр.', 'д-р.', 'кан.', 'доц.', 'см.', 'и т.д.', 'и т.п.', 'т.е.',
      // Английские
      'mr.', 'mrs.', 'dr.', 'ms.', 'jr.', 'sr.', 'p.', 's.', 'e.g.', 'i.e.', 'etc.'
    };
    if (abbreviations.contains(candidate.toLowerCase())) {
      return true;
    }

    // Проверка на инициалы (например, А. или А.С., F.W.)
    // Убираем точку в конце для чистой проверки:
    String noDotCandidate = candidate.substring(0, candidate.length - 1);

    // Ищем одну или две заглавные буквы (Кириллица [А-Я], Латиница [A-Z])
    if (RegExp(r'^[А-ЯA-Z]{1,2}$').hasMatch(noDotCandidate)) {
      return true;
    }

    return false;
  }
}