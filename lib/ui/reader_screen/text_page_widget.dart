// text_page_widget.dart - ШАГ 12 (полноэкранный со свайпом)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/utils/textPaginator.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import 'package:mangalibrary/enums/book_enums.dart';

//TODO класс надопеменять в соответсвии с нашим измененноый струкоурой кинг
class TextPageWidget extends StatefulWidget {
  final Book book;
  final VoidCallback? onScreenTap;
  final Function(bool totalPages)? onBookReady;
  final int? targetPage;
  
  const TextPageWidget({
    super.key,
    required this.book,
    this.onScreenTap,
    this.onBookReady,
    this.targetPage,
  });

  @override
  State<TextPageWidget> createState() => TextPageWidgetState();
}

class TextPageWidgetState extends State<TextPageWidget> {
  BookView bookView = BookView.instance;
  String filePathToBook = "";
  List<String>? _pages;
  bool _isInitialized = false;
  
  BoxConstraints? _constraints;
  bool _hasConstraints = false;
  Future<List<String>>? _paginationFuture;

  int _currentPageIndex = 0;
  PageController? _pageController;

  String textInBook = "";
  Book? currentBook;
  int currentTotalPage = 0;

  TextStyle? textStyle;

  void reloadPages() {
    if (_constraints != null) {
      setState(() {
        _pages = null;
        _paginationFuture = _loadAndPaginateText();
        textStyle = TextStyle(
            fontSize: bookView.fontSize,
            color: bookView.getTextColor,
            height: bookView.lineHeight,
            fontFamily: 'Roboto'
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    currentTotalPage = widget.book.totalPages;
    filePathToBook = widget.book.fileFolderPath;
    currentBook = widget.book;
    _pageController = PageController(initialPage: _currentPageIndex);
    textStyle = TextStyle(
        fontSize: bookView.fontSize,
        color: bookView.getTextColor,
        height: bookView.lineHeight,
        fontFamily: 'Roboto'
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ждем когда виджет будет полностью готов и получит constraints
    if (!_isInitialized && _hasConstraints) {
      _isInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAndPaginateText();
        }
      });
    }
  }

  Future<void> _loadBookContent() async {
    try {
      //TODO надо брать возмно не один файл надо или убрать или передалть или в другом местев for использовать
      final file = File(filePathToBook);
      if (!await file.exists()) {
        throw Exception('Файл книги не найден');
      }

      if (widget.book.fileFormat.toLowerCase() == 'txt') {
        textInBook = await file.readAsString();
      }
    } catch (e) {
      print('❌ Ошибка инициализации книги: $e');
    }

    // Обновляем дату открытия
    widget.book.lastDateOpen = DateTime.now();
    if (widget.onBookReady != null) {
      widget.onBookReady!(true);
    }
  }

  void _updateChapterProgress(Book book) {
    final currentPage = book.currentPage;

    // Проверяем, есть ли тома и главы
    if (book.volumes.isEmpty) {
      print("📚 Нет томов для обновления прогресса");
      return;
    }

    print("🔄 Обновление прогресса глав для страницы: $currentPage");

    // 🔥 ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЕ ГЕТТЕРЫ ИЗ BOOK
    final currentVolume = book.currentVolume;
    final currentChapter = book.currentChapter;

    if (currentVolume != null) {
      print("📖 Текущий том: ${currentVolume.title} (страницы ${currentVolume.startPage}-${currentVolume.endPage})");
    } else {
      print("⚠️ Не найден том для страницы $currentPage");
    }

    if (currentChapter != null) {
      print("📖 Текущая глава: ${currentChapter.title} (страницы ${currentChapter.startPage}-${currentChapter.endPage})");
    } else {
      print("⚠️ Не найдена глава для страницы $currentPage");
    }

    // 🔥 Обновляем статусы всех глав на основе текущей главы
    for (final volume in book.volumes) {
      for (final chapter in volume.chapters) {
        if (currentChapter != null) {
          // Определяем статус главы на основе позиции относительно текущей
          if (chapter.startPage < currentChapter.startPage) {
            // Глава ДО текущей - полностью прочитана
            chapter.isRead = BookStatus.completed;
          } else if (chapter.startPage == currentChapter.startPage) {
            // ТЕКУЩАЯ глава
            chapter.isRead = BookStatus.reading;
          } else {
            // Глава ПОСЛЕ текущей - в планах
            chapter.isRead = BookStatus.planned;
          }
        } else {
          // Если текущая глава не найдена, все главы в планах
          chapter.isRead = BookStatus.planned;
        }
      }
    }

    // 🔥 Логируем статистику
    _logProgressStatistics(book);
  }

// 🔥 Дополнительный метод для логирования статистики
  void _logProgressStatistics(Book book) {
    int completedChapters = 0;
    int readingChapters = 0;
    int plannedChapters = 0;

    for (final volume in book.volumes) {
      for (final chapter in volume.chapters) {
        switch (chapter.isRead) {
          case BookStatus.completed:
            completedChapters++;
            break;
          case BookStatus.reading:
            readingChapters++;
            break;
          case BookStatus.planned:
            plannedChapters++;
            break;
          case BookStatus.paused:
            plannedChapters++; // считаем паузу как запланированную
            break;
        }
      }
    }

    print("📊 Статистика прогресса:");
    print("   ✅ Завершено глав: $completedChapters");
    print("   📖 Читается глав: $readingChapters");
    print("   📚 В планах глав: $plannedChapters");
    print("   📖 Всего глав: ${completedChapters + readingChapters + plannedChapters}");
  }

  void _handlePageChange(int index) {
    if (!_isInitialized) return;
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

      book.currentPage = _currentPageIndex + 1;

      if (pageNumber >= book.totalPages) {
        book.status = BookStatus.completed;
      } else if (pageNumber > 0) {
        book.status = BookStatus.reading;
      }
      _updateChapterProgress(book);

      final booksTable = BooksTable();
      int result = await booksTable.updateBook(book);
// 
      print('✅ [TEXT_PAGE] Текущий прогресс сохранен. Результат: $result');
    } catch (e) {
//       print('❌ [TEXT_PAGE] Ошибка сохранения текущего прогресса: $e');
    }
  }

  @override
  void dispose() async {
    _pageController?.dispose();
    super.dispose();
    await _saveCurrentProgress();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        await _saveCurrentProgress();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.onScreenTap != null) {
            widget.onScreenTap!();
          } else {
            print('❌ onScreenTap is NULL');
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3.0),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages != null ? _pages!.length : 1,
                onPageChanged: _handlePageChange,
                physics: const PageScrollPhysics(),
                itemBuilder: (context, index) {
                  return LayoutBuilder(
                    builder: (context, pageConstraints) {
                      return Container(
                        color: bookView.getBackgroundColor,
                        padding: EdgeInsets.only(top:32, bottom: 16,left: 16,right: 16),
                        child: LayoutBuilder(
                          builder: (context, textConstraints) {
                            // Получаем constraints синхронно
                            if (!_hasConstraints) {
                              _constraints = textConstraints;
                              _hasConstraints = true;
                              _isInitialized = true;
                              // Запускаем асинхронную пагинацию после получения constraints
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _paginationFuture = _loadAndPaginateText();
                                  });
                                }
                              });
                            }

                            // Используем FutureBuilder для асинхронного отображения контента
                            return FutureBuilder<List<String>>(
                              future: _paginationFuture,
                              builder: (context, snapshot) {
                                // Пока загружается - показываем индикатор
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildLoadingScreen();
                                }

                                // Если ошибка
                                if (snapshot.hasError) {
                                  return _buildErrorScreen();
                                }

                                // Если данные получены
                                if (snapshot.hasData) {
                                  List<String> pages = snapshot.data!;

                                  if (pages.isEmpty) {
                                    pages =[
                                      "${"\t"*5} Книга пуста или не содержит текста для отображения.\n\n"
                                          "${"\t"*5}Возможные причины:\n"
                                          "${"\t"*10}• Файл поврежден\n"
                                          "${"\t"*10}• Неподдерживаемый формат\n"
                                          "${"\t"*10}• Текст отсутствует"
                                    ]; // заглушка
                                  }

                                  // Сохраняем страницы в состоянии при первом получении
                                  if (_pages == null) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() {
                                          _pages = pages;
                                          widget.book.totalPages = pages.length;

                                          // Корректируем текущую страницу
                                          if(pages.isNotEmpty){
                                            _currentPageIndex = _currentPageIndex.clamp(0, pages.length - 1);
                                          }
                                          else{
                                            _currentPageIndex = 0;
                                          }
                                        });

                                        // Переходим на нужную страницу после загрузки
                                        if (_pageController != null && _pageController!.hasClients) {
                                          _pageController!.jumpToPage(_currentPageIndex);
                                        }
                                      }
                                    });
                                  }

                                  // Отображаем текст страницы
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green, width: 3.0),
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        pages.isNotEmpty && index < pages.length
                                            ? pages[index]
                                            : 'Страница не найдена',
                                        style: TextStyle(
                                            fontSize: bookView.fontSize,
                                            color: bookView.getTextColor,
                                            height: bookView.lineHeight,
                                            fontFamily: 'Roboto'
                                        ),
                                        onTap: () {
                                          if (widget.onScreenTap != null) {
                                            widget.onScreenTap!();
                                          }
                                        },
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                  );
                                }
                                return Center(child: CircularProgressIndicator());
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Номер страницы поверх всего
            Positioned(
              top: 5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPageIndex + 1}/${currentTotalPage ?? 0}',
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

  Future<List<String>> _loadAndPaginateText() async {
    if (_constraints == null) {
      throw Exception('Constraints не инициализированы при вызове пагинации.');
    }
    final int maxIndex = widget.book.totalPages > 0 ? widget.book.totalPages - 1 : 0;
    if(widget.targetPage != null && widget.targetPage! > 1){
      _currentPageIndex = widget.targetPage! - 1;
    } else {
      _currentPageIndex = (widget.book.currentPage - 1).clamp(0, maxIndex);
    }

    double availableWidth = _constraints!.maxWidth;
    double availableHeight = _constraints!.maxHeight;
// 
    print("🔄 [_loadAndPaginateText] Запуск пагинации. W:$availableWidth H:$availableHeight");

    List<String> calculatedPages = [];
    List<BookVolume> currentVolumes = currentBook!.volumes;
    int currentPage = 0;
    final paginator = CoolTextPaginator();

    for(BookVolume volume in currentVolumes){
      List<VolumeChapter> currentChapter = volume.chapters;
      currentPage++;
      volume.startPage = currentPage;

      if(volume.fileFolderPath != null){
        final directory = Directory(volume.fileFolderPath!);
        if (await directory.exists()) {
          List<FileSystemEntity> entities = directory.listSync().toList();
          for (FileSystemEntity entity in entities) {
            if (entity is File && entity.path.endsWith('.txt')) {
              try {
                final filePath = await File(entity.path);
                if(await filePath.exists()){
                  print('Файл: ${volume.fileFolderPath} номер тома: ${volume.number}');
                  String fileContent = await filePath.readAsString();
                  final result = paginator.paginate(
                    text: fileContent,
                    availableWidth: availableWidth,
                    availableHeight: availableHeight,
                    textStyle: textStyle!,
                  );
                  calculatedPages.addAll(result.pages);
                  currentPage += result.countPage - 1;
                }
              }catch (e){
                print('Ошибка чтения файла ${entity.path}: $e');
                AppGlobals.showError("Ошибка чтения файла ${entity.path}: $e");
              }
            }
          }
        }
      }
      for(VolumeChapter chapter in currentChapter){
        currentPage++;
        final folderPath = chapter.fileFolderPath;
        Directory directory = Directory(folderPath);
        if (await directory.exists()) {
          List<FileSystemEntity> entities = directory.listSync().toList();

          chapter.startPage = currentPage;

          for (FileSystemEntity entity in entities) {
            if (entity is File && entity.path.endsWith('.txt')) {// Проверяем, что это файл
              try {
                final filePath = await File(entity.path);
                if(await filePath.exists()){
                  String fileContent = await filePath.readAsString();
                  print('Файл: ${entity.path} номер тома: ${volume.number} номер главы: ${chapter.position}');
                  final result = paginator.paginate(
                    text: fileContent,
                    availableWidth: availableWidth,
                    availableHeight: availableHeight,
                    textStyle: textStyle!,
                  );
                  calculatedPages.addAll(result.pages);
                  currentPage += result.countPage - 1;
                }
              } catch (e) {
                print('Ошибка чтения файла ${entity.path}: $e');
                AppGlobals.showError("Ошибка чтения файла ${entity.path}: $e");
              }
            }
          }// for (FileSystemEntity entity in entities)

          chapter.endPage = currentPage;

        } // if (await directory.exists())
      } // for(VolumeChapter chapter in currentChapter)

      volume.endPage = currentPage;

    } // for(BookVolume volume in currentVolumes)
    currentTotalPage = currentPage;
    currentBook!.totalPages = currentTotalPage;
    if (widget.onBookReady != null) {
      print("📢 Уведомляем о готовности книги");
      widget.onBookReady!(true);
    }
    print("Второя страница: ${calculatedPages.length}");
    return calculatedPages;
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
              color: bookView.getTextColor,
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
              color: bookView.getTextColor,
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

