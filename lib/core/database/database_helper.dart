import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/file_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as downloadsfolder;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Future<void> initialize() async {
    await _instance.database; // Просто обращаемся к геттеру
  }

  Future<Database> get database async {
    if(_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mangalibrary_book.db');
    return await openDatabase(
        path,
        version: 3,
        onCreate: _createTables,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        }
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
  CREATE TABLE books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    author TEXT,
    bookType TEXT NOT NULL,
    file_folder_path TEXT NOT NULL,
    file_format TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    current_page INTEGER DEFAULT 1,
    total_pages INTEGER DEFAULT 1,
    last_symbol_index INTEGER DEFAULT 0,
    cover_image_path TEXT,
    status TEXT DEFAULT 'planned',
    added_date INTEGER NOT NULL,
    last_date_open INTEGER NOT NULL,
    reading_time INTEGER DEFAULT 0,
    is_favorite INTEGER DEFAULT 0,
    tags TEXT
  )
''');
    await db.execute('''
    CREATE TABLE chapters(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      volume_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      start_page INTEGER NOT NULL,
      end_page INTEGER DEFAULT 0,
      is_read TEXT DEFAULT 'planned',
      read_time INTEGER DEFAULT 0,
      position INTEGER DEFAULT 0,
      file_folder_path TEXT NOT NULL,
      FOREIGN KEY (volume_id) REFERENCES volumes (id) ON DELETE CASCADE
    )
''');
    await db.execute('''
  CREATE INDEX idx_chapters_volume_id ON chapters(volume_id)
''');
    await db.execute('''
  CREATE TABLE volumes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    number INTEGER NOT NULL,
    file_folder_path TEXT DEFAULT NULL,
    start_page INTEGER NOT NULL,
    end_page INTEGER,
    FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
  )
''');
    await db.execute('''
  CREATE INDEX idx_volumes_book_id ON volumes(book_id)
''');
    await db.execute('''
      CREATE TABLE book_view_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        font_size REAL NOT NULL DEFAULT 16.0,
        line_height REAL NOT NULL DEFAULT 1.5,
        background_color INTEGER NOT NULL DEFAULT 4294967295,
        text_color INTEGER NOT NULL DEFAULT 4278190080
      )
    ''');
    try {
      await db.insert('book_view_settings', {
        'id': 1,
        'font_size': 16.0,
        'line_height': 1.5,
        'background_color': Colors.white.toARGB32(),
        'text_color': Colors.black.toARGB32(),
      });
    } catch (e) {
      // Игнорируем ошибку если запись уже существует
      print('⚠️ Запись настроек уже существует или ошибка: $e');
    }
  }

  Future<void> exportEverythingToDownloads() async {
    // print('🚀 НАЧИНАЕМ ПОЛНЫЙ ЭКСПОРТ БИБЛИОТЕКИ...');

    try {
      // 1. Экспортируем базу данных
      final String dbPath = await exportDatabaseToDownloads();

      // 2. Экспортируем все книги
      await FileService.exportBooksToDownloadsSimple();

    } catch (e) {
      // print('💥 ОШИБКА ЭКСПОРТА: $e');
      rethrow;
    }
  }

  Future<String> exportDatabaseToDownloads() async {
    try {
      // 1. Получаем путь к исходной БД
      final databasesPath = await getDatabasesPath();
      final sourceDatabasePath = join(databasesPath, 'mangalibrary_book.db');
      final sourceFile = File(sourceDatabasePath);
      bool fileExists = await sourceFile.exists();

      // 2. Получаем папку загрузок устройства через библиотеку
      Directory downloadDirectory = await downloadsfolder.getDownloadDirectory();

      // 3. Создаем папку для бэкапов внутри папки загрузок
      final backupFolder = Directory(join(downloadDirectory.path, 'MangaLibrary_Backup'));
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      // 4. Формируем конечный путь с именем файла
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportedFileName = 'mangalibrary_book_backup_$timestamp.db';
      final exportedDatabasePath = join(backupFolder.path, exportedFileName);

      // 5. Копируем файл
      await sourceFile.copy(exportedDatabasePath);
      return exportedDatabasePath; // Возвращаем полный путь для отображения

    } catch (e) {
//       print('Ошибка экспорта: $e');
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
}
