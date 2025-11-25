// text_page_widget.dart - ШАГ 12 (полноэкранный со свайпом)
import 'dart:io';
import 'dart:typed_data';
import 'package:epub_pro/epub_pro.dart';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/utils/epub_parser_utils.dart';
import 'package:mangalibrary/core/utils/textPaginator.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class TextPageWidget extends StatefulWidget {
  final BookView bookView;
  final Book book;
  final VoidCallback? onScreenTap;
  final Function(bool totalPages)? onBookReady;
  final int? targetPage;

  const TextPageWidget({
    super.key,
    required this.bookView,
    required this.book,
    this.onScreenTap,
    this.onBookReady,
    this.targetPage,
  });

  @override
  State<TextPageWidget> createState() => TextPageWidgetState();
}

class TextPageWidgetState extends State<TextPageWidget> {
  String filePathToBook = "";
  List<String>? _pages;
  bool _isInitialized = false;
  BoxConstraints? _constraints;
  int _currentPageIndex = 0;
  PageController? _pageController;
  String textInBook = "";
  bool _isReady = false;
  bool _isLoading = false;
  bool _isPaginating = false;
  bool _hasConstraints = false;

  TextStyle get textStyle {
    return TextStyle(
      fontSize: widget.bookView.fontSize,
      color: widget.bookView.getTextColor,
      height: widget.bookView.lineHeight,
      fontFamily: 'Roboto'
    );
  }

  void reloadPages() {
//     print('🔄 [TEXT_PAGE] Вызван reloadPages');

    if (_constraints != null && _isReady) {
      setState(() {
        // _isInitialized = false;
        _pages = null;
      });
// 
//       print('🔄 [TEXT_PAGE] Сброшена инициализация, запуск пагинации...');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _isPaginating = true;
          _loadAndPaginateText().then((_) {
            _isPaginating = false;
//             print('✅ [TEXT_PAGE] Перерисовка завершена. Страниц: ${_pages?.length}');
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
//     print('📖 [TEXT_PAGE] Инициализация:');
//     print("[initState]");
    filePathToBook = widget.book.filePath;
    final int maxIndex = widget.book.totalPages > 0 ? widget.book.totalPages - 1 : 0;
    // AppGlobals.showInfo('инициализация text_page_widget ${widget.targetPage}');
    if(widget.targetPage != null && widget.targetPage! > 1){
      _currentPageIndex = widget.targetPage! - 1;
    }else{
      _currentPageIndex = (widget.book.currentPage - 1).clamp(0, maxIndex);
    }
// 
//     print("_currentPageIndex: $_currentPageIndex");
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadBookContent();
    // _initializeBook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ждем когда виджет будет полностью готов и получит constraints
    if (!_isInitialized && _isReady && !_isPaginating && _hasConstraints) {
      _isInitialized = true;
      _isPaginating = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAndPaginateText().then((_) {
            _isPaginating = false;
          });
        }
      });
    }
  }

  Future<void> _loadBookContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final file = File(filePathToBook);
      if (!await file.exists()) {
        throw Exception('Файл книги не найден');
      }

      if (widget.book.fileFormat.toLowerCase() == 'txt') {
        // --- ЛОГИКА ДЛЯ TXT ---
        textInBook = await file.readAsString();
//         print('✅ Текст TXT успешно прочитан.');
      }
      // Мы не можем читать EPUB в одну строку,
      // поэтому не нужно заполнять textInBook.
      // Логика EPUB будет полностью в _loadAndPaginateText.

