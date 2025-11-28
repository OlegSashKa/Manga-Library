import 'dart:async';

import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/domain/models/bookView.dart';

class BookViewService {
  static final BookViewService _instance = BookViewService._internal();
  static BookView? _cachedSettings;
  static bool _isLoading = false;
  static Completer<BookView>? _loadingCompleter;

  BookViewService._internal();

  factory BookViewService() => _instance;

  // 🔥 ГАРАНТИРОВАННАЯ загрузка настроек без race condition
  Future<BookView> getSettings() async {
    // Если уже загружаем - ждем тот же Completer
    if (_loadingCompleter != null) {
      return _loadingCompleter!.future;
    }

    // Если есть в кэше - возвращаем сразу
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    _loadingCompleter = Completer<BookView>();

    try {
      final settings = await BookViewTable.getSettings();
      _cachedSettings = settings;
      _loadingCompleter!.complete(settings);
    } catch (e) {
      _cachedSettings = BookView.defaultSettings();
      _loadingCompleter!.complete(_cachedSettings);
    } finally {
      _loadingCompleter = null;
    }

    return _cachedSettings!;
  }

  // 🔥 ГАРАНТИРОВАННОЕ обновление настроек
  Future<void> updateSettings(BookView newSettings) async {
    try {
      await BookViewTable.updateSettings(newSettings);
      _cachedSettings = newSettings;
    } catch (e) {
      print('❌ Ошибка сохранения настроек: $e');
      // Можно добавить повторную попытку
    }
  }

  // Сброс кэша (при logout или при необходимости)
  void clearCache() {
    _cachedSettings = null;
  }
}