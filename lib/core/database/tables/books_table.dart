import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/core/database/tables/volume_table.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import '../../../domain/models/book.dart';

class BooksTable{
  final DatabaseHelper dbHelper = DatabaseHelper();
  final VolumesTable _volumesTable = VolumesTable();
  final ChapterTable _chapterTable = ChapterTable();

  Future<Book> getFullBookDetails(int bookId) async {
    // Для чистоты кода, основной запрос к БД делаем в getBookById
    final Book? book = await getBookById(bookId);

    if (book == null) {
      throw Exception('Book with ID $bookId not found in database.');
    }

    print('📚 BOOKS_TABLE - getFullBookDetails:');
    print('📚 Book loaded: ${book.title}');
    print('📚 Volumes after hydration: ${book.volumes.length}');

    for (final volume in book.volumes) {
      print('📚 Volume: ${volume.title}, chapters: ${volume.chapters.length}');
    }

    return book;
  }

  Future<int> insertBook(Book book) async {
    final db = await dbHelper.database;

    int bookId;

    if (book.id == null) {
      // Новая книга - вставляем и получаем ID
      bookId = await db.insert('books', book.toMap());
    } else {
      // Книга с ID - проверяем существование
      final existingBook = await getBookById(book.id!);
      if (existingBook == null) {
        bookId = await db.insert('books', book.toMap());
      } else {
        // Если существует - обновляем и возвращаем ID
        await updateBook(book);
        return book.id!;
      }
    }
    return bookId;
  }

  Future<void> _hydrateBook(Book book) async {
    if (book.id == null) return;

    // print('💧 BOOKS_TABLE - _hydrateBook for book: ${book.title}');

    // 1. Загружаем тома
    final List<BookVolume> volumes = await _volumesTable.getVolumesByBookId(book.id!);
    // print('💧 Loaded volumes: ${volumes.length}');

    // 2. Загружаем главы для каждого тома и делаем инъекцию ссылок
    for (final volume in volumes) {
      final chapters = await _chapterTable.getChaptersByVolumeId(volume.id!);
      // print('💧 Volume "${volume.title}": loaded ${chapters.length} chapters');

      // Инъекция ссылки на родительский Том в Главу
      for (final chapter in chapters) {
        chapter.volume = volume;
        // print('💧   Chapter: ${chapter.title}, startPage: ${chapter.startPage}, position: ${chapter.position}');
      }

      volume.chapters = chapters;
      volume.book = book;
    }

    book.volumes = volumes;
    // print('💧 Hydration completed. Total volumes: ${book.volumes.length}');
  }

  Future<List<Book>> getAllBooks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> bookMaps = await db.query(
      'books',
    );

    List<Book> books = bookMaps.map((map) => Book.fromMap(map)).toList();

    // 💡 ГИДРАТАЦИЯ ВСЕХ КНИГ
    for (final book in books) {
      await _hydrateBook(book);
    }
    return books;
  }

  Future<Book?> getBookById(int id) async{
    final db = await dbHelper.database;
    final List<Map<String,dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    final Book book = Book.fromMap(maps.first);

    // 💡 ГИДРАТАЦИЯ ОДНОЙ КНИГИ
    await _hydrateBook(book);

    return book;
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


  Future<int> updateBook(Book book) async {
    final db = await dbHelper.database;

    int result = await db.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id]
    );

    if (book.volumes.isNotEmpty) {
      // 💡 ИЗМЕНЕНИЕ: Обновляем тома, а внутри них главы
      await _volumesTable.updateVolumes(book.volumes);
      for (final volume in book.volumes) {
        if (volume.chapters.isNotEmpty) {
          await _chapterTable.updateChapters(volume.chapters);
        }
      }
      // print('✅ [BOOKS_TABLE] Обновлена информация о томах и главах.');
    }

    // print('✅ [BOOKS_TABLE] Книга обновлена. Строк изменено: $result');
    return result;
  }

  Future<int>? updateBookField({
    required int bookId,
    required String fieldName,
    required dynamic value,
  }) async {
    final db = await dbHelper.database;

    return await db.update(
      'books',
      {fieldName: value},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await dbHelper.database;

// 💡 ИЗМЕНЕНИЕ: Удаление томов (удаление глав произойдет каскадно)
//     int volumesDeleted = await _volumesTable.deleteVolumesByBookId(id);
    // print('✅ [BOOKS_TABLE] Удалено $volumesDeleted томов для книги ID: $id');

    // BookCacheService().removeFromCache(id); //TODO возможно релизую если время будет
//     print('🧹 Книга ID: $id удалена из кэша');

    return await db.delete(
        'books',
        where: 'id = ?',
        whereArgs: [id]
    );
  }
}