      setState(() {
        _isReady = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        // Можно добавить флаг _hasError
      });
//       print('❌ Ошибка инициализации книги: $e');
    }

    // Обновляем дату открытия
    widget.book.lastDateOpen = DateTime.now();
    if (widget.onBookReady != null) {
      widget.onBookReady!(true);
    }
  }

  void _updateChapterProgress(Book book) {
    final currentPage = book.currentPage;
    if (widget.book.chapters.isEmpty) {
      print("widget.book.chapters.isEmpty");
      return;
    }

    final int currentChapterIndex = widget.book.chapters.indexWhere(
          (chapter) => currentPage >= chapter.startPage && currentPage <= chapter.endPage!,
    );
    print("currentChapterIndex = $currentChapterIndex");
    if (currentChapterIndex == -1) {
      print("currentChapterIndex == -1");
      return;
    }
    // Обновляем прогресс для каждой главы
    for (int i = 0; i < widget.book.chapters.length; i++) {
      final chapter = widget.book.chapters[i];

      if (i < currentChapterIndex) {
        // 1. Главы, которые были ПОЛНОСТЬЮ ПРОЧИТАНЫ (перед текущей)
        chapter.currentPage = chapter.endPage! - chapter.startPage + 1; // Устанавливаем макс. страницу
        chapter.isRead = BookStatus.completed;
      } else if (i == currentChapterIndex) {
        // 2. ТЕКУЩАЯ ГЛАВА
        final int chapterCurrentPage = currentPage - chapter.startPage + 1;
        chapter.currentPage = chapterCurrentPage;
        chapter.isRead = BookStatus.reading;
      } else {
        // 3. Главы, которые ЕЩЕ НЕ НАЧАТЫ
        chapter.currentPage = 0;
        chapter.isRead = BookStatus.planned;
      }

    }
  }

  void _handlePageChange(int index) {
    if (!_isReady || !_isInitialized) return;
// 
//     print('🔄 [_handlePageChange] Пользователь перешел на под индексом: $index ');

    setState(() {
      _currentPageIndex = index; // ← ХРАНИМ ИНДЕКС (0-based)
    });

    Book book = widget.book;
    int pageNumber = book.currentPage = _currentPageIndex + 1;

    if (pageNumber >= book.totalPages) {
      book.status = BookStatus.completed;
    } else if (pageNumber > 0) {
      book.status = BookStatus.reading;
    }
// 
    print('📖 Обновлен объект книги: ${widget.book.currentPage}');
  }

  Future<void> _saveCurrentProgress() async {
//     print("ВЫЗОВ МЕТОДА _saveCurrentProgress()");
    try {
      if (_pages == null) return;

      final book = widget.book;

      int pageNumber = _currentPageIndex + 1;

      if (_pages!.isNotEmpty && _currentPageIndex < _pages!.length) {
        // Вычисляем индекс первого символа текущей страницы
        int symbolIndex = 0;
        for (int i = 0; i < _currentPageIndex; i++) {
          symbolIndex += _pages![i].length;
        }
        book.lastSymbolIndex = symbolIndex;
//         print("💾 Сохранена позиция в тексте: символ $symbolIndex");
      }
// 
      print('💾 [TEXT_PAGE] Сохраняем текущий прогресс: страница $pageNumber');

      book.progress = book.getProgress;
      book.currentPage = _currentPageIndex + 1;


      if (pageNumber >= book.totalPages) {
        book.status = BookStatus.completed;
      } else if (pageNumber > 0) {
        book.status = BookStatus.reading;
      }
      _updateChapterProgress(book);
//       print('💾 [TEXT_PAGE] Сохраняем прогресс:');
//       print('   📄 Индекс: $_currentPageIndex');
//       print('   🔢 Номер страницы: $pageNumber');
//       print('   📊 Всего страниц: ${book.totalPages}');
//       print('   📈 Прогресс: ${book.getProgress * 100}%');
//       print('   🎨 Статус: ${book.status.name}');

      final booksTable = BooksTable();
      int result = await booksTable.updateBook(book);
// 
      print('✅ [TEXT_PAGE] Текущий прогресс сохранен. Результат: $result');
    } catch (e) {
//       print('❌ [TEXT_PAGE] Ошибка сохранения текущего прогресса: $e');
    }
  }

  @override
  void dispose() {
    // _saveCurrentProgress();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_isReady) {
      return _buildErrorScreen();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        await _saveCurrentProgress();
      },
        child: Stack( // ← ОБЕРНУТЬ ВСЁ В STACK
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3.0),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages != null ? _pages!.length : 1,
                onPageChanged: _handlePageChange,
                itemBuilder: (context, index) {
                  return LayoutBuilder(
                    builder: (context, pageConstraints) {
                      return Container(
                        color: widget.bookView.getBackgroundColor,
                        padding: EdgeInsets.only(top:32, bottom: 16,left: 16,right: 16),
                        child: LayoutBuilder(
                          builder: (context, textConstraints) {
                            if (!_hasConstraints) {
                              _constraints = textConstraints;
                              _hasConstraints = true;
//                               print("✅ Constraints получены: ${_constraints!.maxWidth}x${_constraints!.maxHeight}");
                              // ЗАПУСКАЕМ ПАГИНАЦИЮ ПОСЛЕ ПОЛУЧЕНИЯ CONSTRAINTS
                              if (_isReady && !_isPaginating) {
                                _isInitialized = true;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    _isPaginating = true;
                                    _loadAndPaginateText().then((_) {
                                      _isPaginating = false;
                                    });
                                  }
                                });
                              }
                            }
                            if (_pages == null) {
                              return Center(child: CircularProgressIndicator());
                            }
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 3.0),
                              ),
                              child: SelectableText.rich(
                                TextSpan(
                                  text: _pages![index],
                                  style: textStyle,
                                ),
                                textAlign: TextAlign.justify,
                                onTap: () {
                                  if (widget.onScreenTap != null) {
                                    widget.onScreenTap!();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Слой с номером страницы (ПОВЕРХ ВСЕГО)
            Positioned(
              top: 5, // ← отступ от низа всего экрана
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPageIndex + 1}/${_pages?.length ?? 0}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Future<void> readBookText(String filePath) async {
    try {
      final file = File(filePath);

      // Проверяем существование файла
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      // Читаем весь текст из файла
      textInBook = await file.readAsString();
// 
      print('✅ Текст успешно прочитан из файла');
//       print('📁 Путь: $filePath');
//       print('📝 Длина текста: ${textInBook.length} символов');

    } catch (e) {
//       print('❌ Ошибка чтения файла: $e');
    }
  }

  int getCurrentPageIndex() {
    return _currentPageIndex;
  }

  // 🔥 НОВЫЙ ГЕТТЕР: Общее количество страниц
  int getTotalPages() {
    return _pages?.length ?? 0;
  }

  // 🔥 НОВЫЙ ГЕТТЕР: Индекс последнего прочитанного символа
  // (Пока что это заглушка, пока нет логики для его отслеживания при свайпе)
  int getLastSymbolIndex() {
    // В идеале, здесь должно возвращаться значение,
    // полученное из PageController'а и логики пагинации
    return widget.book.lastSymbolIndex; // Возвращаем последнее сохраненное значение
  }

  Future<void> _loadAndPaginateText() async {
    if (_constraints == null) {
//       print('❌ Constraints еще не доступны');
      return;
    }
    double availableWidth = _constraints!.maxWidth;
    double availableHeight = _constraints!.maxHeight;
// 
    print("🔄 [_loadAndPaginateText] Запуск пагинации. W:$availableWidth H:$availableHeight");

    List<String> calculatedPages = [];
    int initialPageIndex = (widget.book.currentPage - 1).clamp(0, widget.book.totalPages - 1);

    final paginator = CoolTextPaginator();
    PaginationResult result = PaginationResult(pages: [], targetPageIndex: 0);

    if (widget.book.fileFormat.toLowerCase() == 'txt') {
      if (textInBook.isEmpty) {
        // Должно быть прочитано в _loadBookContent, но на всякий случай
        await File(filePathToBook).readAsString().then((content) => textInBook = content);
      }

      final paginator = CoolTextPaginator();
      final result = paginator.paginate(
        text: textInBook,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        textStyle: textStyle,
      );

      //TODO: перезаписть главу надо, условно пересоздать, так как она не пересоздаеться и не перещитваеться, просто останеться в бд

      calculatedPages = result.pages;

    } else if (widget.book.fileFormat.toLowerCase() == 'epub') {
      try {
        final bytes = await File(filePathToBook).readAsBytes();
        final epubBook = await EpubReader.readBook(bytes);

        // Используем утилиту, которую вы уже применяли в AddBookDialog
        final parsedContent = EpubParserUtils.extractAndPaginateBook(
            epubBook: epubBook,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            textStyle: textStyle,
            idBook: widget.book.id!,
        );

        calculatedPages = parsedContent.allBookPages;
        widget.book.chapters = parsedContent.chapters;
        // Ограничиваем индекс
        initialPageIndex = initialPageIndex.clamp(0, calculatedPages.length - 1);

      } catch (e) {
//         print('❌ Ошибка пагинации EPUB: $e');
        // Если ошибка, оставляем пустые страницы или показываем ошибку
      }
    }

    if (mounted) {
      setState(() {
        _pages = calculatedPages;
        _currentPageIndex = initialPageIndex;
        // Обновляем totalPages в объекте книги
        widget.book.totalPages = _pages!.length;
      });
// 
      print("coll _pages^ ${_pages!.length}");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController != null && _pageController!.hasClients) {

          // 🔥 ИСПРАВЛЕНИЕ: Убираем условие, чтобы всегда принудительно
          // переходить на нужную страницу после загрузки контента
          // if(_pageController!.initialPage != _currentPageIndex) {
          _pageController!.jumpToPage(_currentPageIndex);
          // }
// 
          print("✅ Переход на страницу: $_currentPageIndex");
        }
      });
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Загрузка книги...',
            style: TextStyle(
              fontSize: 16,
              color: widget.bookView.getTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Ошибка загрузки книги',
            style: TextStyle(
              fontSize: 16,
              color: widget.bookView.getTextColor,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_outlined),
          )
        ],
      ),
    );
  }
}

