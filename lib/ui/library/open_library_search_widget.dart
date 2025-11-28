// open_library_search_widget.dart
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/open_library_service.dart';

class OpenLibrarySearchWidget extends StatefulWidget {
  const OpenLibrarySearchWidget({super.key});

  @override
  State<OpenLibrarySearchWidget> createState() => _OpenLibrarySearchWidgetState();
}

class _OpenLibrarySearchWidgetState extends State<OpenLibrarySearchWidget> {
  final OpenLibraryService _service = OpenLibraryService();
  late Future<List<OpenLibraryBook>> _booksFuture;
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = 'flutter';

  @override
  void initState() {
    super.initState();
    _booksFuture = _service.searchBooks(_currentQuery);
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _currentQuery = query;
      _booksFuture = _service.searchBooks(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Поле поиска
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск книг...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('flutter');
                },
              ),
            ),
            onSubmitted: _performSearch,
          ),
        ),

        // Результаты поиска
        Expanded(
          child: FutureBuilder<List<OpenLibraryBook>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _booksFuture = _service.searchBooks(_currentQuery);
                          });
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final book = snapshot.data![index];
                    return _buildBookItem(book);
                  },
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Книги по запросу "$_currentQuery" не найдены.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookItem(OpenLibraryBook book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: Colors.blue),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Автор: ${book.authorName}'),
            if (book.firstPublishYear > 0)
              Text(
                'Год первого издания: ${book.firstPublishYear}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Добавить переход к деталям книги
          // print('Нажата книга: ${book.title}');
        },
      ),
    );
  }
}