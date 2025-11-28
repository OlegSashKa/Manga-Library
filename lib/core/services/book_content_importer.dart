import 'dart:io';
import 'package:epub_pro/epub_pro.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/utils/textPaginator.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:path/path.dart' as path;
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:filesize/filesize.dart';

class BookContentResult {
  final String fileFolderPath;
  final String fileFormat;
  final List<BookVolume> bookVolumes;
  final int totalPages;
  final int filseSize;

  BookContentResult({
    required this.fileFolderPath,
    required this.fileFormat,
    required this.bookVolumes,
    required this.totalPages,
    required this.filseSize,
  });
}

class BookContentImporter {
  // =======================================================
  // 💡 ГЛАВНЫЙ МЕТОД ИМПОРТА
  // =======================================================
  static Future<BookContentResult> importContent({
    required Book book,
    required String sourceFilePath,
    required Map<String, double> availableSize,
    required nameBook,
  }) async {
    // 1. Создаем корневую папку книги
    String nameFile = FileService.safePathName(nameBook);
    final pathToBooks = await FileService.getBooksDirectory();

    final bookFolderPath = path.join(pathToBooks.path, nameFile);

    book.fileFolderPath = bookFolderPath;

    final fileFormat = path.extension(sourceFilePath).toLowerCase();
    List<BookVolume> newBookVolumes = [];
    if (fileFormat == '.txt') {
      newBookVolumes = await _processTxtFile(book, sourceFilePath, availableSize);
    } else if (fileFormat == '.epub') {
      newBookVolumes = await _processEpubFile(book, sourceFilePath, availableSize);
    } else {
      throw Exception('Формат файла $fileFormat не поддерживается для импорта контента.');
    }

    return BookContentResult(
        fileFolderPath: bookFolderPath,
        fileFormat: fileFormat,
        bookVolumes: newBookVolumes,
        totalPages: book.totalPages,
        filseSize: await getDirectorySize(pathToBooks),
    );
  }
  static Future<int> getDirectorySize(Directory dir) async {
    try {
      int totalSize = 0;
      final entitiesList = await dir.list(recursive: true).toList();

      for (final entity in entitiesList) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('Ошибка при подсчете размера папки: $e');
      return 0;
    }
  }
  
  // =======================================================
  // 💡 ЛОГИКА ДЛЯ TXT-ФАЙЛА (Единственный Том, Единственная Глава)
  // =======================================================
  static Future<List<BookVolume>> _processTxtFile(Book book, String sourceFilePath, Map<String, double> availableSize) async {
    // 1. Чтение исходного файла
    final File sourceFile = File(sourceFilePath);
    String rawText = await sourceFile.readAsString();

    // 2. Форматирование текста (добавление красных строк)
    String formattedText = FileService.formatBookTextOptimized(rawText);

    final volumeTitle = 'Том 1';
    final chapterTitle = 'Глава 1';

    final chapterDirectory = await FileService.getBooksVolumeChapter(book, volumeTitle, chapterTitle);

    final destFile = File(path.join(chapterDirectory.path, "txt_1.txt"));
    await destFile.writeAsString(formattedText);

    // 3. Получаем настройки отображения из БД
    BookView bookView = BookView.instance;

    TextStyle textStyle = TextStyle(
      fontSize: bookView.fontSize,
      height: bookView.lineHeight,
      color: Color(bookView.textColor),
    );

    CoolTextPaginator paginator = CoolTextPaginator();

    PaginationResult paginationResult = paginator.paginate(
      text: formattedText,
      availableWidth: availableSize['width']!,
      availableHeight: availableSize['height']!,
      textStyle: textStyle,
    );

    int testTotalPage = paginationResult.countPage;

    // 1. Создание Модели Тома
    final volume = BookVolume(
      bookId: book.id!,
      title: volumeTitle,
      number: 1,
      startPage: 1,
      endPage: testTotalPage,
    );

    // 3. Создание Модели Главы
    final chapter = VolumeChapter(
      volumeId: 0, // Будет установлен после сохранения тома в БД
      title: chapterTitle,
      startPage: 1,
      endPage: testTotalPage,
      position: 1,
      fileFolderPath: destFile.path,
    );

    volume.chapters = [chapter];

    // 9. Устанавливаем общее количество страниц в книге
    book.totalPages = testTotalPage;

    return [volume];
  }

