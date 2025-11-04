import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data/mock_data.dart';
import '../../core/data/mock_schedule_data.dart';
import '../../domain/models/manga.dart';
import '../../domain/models/schedule.dart';
import '../manga_details/manga_details_screen.dart';
import 'time_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _currentIndex = 0; // 0 - библиотека, 1 - расписание
  final List<Manga> _mangaList = MockData.getMockManga();
  final List<ScheduleItem> _scheduleList = MockScheduleData.getMockSchedule();
  Timer? _timer;

  // Переменные для поиска
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Manga> _filteredMangaList = [];
  List<ScheduleItem> _filteredScheduleList = [];

  @override
  void initState() {
    super.initState();
    _filteredMangaList = _mangaList;
    _filteredScheduleList = _scheduleList;
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      Provider.of<TimeProvider>(context, listen: false).updateTime();
    });
  }

  // Метод поиска для библиотеки
  void _searchManga(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMangaList = _mangaList;
      } else {
        _filteredMangaList = _mangaList.where((manga) {
          return manga.title.toLowerCase().contains(query.toLowerCase()) ||
              manga.author.toLowerCase().contains(query.toLowerCase()) ||
              manga.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
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
        _filteredMangaList = _mangaList;
        _filteredScheduleList = _scheduleList;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
            // Добавляем иконку поиска
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          cursorColor: Colors.deepPurple,
          onChanged: _search,
        )
            : const Text('Главная'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
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
        onPressed: _addNewManga,
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
          // Сбрасываем поиск при переключении вкладок
          if (_isSearching) {
            _searchController.clear();
            _filteredMangaList = _mangaList;
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
    final resultCount = _currentIndex == 0
        ? _filteredMangaList.length
        : _filteredScheduleList.length;
    final totalCount = _currentIndex == 0
        ? _mangaList.length
        : _scheduleList.length;

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
              'Найдено: $resultCount/$totalCount',
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
        itemCount: _filteredMangaList.length + 1,
        itemBuilder: (context, index) {
          if (index == _filteredMangaList.length) {
            return _buildAddMangaCard();
          }
          return _buildMangaCard(_filteredMangaList[index]);
        },
      ),
    );
  }

  // Контент расписания
  Widget _buildScheduleContent() {
    final thisWeekSchedule = _filteredScheduleList.where((item) {
      final difference = item.releaseDate.difference(DateTime.now()).inDays;
      return difference <= 7;
    }).toList();

    final futureSchedule = _filteredScheduleList.where((item) {
      final difference = item.releaseDate.difference(DateTime.now()).inDays;
      return difference > 7;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // На этой неделе
          _buildScheduleSection(
            title: 'НА ЭТОЙ НЕДЕЛЕ',
            schedule: thisWeekSchedule,
          ),
          const SizedBox(height: 24),

          // Будущие выходы
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
          // Иконка статуса
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

          // Информация
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
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
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
  Widget _buildMangaCard(Manga manga) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openMangaDetails(manga),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.menu_book,
                size: 50,
                color: Colors.deepPurple.withOpacity(0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'т.${manga.volume}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: manga.progress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.deepPurple,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(manga.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMangaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: _addNewManga,
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
              'Добавить новую',
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

  void _openMangaDetails(Manga manga) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MangaDetailsScreen(manga: manga),
      ),
    );
  }

  void _addNewManga() {
    print('Добавить новую мангу');
  }
}