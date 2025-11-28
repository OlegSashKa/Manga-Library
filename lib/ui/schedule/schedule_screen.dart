// schedule_screen.dart (переименован для примера)
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/open_library_service.dart'; // Импортируем наш сервис

class LibrarySearchScreen extends StatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  State<LibrarySearchScreen> createState() => _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends State<LibrarySearchScreen> {
  final OpenLibraryService _service = OpenLibraryService();
  late Future<List<OpenLibraryBook>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // 💡 ИНИЦИАЛИЗИРУЕМ ЗАПРОС ПРИ ЗАГРУЗКЕ ЭКРАНА
    // Запрос по ключевому слову 'flutter' для примера
    _booksFuture = _service.searchBooks('Flutter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('📚 Поиск OpenLibrary'), // Измененный заголовок
      ),
      body: FutureBuilder<List<OpenLibraryBook>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 1. Состояние загрузки
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 2. Состояние ошибки
            return Center(
              child: Text('Ошибка загрузки: ${snapshot.error}'),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // 3. Успешная загрузка данных
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final book = snapshot.data![index];
                return _buildBookItem(book);
              },
            );
          } else {
            // 4. Нет данных
            return const Center(
              child: Text('Книги по запросу "Flutter" не найдены.'),
            );
          }
        },
      ),
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
        subtitle: Text('Автор: ${book.authorName}'),
        trailing: Text(
          'Год: ${book.firstPublishYear}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          // Действие при нажатии на книгу, например, переход на страницу деталей
          // print('Нажата книга: ${book.title}');
        },
      ),
    );
  }
}
