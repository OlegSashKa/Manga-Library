import 'package:mangalibrary/domain/models/book.dart';

class BookCacheService {
  static final BookCacheService _instance = BookCacheService._internal();
  factory BookCacheService() => _instance;
  BookCacheService._internal();

  final Map<int, List<String>> _pageCache = {};

  final List<int> _lruList = [];
  static const int maxCacheSize = 3; // Максимум 10 книг в кэше

  void cacheBookPages(int bookId, List<String> pages) {

    if (_lruList.length >= maxCacheSize) {
      final oldestBookId = _lruList.removeAt(0);
      _pageCache.remove(oldestBookId);
      print('🧹 Удалена из кэша книга ID: $oldestBookId');
    }

    _pageCache[bookId] = pages;

    _lruList.remove(bookId);
    _lruList.add(bookId);

    print('💾 Закэширована книга ID: $bookId (${pages.length} страниц)');
    print('📊 Размер кэша: ${_pageCache.length} книг');
  }

  void updateCachedPages(int bookId, List<String> newPages) {
    if (_pageCache.containsKey(bookId)) {
      _pageCache[bookId] = newPages;
      // Обновляем LRU
      _lruList.remove(bookId);
      _lruList.add(bookId);
      print('🔄 Обновлён кэш книги ID: $bookId (${newPages.length} страниц)');
    }
  }

  List<String>? getCachedPages(int bookId) {
    if (_pageCache.containsKey(bookId)) {
      // Обновляем LRU
      _lruList.remove(bookId);
      _lruList.add(bookId);
      print('⚡ Загружено из кэша: книга ID: $bookId');
      return _pageCache[bookId];
    }
    return null;
  }

  void clearCache() {
    _pageCache.clear();
    _lruList.clear();
    print('🗑️ Кэш полностью очищен');
  }

  void removeFromCache(int bookId) {
    _pageCache.remove(bookId);
    _lruList.remove(bookId);
    print('🧹 Удалена из кэша книга ID: $bookId');
  }
}