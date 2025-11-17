import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/core/services/app_info_service.dart';
import 'package:mangalibrary/core/utils/book_page_updater.dart';
import 'package:mangalibrary/enums/book_enums.dart';
import 'package:mangalibrary/ui/book_details_screen/book_details_screen.dart';
import 'package:mangalibrary/ui/library/BookTags.dart';
import 'package:provider/provider.dart';
import '../../core/data/mock_schedule_data.dart';
import '../../domain/models/book.dart';
import '../../core/data/mock_data.dart';
import '../../domain/models/schedule.dart';
import 'package:mangalibrary/core/database/tables/books_table.dart';
import 'time_provider.dart';
import 'package:mangalibrary/ui/add_book_dialog/add_book_dialog.dart';


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});


  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Book> _bookList = [];
  final List<ScheduleItem> _scheduleList = MockScheduleData.getMockSchedule();
  Timer? _timer;
  String textAppInfo = 'Загрузка...';
  bool _isExporting = false;
  String _exportStatus = '';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final BooksTable _booksTable = BooksTable();

  // Переменные для поиска
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Book> _filteredBookList = [];
  List<ScheduleItem> _filteredScheduleList = [];

  @override
  void initState() {
    super.initState();
    _filteredBookList = _bookList;
    _filteredScheduleList = _scheduleList;
    _loadAppVersion();
    _startAutoRefresh();
    _loadLibraryData();
  }

  void _loadLibraryData() async {
    try{
      List<Book> booksFromDb = await _booksTable.getAllBooks();

      setState(() {
        // ВАЖНО: полностью очищаем список перед добавлением книг из БД
        _bookList.clear();
        _bookList.addAll(booksFromDb);
        _filteredBookList = _bookList;
      });

      // УБИРАЕМ добавление тестовой книги если есть книги из БД
      // Тестовая книга добавляется ТОЛЬКО если БД пустая
      if (_bookList.isEmpty) {
        print('База пуста, загружается тестовая книга.');
        _addMockDataForTesting();
      } else {
        print('Загружено книг из БД: ${_bookList.length}');
      }
    } catch (e) {
      print('Ошибка загрузки из базы: $e');
      // Только в случае ошибки добавляем тестовые данные
      _addMockDataForTesting();
    }
  }

  void _addMockDataForTesting() {
    setState(() {
      _bookList.clear();
      _bookList.addAll(MockData.getMockManga());
      _filteredBookList = _bookList;
      print('Добавлено тестовых книг: ${_bookList.length}');
    });
  }

  void _loadAppVersion() {
    setState(() {
       textAppInfo = AppInfoService.instance.appInfo.fullInfoApp;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      Provider.of<TimeProvider>(context, listen: false).updateTime();
    });
  }

  // Метод поиска для библиотеки
  void _searchManga(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBookList = _bookList;
      } else {
        _filteredBookList = _bookList.where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
              book.author.toLowerCase().contains(query.toLowerCase()) ||
              book.tags.any((tag) =>
                  tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  // Метод поиска для расписания
  void _searchSchedule(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredScheduleList = _scheduleList;
      } else {
        _filteredScheduleList = _scheduleList.where((item) {
          return item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.magazine.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Общий метод поиска
  void _search(String query) {
    if (_currentIndex == 0) {
      _searchManga(query);
    } else {
      _searchSchedule(query);
    }
  }

  // Переключение режима поиска
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredBookList = _bookList;
        _filteredScheduleList = _scheduleList;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? TextField( controller: _searchController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Поиск...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                                // prefixIcon: Icon(Icons.search, color: Colors.grey),
                              ),
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                              cursorColor: Colors.deepPurple,
                              onChanged: _search,
        )
                            : const Text('Главная'),
                  actions: [ if (_isSearching)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _toggleSearch,
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _toggleSearch,
                              ),
                            if (!_isSearching)
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: _showAppInfo3,
                              ),
                  ],
      ),
      body: Column(
        children: [
          // Блок времени с переключением
          _buildTimeWidget(),
          const SizedBox(height: 16),

          // Табы библиотека/расписание
          _buildTabBar(),
          const SizedBox(height: 16),

          // Заголовок в зависимости от выбранной вкладки
          _buildHeader(),
          const SizedBox(height: 16),

          // Контент - либо библиотека, либо расписание
          _buildContent(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _addNewBook,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildTimeWidget() {
    return Consumer<TimeProvider>(
      builder: (context, timeProvider, child) {
        return GestureDetector(
          onTap: () => timeProvider.toggleTime(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  timeProvider.isTokyoTime ? Icons.language : Icons.pin_drop,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  timeProvider.currentTime.displayText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple[800],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.swap_horiz,
                  size: 20,
                  color: Colors.deepPurple.withOpacity(0.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('БИБЛИОТЕКА', 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTab('РАСПИСАНИЕ', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
          if (_isSearching) {
            _searchController.clear();
            _filteredBookList = _bookList;
            _filteredScheduleList = _scheduleList;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _currentIndex == index
            ? Colors.deepPurple
            : Colors.grey[300],
        foregroundColor: _currentIndex == index
            ? Colors.white
            : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildHeader() {
    final bookCount = _filteredBookList.length;
    final totalCount = _bookList.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _currentIndex == 0 ? 'МОЯ БИБЛИОТЕКА' : 'РАСПИСАНИЕ ВЫХОДОВ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          if (_isSearching && _searchController.text.isNotEmpty)
            Text(
              'Найдено: $bookCount/$totalCount',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: _currentIndex == 0
          ? _buildLibraryContent()
          : _buildScheduleContent(),
    );
  }

  // Контент библиотеки
  Widget _buildLibraryContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: _isSearching ? _filteredBookList.length : _bookList.length + 1,
        itemBuilder: (context, index) {
          if (!_isSearching) {
            // Если книг нет - показываем AddBook
            if (_bookList.isEmpty) {
              return buildAddBookCard(); // AddBook
            }
            // Если есть книги - показываем кнопку добавления в конце
            if (index == _bookList.length) {
              return buildAddBookCard();
            }
          }
          final book = _filteredBookList[index];
          return _buildBookCard(book);
        },
      ),
    );
  }

  // Контент расписания
  Widget _buildScheduleContent() {
    final thisWeekSchedule = _filteredScheduleList.where((item) {
      final difference = item.releaseDate
          .difference(DateTime.now())
          .inDays;
      return difference <= 7;
    }).toList();

    final futureSchedule = _filteredScheduleList.where((item) {
      final difference = item.releaseDate
          .difference(DateTime.now())
          .inDays;
      return difference > 7;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScheduleSection(
            title: 'НА ЭТОЙ НЕДЕЛЕ',
            schedule: thisWeekSchedule,
          ),
          const SizedBox(height: 24),
          _buildScheduleSection(
            title: 'БУДУЩИЕ ВЫХОДЫ',
            schedule: futureSchedule,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScheduleSection({
    required String title,
    required List<ScheduleItem> schedule,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (schedule.isEmpty)
          const Text(
            'Ничего не найдено',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...schedule.map((item) => _buildScheduleItem(item)).toList(),
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor(item),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(item),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayLabel(item),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(item),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.chapter,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                        Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.menu_book, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.magazine,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (!item.isToday && !item.isTomorrow) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.daysLeft,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(ScheduleItem item) {
    if (item.isToday) return '🔥 Сегодня';
    if (item.isTomorrow) return '📖 Завтра';
    return '🎯 ${_formatDate(item.releaseDate)}';
  }

  Color _getMangaStatusColor(String status) {
    switch (status) {
      case 'Читаю':
        return Colors.green;
      case 'В планах':
        return Colors.blue;
      case 'Прочитано':
        return Colors.purple;
      case 'Отложено':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(ScheduleItem item) {
    if (item.isToday) return Colors.red;
    if (item.isTomorrow) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(ScheduleItem item) {
    if (item.isToday) return Icons.flash_on;
    if (item.isTomorrow) return Icons.today;
    return Icons.calendar_today;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  // Методы библиотеки
  Widget _buildBookCard(Book book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openBookDetails(book),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  if (book.author.isNotEmpty) ...[
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                  Text(
                    'Том ${book.currentChapterIndex}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: book.statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      book.statusDisplayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: book.progress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.deepPurple,
                    minHeight: 6,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(book.progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${book.currentPage}/${book.totalPages} стр.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (book.tags.isNotEmpty) ...[
                    SizedBox(height: 8),
                    BookTags(tags: book.tags),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddBookCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: _addNewBook,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 40,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 8),
            Text(
              'Добавить книгу',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openBookDetails(Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(
          book: book,
          onDelete: () {
            _deleteBook(book);
          },
        ),
      ),
    ).then((_) async {
      final BooksTable booksTable = BooksTable();
      final Book? updatedBook = await booksTable.getBookById(book.id!);
      if (updatedBook != null) {
        // ВЫЧИСЛЯЕМ СТАТУС НА ОСНОВЕ ПРОГРЕССА
        BookStatus calculateStatus(double progress) {
          if (progress < 0.1) return BookStatus.planned;
          if (progress < 1.0) return BookStatus.reading;
          return BookStatus.completed;
        }

        BookStatus newStatus = calculateStatus(updatedBook.progress);

        // ОБНОВЛЯЕМ СТАТУС В БАЗЕ ДАННЫХ
        await booksTable.updateBookField(
            bookId: book.id!,
            fieldName: 'status',
            value: newStatus.name // ← Сохраняем как строку!
        );

        setState(() {
          // ОБНОВЛЯЕМ ВЕСЬ ОБЪЕКТ КНИГИ, а не отдельные поля
          final index = _bookList.indexWhere((b) => b.id == book.id);
          if (index != -1) {
            _bookList[index] = Book.fromMap({
              ...updatedBook.toMap(),
              'status': newStatus.name // ← Обновляем статус
            });
            _filteredBookList = List.from(_bookList);
          }
        });

        print("Статус книги обновлен на: $newStatus");
      }
    });
    _loadLibraryData(); // Перезагружаем данные для гарантии
  }

  void _deleteBook(Book book) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Книга "${book.title}" удалена')),
    );
  }

  void _addNewBook() async {
    Book? newBook = await showDialog<Book>(
        context: context,
        builder: (BuildContext context) => AddBookDialog(
          onBookAdded: (book) {
            _saveNewBookToDatabase(book);
          },
        ),
    );
  }

  void _showAppInfo3() {
    double currentHeight = 330.0;
    bool isTouch = false;
    showModalBottomSheet(
      enableDrag: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AnimatedContainer(
              duration: Duration(milliseconds: 50),
              height: currentHeight,
              curve: Curves.easeOut,
              constraints: BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.deepPurple[100]!],
                ),
              ),
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      child: Container(
                        padding: EdgeInsets.only(top:5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.transparent,
                        ),
                        height: 35,
                        child: Center(
                          child: Container(
                            height: 10,
                            width: 330.0*0.5,
                            decoration: BoxDecoration(
                              color: isTouch
                                  ? Colors.deepPurple
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(25)
                            ),
                          ),
                        ),
                      ),
                      onVerticalDragStart: (detalis) {
                        setState((){
                          isTouch = true;
                        });
                      },
                      onVerticalDragUpdate: (detalis) {
                        setState((){
                          currentHeight -= detalis.primaryDelta!;
                          if(currentHeight > 330.0) currentHeight = 330.0;
                        });
                      },
                      onVerticalDragEnd: (detalis) {
                        setState((){
                          if(currentHeight < 330.0*0.67){
                            Navigator.pop(context);
                          }else{
                            currentHeight = 330.0;
                          }
                          isTouch = false;
                        });
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Работа выполнена Александром А.В.\n'
                                'Из ИТ-41\n\n'
                                'Информация о приложении:\n'
                                'Написан на Flutter\n'
                                '$textAppInfo\n',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.grey[1000],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _showStatusApp();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                            ),
                            child:  Text('Статистика приложения'),
                          ),
                          SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          );
        },
      ),
    );
  }

  void _showStatusApp() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storage, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Информация о Базе Данных',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная статистика
                      _buildStatCard(
                        title: 'Основная статистика',
                        icon: Icons.library_books,
                        children: [
                          _buildStatItem('Всего книг', '0'),
                          _buildStatItem('В избранном', '0'),
                          _buildStatItem('Общий размер', '0 МБ'),
                          _buildStatItem('Средний размер', '0 МБ'),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Прогресс чтения
                      _buildStatCard(
                        title: 'Прогресс чтения',
                        icon: Icons.timeline,
                        children: [
                          _buildStatItem('Средний прогресс', '0%'),
                          _buildStatItem('Общее время чтения', '0ч 0м'),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Распределение
                      _buildStatCard(
                        title: 'Распределение',
                        icon: Icons.pie_chart,
                        children: [
                          _buildStatItem('Статусы чтения', 'Нет данных'),
                          _buildStatItem('Типы книг', 'Нет данных'),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Кнопка экспорта
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _exportDataBase,
                          icon: Icon(Icons.import_export),
                          label: Text('Экспорт базы данных и файлов'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            int current = 0;
                            int total = 0;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                title: Text('Пересчёт страниц'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Идёт пересчёт страниц...'),
                                    SizedBox(height: 8),
                                    Text('$current / $total'),
                                  ],
                                ),
                              )
                            );
                            try{
                              await BookPageUpdater.recalculateAllBooksPages(
                                  context,
                                      (currentProgress, totalCount) {
                                    setState(() {
                                      current = currentProgress;
                                      total = totalCount;
                                    });
                                  }
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Пересчёт страниц завершён!'))
                              );
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка пересчёта: $e'), backgroundColor: Colors.red)
                              );
                            }

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Пересчёт страниц завершён!'))
                            );
                          },
                          label: Text('Пересичитать все страницы книг'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Кнопка закрыть
              Container(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(200, 50),
                  ),
                  child: Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

// Вспомогательный метод для элемента статистики
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  void _saveNewBookToDatabase(Book newBook) async {
    int newBookId = await _booksTable.insertBook(newBook);
    newBook.id = newBookId;
    _loadLibraryData();
    // try{
    //
    //
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //         content: Text('Книга "${newBook.title}" успешно добавлена!'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // }catch (e){
    //   print('Ошибка сохранения книги: $e');
    //   ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Ошибка при добавлении книги: $e'),
    //         backgroundColor: Colors.red,
    //       )
    //   );
    // }
  }

  Future<void> _exportDataBase() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _exportStatus = 'Экспортируем библиотеку...';
    });

    try {
      print('=== НАЧАЛО ЭКСПОРТА ===');

      // Просто вызываем экспорт всего
      await _dbHelper.exportEverythingToDownloads();

      setState(() {
        _exportStatus = '✅ Вся библиотека экспортирована в папку Download/MangaLibrary_Books/';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Библиотека экспортирована!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('=== ОШИБКА ЭКСПОРТА: $e ===');
      setState(() {
        _exportStatus = '❌ Ошибка: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
      print('=== ЗАВЕРШЕНИЕ ЭКСПОРТА ===');
    }
  }

  /// Вспомогательный метод для форматирования размера файла
  /// Преобразует байты в читаемый формат (КБ, МБ)
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

}