import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/core/services/page_calculator_service.dart';
import 'dart:io';

class BookPageUpdater {
  static Future<void> recalculateAllBooksPages(BuildContext context, Function(int current, int total)? onProgress,) async {
    try{
      print('🔄 НАЧИНАЕМ ПЕРЕСЧЁТ СТРАНИЦ ДЛЯ ВСЕХ КНИГ...');

      final booksTable = BooksTable();
      final allBooks = await booksTable.getAllBooks();
      final bookViewSettings = await BookViewTable.getSettings();

      final txtBooks = allBooks.where((book) => book.fileFormat == 'txt').toList();

      print('📚 Найдено txt-книг для пересчёта: ${txtBooks.length}');

      int updatedCount = 0;
      int processedCount = 0;

      final mediaQuery = MediaQuery.of(context);
      final appBarHeight = kToolbarHeight; // стандартная высота AppBar
      final statusBarHeight = mediaQuery.padding.top;
      final bottomPadding = mediaQuery.padding.bottom;

      final double availableHeight = mediaQuery.size.height
          - statusBarHeight
          - appBarHeight
          - bottomPadding
          - 32;

      final double availableWidth = mediaQuery.size.width - 32;

      for(Book book in allBooks){

        processedCount++;
        // Вызываем callback прогресса если передан
        onProgress?.call(processedCount, txtBooks.length);

        if(book.fileFormat == 'txt' && await File(book.filePath).exists()){
          try{
            final content = await  File(book.filePath).readAsString();

            final newTotalPages = PageCalculatorService.calculatePageCount(
              text: content,
              pageWidth: availableWidth,
              pageHeight: availableHeight,
              fontSize: bookViewSettings.fontSize,
              lineHeight: bookViewSettings.lineHeight,
              horizontalPadding: 16.0,
              verticalPadding: 16.0,
              fontFamily: 'Roboto',
            );
            // Обновляем только если количество страниц изменилось
            if (newTotalPages != book.totalPages) {
              await booksTable.updateBookField(
                bookId: book.id!,
                fieldName: 'total_pages',
                value: newTotalPages,
              );
              updatedCount++;

              print('📖 Обновлена книга "${book.title}": ${book.totalPages} → $newTotalPages страниц');
            }
          } catch (e) {
            print('⚠️ Ошибка пересчёта для книги "${book.title}": $e');
          }
        }
      }
      print('✅ ПЕРЕСЧЁТ ЗАВЕРШЁН: обновлено $updatedCount книг');
    }catch (e) {
      print('❌ ОШИБКА ПЕРЕСЧЁТА СТРАНИЦ: $e');
    }
  }
}