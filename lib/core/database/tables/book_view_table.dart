import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/core/utils/book_page_updater.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:sqflite/sqflite.dart';

class BookViewTable{
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static Future<BookView> getSettings() async {
    final db = await DatabaseHelper().database;
    final maps = await db.query('book_view_settings', limit: 1);

    if (maps.isEmpty) {
      return BookView.defaultSettings();
    }

    return BookView.fromMap(maps.first);
  }

  // Обновить настройки
  static Future<void> updateSettings(BookView bookView) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'book_view_settings',
      bookView.toMap(),
      where: 'id = ?',
      whereArgs: [bookView.id],
    );
  }

  Future<int> deleteBookView(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'book_view_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateBookViewField({
    required String fieldName,
    required dynamic value,
  }) async {
    final db = await DatabaseHelper().database;

    // Получаем текущую запись (предполагаем, что у нас только одна запись с id=1)
    final maps = await db.query('book_view_settings', limit: 1);
    if (maps.isEmpty) return;

    final currentId = maps.first['id'];

    await db.update(
      'book_view_settings',
      {fieldName: value},
      where: 'id = ?',
      whereArgs: [currentId],
    );
  }

  static Future<void> updateSettingsWithPageRecalculation(BookView bookView, BuildContext context) async {
    await updateSettings(bookView);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Настройки сохранены. Начинается пересчёт страниц...'),
          duration: Duration(seconds: 1),
        )
    );

    Future.delayed(Duration(seconds: 1), (){
      BookPageUpdater.recalculateAllBooksPages(context, null).then((_){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пересчёт страниц завершён!'),
              backgroundColor: Colors.green,
            )
        );
      }).catchError((e){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка пересчёта страниц: $e'),
              backgroundColor: Colors.red,
            )
        );
      });
    });
  }
}