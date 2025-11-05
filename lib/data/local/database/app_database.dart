import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../entities/manga_entity.dart';

class AppDatabase  {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'manga_library.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE manga(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        coverUrl TEXT,
        volume INTEGER NOT NULL,
        progress REAL NOT NULL,
        tagsJson TEXT NOT NULL,
        status TEXT NOT NULL,
        currentPage INTEGER NOT NULL,
        totalPages INTEGER NOT NULL,
        nextChapterTimestamp INTEGER,
        type TEXT NOT NULL,
        createdAtTimestamp INTEGER NOT NULL
      )
    ''');
  }
}