  // =======================================================
  // 💡 ЛОГИКА ДЛЯ EPUB-ФАЙЛА (Не-до рекурсивный обход)
  // =======================================================
  static Future<List<BookVolume>> _processEpubFile(Book book, String sourceFilePath, Map<String, double> availableSize) async { // Future<List<BookVolume>>

    BookView bookView = BookView.instance;

    TextStyle textStyle = TextStyle(
      fontSize: bookView.fontSize,
      height: bookView.lineHeight,
      color: Color(bookView.textColor),
    );

    EpubBook? epubBook;
    List<EpubChapter>? chaptersEpub;
    final inputBytes = await File(sourceFilePath).readAsBytes();
    bool useFallbackContent = false;

    try {
      epubBook = await EpubReader.readBook(inputBytes);
      chaptersEpub = epubBook.chapters ?? [];

      if (chaptersEpub.isEmpty) {
        // Если пакет прочитал, но не нашел ни одной главы (редко, но бывает)
        throw Exception("Пакет EpubReader не смог извлечь структуру глав.");
      }

    } catch (e) {
      // КРИТИЧЕСКИЙ FALLBACK: Ошибка парсинга навигации
      AppGlobals.showWarning("Ошибка чтения EPUB: Попытка собрать главы из манифеста.");
      print("Ошибка чтения EPUB (EpubReader), переход в режим Fallback: $e");
      useFallbackContent = true;
    }

    // 2. ОБРАБОТКА FALLBACK-РЕЖИМА
    if (useFallbackContent) {
      final archive = ZipDecoder().decodeBytes(inputBytes);
      final rawContentList = _extractAllContentFiles(archive);

      if (rawContentList.isEmpty) {
        throw Exception('Критическая ошибка: Не удалось извлечь ни один контентный файл.');
      }

      // Создаем псевдо-главы из списка файлов для дальнейшей обработки
      chaptersEpub = rawContentList.map((item) {
        final contentFile = archive.findFile(item['href']!);

        // ВАЖНО: Мы не можем получить HTML Content через EpubReader,
        // но мы можем его симулировать, чтобы код ниже работал.
        return EpubChapter(
          title: item['id'] ?? path.basenameWithoutExtension(item['href']!),
          htmlContent: contentFile?.content.toString(), // Вставляем сырой HTML/XHTML
          subChapters: [],
          contentFileName: item['href'],
        );
      }).toList();
    }

    // 3. ОБРАБОТКА ГЛАВ (работает только если epubBook удалось прочитать)
    if (chaptersEpub == null || chaptersEpub.isEmpty) {
      return [];
    }

    int numChapter = 1;
    int currentPage = 0;
    final volumes = <BookVolume>[];

    for(final chapter in chaptersEpub) {
      final volumesChapters = <VolumeChapter>[];

      if (_isServiceChapter(chapter) || chapter.htmlContent == null) {
        continue;
      }

      String textContent = "";
      BookVolume volume = BookVolume(
        bookId: book.id!,
        title: "",
        number: numChapter,
        startPage: 0,
        endPage: 0,
      );

      int numSubChapter = 1;
      final volumeTitlePath = "Том_${FileService.formatWithLeadingZeros(numChapter, totalDigits: 4)}";
      final chapterTitlePath = "Глава_${FileService.formatWithLeadingZeros(numSubChapter, totalDigits: 4)}";

      try {
        final document = parse(chapter.htmlContent);
        textContent = document.body?.text ?? "[No text content]";
        if(!_hasRealContent(textContent)){
          continue;
        }

        String formattedText = FileService.formatBookTextOptimized(textContent); //textContent;

        final chapterDirectory = await FileService.getBooksVolumeChapter(book, volumeTitlePath, chapterTitlePath);

        final destFile = File(path.join(chapterDirectory.path, "epub_${FileService.formatWithLeadingZeros(numChapter, totalDigits: 4)}.txt"));
        await destFile.writeAsString(formattedText);

        currentPage++;

        volume.title = chapter.title ?? "Том $numChapter";
        volume.startPage = currentPage;
        volume.fileFolderPath = chapterDirectory.path;

        numChapter++;

        CoolTextPaginator paginator = CoolTextPaginator();
        PaginationResult paginationResult = paginator.paginate(
          text: formattedText,
          availableWidth: availableSize['width']!,
          availableHeight: availableSize['height']!,
          textStyle: textStyle,
        );

        currentPage += paginationResult.countPage - 1;

      }catch (e) {
        throw Exception('CHAPTER_HTML_PARSING_ERROR: $e');
      }

      final subChapters = chapter.subChapters ?? [];
      if (subChapters.isNotEmpty) {
        for (final subChapter in subChapters) {
          if (_isServiceChapter(subChapter) || subChapter.htmlContent == null) {
            continue;
          }
          try{
            final document = parse(subChapter.htmlContent);
            final textContentSub = document.body?.text ?? "[No text content]";

            if(!_hasRealContent(textContentSub)){
              continue;
            }

            String formattedSubText = FileService.formatBookTextOptimized(textContentSub);

            final subChapterTitlePath = subChapter.title ?? "Глава_${FileService.formatWithLeadingZeros(numSubChapter,totalDigits: 4)}";
            final chapterDirectory = await FileService.getBooksVolumeChapter(book, volumeTitlePath, subChapterTitlePath);
            final destFile = File(path.join(chapterDirectory.path, "epub_${FileService.formatWithLeadingZeros(numChapter)}_${FileService.formatWithLeadingZeros(numSubChapter, totalDigits: 4)}.txt"));

            await destFile.writeAsString(formattedSubText);

            CoolTextPaginator paginator = CoolTextPaginator();
            PaginationResult paginationResult = paginator.paginate(
              text: formattedSubText,
              availableWidth: availableSize['width']!,
              availableHeight: availableSize['height']!,
              textStyle: textStyle,
            );

            int testTotalPage = paginationResult.countPage;

            currentPage++;

            final chapter = VolumeChapter(
              volumeId: 0, // Будет установлен после сохранения тома в БД
              title: subChapter.title ?? "Глава $numSubChapter",
              startPage: currentPage,
              endPage: currentPage + testTotalPage - 1,
              position: numSubChapter,
              fileFolderPath: chapterDirectory.path,
            );

            numSubChapter++;

            currentPage += testTotalPage - 1;

            volumesChapters.add(chapter);
          }catch (e){
            throw Exception('SUBCHAPTER_HTML_PARSING_ERROR: $e');
          }
        } // for ( final subChapter in subChapters)
      }

      volume.endPage = currentPage;
      volume.chapters = volumesChapters;
      volumes.add(volume);
    } // for(final chapter in chaptersEpub)

    book.totalPages = currentPage;
    return volumes;
  }


