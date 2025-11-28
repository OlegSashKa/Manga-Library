// open_library_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenLibraryBook {
  final String title;
  final String authorName;
  final String key;
  final int firstPublishYear;

  OpenLibraryBook({
    required this.title,
    required this.authorName,
    required this.key,
    required this.firstPublishYear,
  });

  factory OpenLibraryBook.fromJson(Map<String, dynamic> json) {
    // OpenLibrary API часто возвращает списки для авторов
    final authors = json['author_name'];
    final author = (authors != null && authors is List && authors.isNotEmpty)
        ? authors.first.toString()
        : 'Неизвестен';

    return OpenLibraryBook(
      title: json['title'] as String? ?? 'Нет заголовка',
      authorName: author,
      key: json['key'] as String? ?? '',
      firstPublishYear: json['first_publish_year'] as int? ?? 0,
    );
  }
}

class OpenLibraryService {
  static const String baseUrl = 'https://openlibrary.org';

  Future<List<OpenLibraryBook>> searchBooks(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search.json?q=$query&limit=10'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final docs = data['docs'] as List;

      return docs.map((json) => OpenLibraryBook.fromJson(json)).toList();
    } else {
      // Можно выбросить исключение или вернуть пустой список
      throw Exception('Ошибка при загрузке данных: ${response.statusCode}');
    }
  }
}