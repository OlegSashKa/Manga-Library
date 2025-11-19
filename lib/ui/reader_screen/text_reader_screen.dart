import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/core/utils/page_manager.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/ui/reader_screen/text_page_widget.dart';

class TextReaderScreen extends StatefulWidget {
  final Book book;

  const TextReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  String _textContent = '';
  bool _isLoading = true;
  bool _hasError = false;
  // bool _settingsLoaded = false; // ← ДОБАВЛЯЕМ ФЛА
  PageManager? _pageManager;
  bool _showAppBar = false;

  PageController? _pageController;

  BookView _bookView = BookView.defaultSettings();

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      _loadBookContent();
    });
  }

  Future<void> _loadSettings() async {
    try{
      final settings = await BookViewTable.getSettings();
      setState(() {
        _bookView = settings;
        // _settingsLoaded = true; // ← ОТМЕЧАЕМ ЧТО НАСТРОЙКИ ЗАГРУЖЕНЫ
      });
    }catch(e){
      print('Ошибка загрузки настроек: $e');
      setState(() {
        // _settingsLoaded = true; // ← ВСЕ РАВНО ОТМЕЧАЕМ КАК ЗАГРУЖЕННЫЕ
      });
    }
  }

  Future<void> _loadBookContent() async {
    try{
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final file = File(widget.book.filePath);

      if (await file.exists()) {
        final content = await file.readAsString();

        if (!mounted) return;

        setState(() {
          _textContent = content;
          _isLoading = false;
        });

        // 🔥 СОЗДАЕМ PAGE_MANAGER
        _pageManager = PageManager();
        _pageManager!.addListener(_onPagesUpdated);

      } else {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }

    } catch (e){
      print('Ошибка загрузки книги: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _onPagesUpdated() {
    if (!mounted) return;
    setState(() {
      // Обновляем UI когда страницы меняются
    });
  }

  void _changeLineHeight() {
    final double newLineHeight = _bookView.lineHeight <= 1 ? 1 : _bookView.lineHeight - 0.25;
    final updatedBookView = BookView(
      id: _bookView.id,
      fontSize: _bookView.fontSize,
      lineHeight: newLineHeight,
      backgroundColor: _bookView.backgroundColor,
      textColor: _bookView.textColor,
    );

    setState(() {
      _bookView = updatedBookView;
    });

    // Сохраняем настройки в базу (без глобального пересчёта)
    BookViewTable.updateSettings(updatedBookView);
  }

  void _changeLineLower() {
    final double newLineHeight = _bookView.lineHeight >= 5 ? 5 : _bookView.lineHeight + 0.25;

    final updatedBookView = BookView(
      id: _bookView.id,
      fontSize: _bookView.fontSize,
      lineHeight: newLineHeight,
      backgroundColor: _bookView.backgroundColor,
      textColor: _bookView.textColor,
    );

    setState(() {
      _bookView = updatedBookView;
    });

    // Сохраняем настройки в базу (без глобального пересчёта)
    BookViewTable.updateSettings(updatedBookView);
  }

  void _increaseFontSize() {
    final double newFontSize = _bookView.fontSize + 3 >= 32 ? 32 : _bookView.fontSize + 3;
    print("newFontSize " + newFontSize.toString());

    final updatedBookView = BookView(
      id: _bookView.id,
      fontSize: newFontSize,
      lineHeight: _bookView.lineHeight,
      backgroundColor: _bookView.backgroundColor,
      textColor: _bookView.textColor,
    );

    // Точечное обновление в базе
    setState(() {
      _bookView = updatedBookView;
    });

    // Сохраняем настройки в базу (без глобального пересчёта)
    BookViewTable.updateSettings(updatedBookView);
  }

  void _decreaseFontSize() {
    final double newFontSize = _bookView.fontSize - 3 <= 14 ? 14 : _bookView.fontSize - 3;
    print("newFontSize " + newFontSize.toString());
    final updatedBookView = BookView(
      id: _bookView.id,
      fontSize: newFontSize,
      lineHeight: _bookView.lineHeight,
      backgroundColor: _bookView.backgroundColor,
      textColor: _bookView.textColor,
    );

    setState(() {
      _bookView = updatedBookView;
    });

    // Сохраняем настройки в базу (без глобального пересчёта)
    BookViewTable.updateSettings(updatedBookView);
  }

  void _toggleDarkMode() {
    final newBackgroundColor = _bookView.getBackgroundColor == Colors.white
        ? Colors.black.toARGB32()
        : Colors.white.toARGB32();
    final newTextColor = _bookView.getTextColor == Colors.white
        ? Colors.black.toARGB32()
        : Colors.white.toARGB32();

    final updatedBookView = BookView(
      id: _bookView.id,
      fontSize: _bookView.fontSize,
      lineHeight: _bookView.lineHeight,
      backgroundColor: newBackgroundColor,
      textColor: newTextColor,
    );

    setState(() {
      _bookView = updatedBookView;
    });

    BookViewTable.updateSettings(updatedBookView);
  }

  @override
  Widget build(BuildContext context) {
    Color _backgroundColor = _bookView.getBackgroundColor;
    Color _textColor = _bookView.getTextColor;

    return Scaffold(

      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Основной контент БЕЗ отступов
          GestureDetector(
            onTap: _toggleAppBar,
            child: Container(
              color: _backgroundColor,
              width: double.infinity,
              height: double.infinity,
              child: _buildContent(),
            ),
          ),

          // AppBar с ограниченной высотой
          AnimatedOpacity(
            duration: Duration(milliseconds: 150),
            opacity: _showAppBar ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_showAppBar,
              child: Container(
                height: kToolbarHeight + MediaQuery.of(context).padding.top, // ← ОГРАНИЧИВАЕМ ВЫСОТУ
                child: _buildAppBar(_backgroundColor, _textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Color backgroundColor, Color textColor) {
    return Material(
      color: backgroundColor == Colors.white ? Colors.white : Colors.black,
      elevation: 2,
      child: AppBar(
        title: Text(
          widget.book.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: backgroundColor == Colors.white
            ? Colors.white
            : Colors.black,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.settings, color: textColor),
            onSelected: (value) {
              switch (value) {
                case 'increase_font':
                  _increaseFontSize();
                  break;
                case 'decrease_font':
                  _decreaseFontSize();
                  break;
                case 'dark_mode':
                  _toggleDarkMode();
                  break;
                case 'line_height_increase':
                  _changeLineHeight();
                  break;
                case 'line_height_decrease':
                  _changeLineLower();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'increase_font',
                child: Row(
                  children: [
                    Icon(Icons.text_increase, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Увеличить шрифт'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'decrease_font',
                child: Row(
                  children: [
                    Icon(Icons.text_decrease, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Уменьшить шрифт'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'dark_mode',
                child: Row(
                  children: [
                    Icon(backgroundColor == Colors.white
                        ? Icons.dark_mode
                        : Icons.light_mode,
                        color: Colors.black
                    ),
                    SizedBox(width: 8),
                    Text(backgroundColor == Colors.white
                        ? 'Темный режим'
                        : 'Светлый режим'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'line_height_increase',
                child: Row(
                  children: [
                    Icon(Icons.format_line_spacing, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Высота строки: ${_bookView.lineHeight}'),
                    Icon(Icons.remove, color: Colors.black),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'line_height_decrease',
                child: Row(
                  children: [
                    Icon(Icons.format_line_spacing, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Высота строки: ${_bookView.lineHeight}'),
                    Icon(Icons.add, color: Colors.black),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContent() {
    Color _textColor = _bookView.getTextColor;
    Color _backgroundColor = _bookView.getBackgroundColor;
    double _fontSize = _bookView.fontSize;
    double _lineHeight = _bookView.lineHeight;

    if(_isLoading){
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Загрузка книги...',
              style: TextStyle(color: _textColor),
            ),
          ],
        ),
      );
    }

    if(_hasError){
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Ошибка загрузки книги',
              style: TextStyle(color: _textColor, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Файл не найден или поврежден',
              style: TextStyle(color: _textColor.withOpacity(0.7)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookContent,
              child: Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    // 🔥 ВЫЧИСЛЯЕМ ФИКСИРОВАННЫЙ РАЗМЕР ДЛЯ TEXT_PAGE_WIDGET
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    print('📐 [READER] Фиксированный размер для TextPageWidget: ${screenWidth}x${screenHeight}');

    return Container(
      padding: EdgeInsets.only(top:24),
      decoration: BoxDecoration( // ← ДОБАВИЛ ГРАНИЦУ
        border: Border.all(color: Colors.red, width: 3.0),
        color: _backgroundColor,
      ),
      child: TextPageWidget(
        text: _textContent,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        textColor: _textColor,
        backgroundColor: _backgroundColor,
        fixedSize: Size(screenWidth, screenHeight), // ← ПЕРЕДАЕМ ФИКСИРОВАННЫЙ РАЗМЕР
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
  //
  // void _saveReadingProgress(int currentPage) {
  //   if (widget.book.id == null) return;
  //
  //   final progress = currentPage / _pages.length;
  //
  //   BookStatus newStatus;
  //   if (currentPage == 0) {
  //     newStatus = BookStatus.planned;
  //   } else if (currentPage  < _pages.length) {
  //     newStatus = BookStatus.reading;
  //   } else {
  //     newStatus = BookStatus.completed;
  //   }
  //
  //   print('🎨 [READER] Обновление статуса: $newStatus (страница: $currentPage/${_pages.length}, прогресс: ${(progress * 100).toStringAsFixed(1)}%)');
  //
  //   booksTable.updateBookField(
  //     bookId: widget.book.id!,
  //     fieldName: 'current_page',
  //     value: currentPage,
  //   );
  //
  //   booksTable.updateBookField(
  //     bookId: widget.book.id!,
  //     fieldName: 'progress',
  //     value: progress,
  //   );
  //
  //   booksTable.updateBookField(
  //     bookId: widget.book.id!,
  //     fieldName: 'status',
  //     value: newStatus.name,
  //   );
  //
  //   if (widget.book.totalPages != _pages.length) {
  //     booksTable.updateBookField(
  //       bookId: widget.book.id!,
  //       fieldName: 'total_pages',
  //       value: _pages.length,
  //     );
  //     print('💾 Обновлено total_pages: ${_pages.length}');
  //   }
  //
  //   print('💾 Прогресс сохранён: страница $currentPage, прогресс ${(progress * 100).toStringAsFixed(1)}%, статус: $newStatus');
  //
  //   // 🔥 ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА - убедимся что сохранилось
  //   Future.delayed(Duration(milliseconds: 300), () async {
  //     final freshBook = await booksTable.getBookById(widget.book.id!);
  //     print('🔍 ПРОВЕРКА СОХРАНЕНИЯ: current_page в базе = ${freshBook?.currentPage}');
  //   });
  // }

  // void _recalculatePagesWithNewSettings(BookView newSettings) {
  //   if (_textContent.isEmpty || !mounted) return;
  //
  //   print('🔄 ПЕРЕСЧЁТ СТРАНИЦ С ОБНОВЛЕНИЕМ КЭША...');
  //   print('   📊 Шрифт: ${newSettings.fontSize}px');
  //   print('   📏 Интервал: ${newSettings.lineHeight}');
  //
  //   final mediaQuery = MediaQuery.of(context);
  //   const double horizontalPadding = 16.0;
  //   const double verticalPadding = 16.0;
  //
  //   final double availableHeight = mediaQuery.size.height
  //       - mediaQuery.padding.top
  //       - kToolbarHeight
  //       - mediaQuery.padding.bottom
  //       - (verticalPadding * 2);
  //
  //   final double availableWidth = mediaQuery.size.width - (horizontalPadding * 2);
  //
  //   final newPages = PageCalculatorService.splitTextIntoPages(
  //     text: _textContent,
  //     pageWidth: availableWidth,
  //     pageHeight: availableHeight,
  //     fontSize: newSettings.fontSize,
  //     lineHeight: newSettings.lineHeight,
  //     fontFamily: 'Roboto',
  //   );
  //
  //   BookCacheService().updateCachedPages(widget.book.id!, newPages);
  //
  //   if (widget.book.id != null) {
  //     booksTable.updateBookField(
  //       bookId: widget.book.id!,
  //       fieldName: 'total_pages',
  //       value: newPages.length,
  //     );
  //     print('💾 Обновлено total_pages: ${newPages.length}');
  //   }

    // int newCurrentPage = _findPageByAnchor(newPages, _pageAnchor, _currentPageIndex, _pages.length, newPages.length);

    // setState(() {
    //   _pages = newPages;
    //   _currentPageIndex = newCurrentPage;
    // });

    // if (mounted && _pageController != null) {
    //   _isProgrammaticNavigation = true;
    //   _pageController!.jumpToPage(_currentPageIndex);
    //   _isProgrammaticNavigation = false;
    // }

    // BookViewTable.updateSettings(newSettings);

    // _saveReadingProgress(_currentPageIndex + 1);

    // print('✅ Страницы пересчитаны: ${_pages.length} страниц');
    // print('   📍 Новая позиция: ${_currentPageIndex + 1} из ${_pages.length}');

    // AppGlobals.showSuccess('Страницы пересчитаны (${_pages.length} стр.)');
  // }

  // Future<void> _restoreLastPage() async {
  //   try {
  //     print('🔍 [RESTORE_START] Начало восстановления страницы');
  //
  //     if (!mounted || _pageRestored || _pages.isEmpty || widget.book.id == null) {
  //       // Если не нужно восстанавливать, создаем контроллер с 0 страницей
  //       _initializePageController(0);
  //       return;
  //     }
  //
  //     final booksTable = BooksTable();
  //     final freshBook = await booksTable.getBookById(widget.book.id!);
  //
  //     if (freshBook != null && mounted) {
  //       final lastPage = freshBook.currentPage;
  //       final pageIndex = (lastPage - 1).clamp(0, _pages.length - 1);
  //
  //       print('🔍 [RESTORE_JUMP] Создаем контроллер со страницей: $pageIndex');
  //       _initializePageController(pageIndex);
  //       if (pageIndex + 1 != freshBook.currentPage || freshBook.totalPages != _pages.length) {
  //         print('💾 [RESTORE] Сохраняем актуальный прогресс при открытии');
  //         _saveReadingProgress(pageIndex + 1);
  //       }
  //     } else {
  //       _initializePageController(0);
  //     }
  //   } catch (e) {
  //     print('⚠️ [RESTORE_ERROR] Ошибка восстановления: $e');
  //     _initializePageController(0);
  //   }
  // }

  // int _findPageByAnchor(List<String> newPages, String anchor, int oldCurrentPage, int oldTotalPages, int newTotalPages) {
  //   if (anchor.isEmpty) {
  //     // 🔥 Если якоря нет, используем старую логику с процентами
  //     print('Используем старую логику с процентами');
  //     final oldProgress = oldCurrentPage / oldTotalPages;
  //     return (oldProgress * newTotalPages).floor().clamp(0, newTotalPages - 1);
  //   }
  //   print('🔍 Поиск якоря: "$anchor"');
  //   final approximatePage = ((oldCurrentPage / oldTotalPages) * newTotalPages).floor();
  //   final startPage = max(0, approximatePage - 1);
  //   final endPage = min(newTotalPages - 1, approximatePage + 1);
  //   print('   📍 Примерная позиция: $approximatePage, диапазон поиска: $startPage-$endPage');
  //
  //   for (int i = startPage; i <= endPage; i++) {
  //     if (newPages[i].contains(anchor)) {
  //       print('   ✅ Якорь найден на странице: $i');
  //       return i;
  //     }
  //   }
  //
  //   for (int i = 0; i < newPages.length; i++) {
  //     if (newPages[i].contains(anchor)) {
  //       print('   🔎 Якорь найден в другом месте: $i');
  //       return i;
  //     }
  //   }
  //   print('   ❌ Якорь не найден, используем процентную логику');
  //   return approximatePage.clamp(0, newTotalPages - 1);
  // }
}