  // 🔍 Вспомогательные методы для фильтрации
  static bool _isServiceChapter(EpubChapter chapter) {
    final title = chapter.title?.toLowerCase() ?? '';

    // Исключаем служебные главы
    final excludedTitles = [
      'titlepage', 'cover', 'copyright', 'contents',
      'toc', 'table of contents', 'front matter',
      'dedication', 'acknowledgments', 'preface'
    ];

    return excludedTitles.any((excluded) => title.contains(excluded));
  }

  static bool _hasRealContent(String text) { // if (chapter.htmlContent == null) return false;
    // Считаем что есть контент если больше 50 символов реального текста
    if (text.isEmpty) return false;

    return text.length > 50 &&
        !text.toLowerCase().contains('this page intentionally left blank');
  }

  static List<Map<String, String>> _findAndParseNavigation(Archive archive) {
    try {
      // 1. Находим container.xml для определения пути к OPF
      final containerFile = archive.findFile('META-INF/container.xml');
      if (containerFile == null) return [];

      final containerDoc = XmlDocument.parse(containerFile.content.toString());
      final rootFile = containerDoc.findAllElements('rootfile').first;
      final opfPath = rootFile.getAttribute('full-path');
      if (opfPath == null) return [];

      final opfFile = archive.findFile(opfPath);
      if (opfFile == null) return [];

      final opfDoc = XmlDocument.parse(opfFile.content.toString());

      // 2. Ищем EPUB 3 навигацию
      final navItem = opfDoc.findAllElements('item').firstWhere(
            (item) => item.getAttribute('properties') == 'nav',
      );

      if (navItem != null) {
        // Если найдено, это EPUB 3. Для полной работы нужно распарсить HTML.
        return [{ 'type': 'epub3', 'href': navItem.getAttribute('href')! }];
      }

      // 3. Резервный поиск NCX (EPUB 2)
      final ncxItem = opfDoc.findAllElements('item').firstWhere(
            (item) => item.getAttribute('media-type') == 'application/x-dtbook+xml',
      );

      if (ncxItem != null) {
        // Если найдено, это EPUB 2. Для полной работы нужно распарсить NCX XML.
        return [{ 'type': 'epub2', 'href': ncxItem.getAttribute('href')! }];
      }

      return [];
    } catch (e) {
      print("Ошибка при ручном поиске навигации: $e");
      return [];
    }
  }
  // 🔍 Вспомогательный метод для извлечения всех контентных файлов из манифеста OPF
  static List<Map<String, String>> _extractAllContentFiles(Archive archive) {
    try {
      final containerFile = archive.findFile('META-INF/container.xml');
      if (containerFile == null) return [];

      final containerDoc = XmlDocument.parse(containerFile.content.toString());
      final rootFile = containerDoc.findAllElements('rootfile').first;
      final opfPath = rootFile.getAttribute('full-path');
      if (opfPath == null) return [];

      final opfFile = archive.findFile(opfPath);
      if (opfFile == null) return [];

      // Чтение и очистка содержимого OPF перед парсингом!
      String opfContent = opfFile.content.toString();

      if (opfContent.startsWith('\uFEFF')) {
        opfContent = opfContent.substring(1);
      }

      // Обрезаем лишние пробелы/переносы в начале и конце
      final opfDoc = XmlDocument.parse(opfContent.trim());

      final contentFiles = <Map<String, String>>[];
      final opfDirectory = opfPath.substring(0, opfPath.lastIndexOf('/') + 1);

      // Ищем все элементы в <manifest>
      for (final item in opfDoc.findAllElements('item')) {
        final mediaType = item.getAttribute('media-type') ?? '';

        // Ищем только контент (XHTML, HTML, HTA)
        if (mediaType.contains('xhtml') || mediaType.contains('html')) {
          final id = item.getAttribute('id') ?? '';
          final href = item.getAttribute('href') ?? '';

          // Исключаем служебные файлы, если они не помечены как nav (чтобы не парсить toc.xhtml)
          if ((mediaType.contains('xhtml') || mediaType.contains('html')) && id != 'ncx') {
            // Убедиться, что это не файл стиля и не обложка
            if (!mediaType.contains('css') && !item.getAttribute('properties').toString().contains('cover')) {
              // Добавляем файл
            }
          }
        }
      }
      return contentFiles;
    } catch (e) {
      print("Ошибка при извлечении контентных файлов из OPF: $e");
      return [];
    }
  }
}