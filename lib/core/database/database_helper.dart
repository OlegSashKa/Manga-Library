import 'dart:async';
import 'dart:io';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as downloadsfolder;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if(_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mangalibrary_book.db');
    return await openDatabase(
      path, version: 1, onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        bookType TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_format TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        current_page INTEGER DEFAULT 0,
        total_pages INTEGER DEFAULT 0,
        progress REAL DEFAULT 0.0,
        cover_image_path TEXT,
        status TEXT DEFAULT 'planned',
        added_date INTEGER NOT NULL,
        last_date_open INTEGER NOT NULL,
        reading_time INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        tags TEXT,
        current_chapter_index INTEGER DEFAULT 0
    )
    ''');
    await db.execute('''
      CREATE TABLE chapters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        start_page INTEGER NOT NULL,
        end_page INTEGER,
        current_page INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        read_time INTEGER,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> exportEverythingToDownloads() async {
    print('🚀 НАЧИНАЕМ ПОЛНЫЙ ЭКСПОРТ БИБЛИОТЕКИ...');

    try {
      // 1. Экспортируем базу данных
      print('📀 ЭКСПОРТ БАЗЫ ДАННЫХ...');
      final String dbPath = await exportDatabaseToDownloads();
      print('✅ БАЗА ДАННЫХ ЭКСПОРТИРОВАНА: $dbPath');

      // 2. Экспортируем все книги
      print('📚 ЭКСПОРТ КНИГ...');
      await FileService.exportBooksToDownloadsSimple();

      print('🎉 ВСЯ БИБЛИОТЕКА УСПЕШНО ЭКСПОРТИРОВАНА!');

    } catch (e) {
      print('💥 ОШИБКА ЭКСПОРТА: $e');
      rethrow;
    }
  }

  /// Экспортирует базу данных в папку загрузок (Downloads)
  ///
  /// Этот метод выполняет следующие действия:
  /// 1. Получает путь к исходной базе данных приложения
  /// 2. Создает папку для экспорта в Downloads если её нет
  /// 3. Копирует файл базы данных с новым именем
  /// 4. Возвращает путь к экспортированному файлу
  Future<String> exportDatabaseToDownloads() async {
    try {
      // 1. Получаем путь к исходной БД
      final databasesPath = await getDatabasesPath();
      final sourceDatabasePath = join(databasesPath, 'mangalibrary_book.db');
      final sourceFile = File(sourceDatabasePath);
      bool fileExists = await sourceFile.exists();

      print('🟡 Файл БД существует: $fileExists');
      print('🟡 Путь к файлу: $sourceDatabasePath');

      // 2. Получаем папку загрузок устройства через библиотеку
      Directory downloadDirectory = await downloadsfolder.getDownloadDirectory();
      if (downloadDirectory == null) {
        throw Exception('Не удалось получить папку загрузок');
      }
      print('🟡 Папка загрузок: $downloadDirectory');

      // 3. Создаем папку для бэкапов внутри папки загрузок
      final backupFolder = Directory(join(downloadDirectory.path, 'MangaLibrary_Backup'));
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      print('🟡 Путь для бэкапа: ${backupFolder.path}');

      // 4. Формируем конечный путь с именем файла
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportedFileName = 'mangalibrary_book_backup_$timestamp.db';
      final exportedDatabasePath = join(backupFolder.path, exportedFileName);
      print('🟡 Конечный путь: $exportedDatabasePath');

      // 5. Копируем файл
      await sourceFile.copy(exportedDatabasePath);
      return exportedDatabasePath; // Возвращаем полный путь для отображения

    } catch (e) {
      print('Ошибка экспорта: $e');
      throw Exception('Не удалось экспортировать базу: $e');
    }
  }

  /// Получает информацию о текущей базе данных
  ///
  /// Возвращает Map с информацией о размере файла и пути
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final databasesPath = await getDatabasesPath();
      final databasePath = join(databasesPath, 'mangalibrary_book.db');
      final databaseFile = File(databasePath);

      if (await databaseFile.exists()) {
        final fileStat = await databaseFile.stat();
        return {
          'path': databasePath,
          'size': fileStat.size,
          'exists': true,
        };
      } else {
        return {
          'path': databasePath,
          'size': 0,
          'exists': false,
        };
      }
    } catch (e) {
      throw Exception('Не удалось получить информацию о базе данных: $e');
    }
  }

  /// Проверяет доступность папки загрузок для записи
  ///
  /// Создает тестовый файл чтобы убедиться что есть разрешение на запись
  Future<bool> checkDownloadsAccess() async {
    try {
      Directory? downloadsDirectory;

      if (Platform.isAndroid) {
        downloadsDirectory = await getExternalStorageDirectory();
        if (downloadsDirectory != null) {
          // Проверяем разные возможные пути к Downloads
          final possiblePaths = [
            join(downloadsDirectory.path, 'Download'),
            join(downloadsDirectory.path, 'Downloads'),
            downloadsDirectory.path,
          ];

          for (final possiblePath in possiblePaths) {
            final dir = Directory(possiblePath);
            if (await dir.exists() || await _canCreateDirectory(possiblePath)) {
              downloadsDirectory = dir;
              break;
            }
          }
        }
      } else if (Platform.isIOS) {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory == null) return false;

      // Пробуем создать тестовый файл
      final testFile = File(join(downloadsDirectory.path, 'test_write_permission.txt'));
      await testFile.writeAsString('test');
      await testFile.delete();

      return true;
    } catch (e) {
      print('Нет доступа к папке загрузок: $e');
      return false;
    }
  }

  /// Вспомогательный метод для проверки возможности создания директории
  Future<bool> _canCreateDirectory(String path) async {
    try {
      final dir = Directory(path);
      await dir.create(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }
}
