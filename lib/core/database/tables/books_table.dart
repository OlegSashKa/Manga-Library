import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import '../../../domain/models/book.dart';

class BooksTable{
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<int> insertBook(Book book) async {
    final db = await dbHelper.database;

    // Создаем копию книги без id для новой записи
    if (book.id == null) {
      return await db.insert('books', book.toMap());
    } else {
      // Если id указан, проверяем не существует ли уже книга с таким id
      final existingBook = await getBookById(book.id!);
      if (existingBook == null) {
        return await db.insert('books', book.toMap());
      } else {
        // Если существует, обновляем
        return await updateBook(book);
      }
    }
  }

  Future<List<Book>> getAllBooks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('books');
    return List.generate(maps.length, (i){
      return Book.fromMap(maps[i]);
    });
  }

  Future<Book?> getBookById(int id) async{
    final db = await dbHelper.database;
    final List<Map<String,dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if(maps.isNotEmpty){
      return Book.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> doesBookExist(String title) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title = ?',
      whereArgs: [title],
    );
    return maps.isNotEmpty;
  }

  Future<bool> doesFileExist(String filePath) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
    return maps.isNotEmpty;
  }

  Future<int> updateBook(Book book) async {
    final db = await dbHelper.database;
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id]
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
        'books',
        where: 'id = ?',
        whereArgs: [id]
    );
  }
}