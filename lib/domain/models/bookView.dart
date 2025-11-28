import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/book_view_table.dart';

class BookView{
  int? id;
  //поиде здесь должен быть настройки аккаунта но здесь их не будет
  double fontSize;
  double lineHeight;
  int backgroundColor;
  int textColor;

  BookView._internal({
    this.id,
    required this.fontSize,
    required this.lineHeight,
    required this.backgroundColor,
    required this.textColor,
  });

  static final BookView _instance = BookView._internal(
    id: 1,
    fontSize: 16,
    lineHeight: 1.5,
    backgroundColor: Colors.white.toARGB32(),
    textColor: Colors.black.toARGB32(),
  );

  // 🔥 Геттер для доступа к экземпляру
  static BookView get instance => _instance;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'font_size': fontSize,
      'line_height': lineHeight,
      'background_color': backgroundColor,
      'text_color': textColor,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  static Future<void> updateSettings({
    double? fontSize,
    double? lineHeight,
    int? backgroundColor,
    int? textColor,
  }) async {
    _instance.fontSize = fontSize ?? _instance.fontSize;
    _instance.lineHeight = lineHeight ?? _instance.lineHeight;
    _instance.backgroundColor = backgroundColor ?? _instance.backgroundColor;
    _instance.textColor = textColor ?? _instance.textColor;

    // 🔥 АВТОМАТИЧЕСКИ СОХРАНЯЕМ В БД
    await saveToDatabase();
  }

  // 🔥 Метод для сброса к настройкам по умолчанию
  static Future<void> resetToDefaults() async {
    _instance.fontSize = 16;
    _instance.lineHeight = 1.5;
    _instance.backgroundColor = Colors.white.toARGB32();
    _instance.textColor = Colors.black.toARGB32();

    // 🔥 СОХРАНЯЕМ В БД
    await saveToDatabase();
  }

  factory BookView.fromMap(Map<String, dynamic> map) {
    return BookView._internal(
      id: map['id'],
      fontSize: map['font_size'] ?? 16.0,
      lineHeight: map['line_height'] ?? 1.5,
      backgroundColor: map['background_color'] ?? 0xFFFFFFFF,
      textColor: map['text_color'] ?? 0xFF000000,
    );
  }

  static Future<void> loadFromDatabase() async {
    try {
      final settings = await BookViewTable.getSettings();

      // 🔥 ОБНОВЛЯЕМ СИНГЛТОН данными из БД
      _instance.id = settings.id;
      _instance.fontSize = settings.fontSize;
      _instance.lineHeight = settings.lineHeight;
      _instance.backgroundColor = settings.backgroundColor;
      _instance.textColor = settings.textColor;

      print('✅ Настройки загружены из БД: $_instance');
    } catch (e) {
      print('❌ Ошибка загрузки настроек: $e');
      // Оставляем значения по умолчанию
    }
  }

  static Future<void> saveToDatabase() async {
    try {
      await BookViewTable.updateSettings(_instance);
      print('✅ Настройки сохранены в БД: $_instance');
    } catch (e) {
      print('❌ Ошибка сохранения настроек: $e');
      rethrow;
    }
  }

  BookView copyWith({
    int? id,
    double? fontSize,
    double? lineHeight,
    int? backgroundColor,
    int? textColor,
  }) {
    return BookView._internal(
      id: id ?? this.id,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  Color get getBackgroundColor => Color(BookView._instance.backgroundColor);
  Color get getTextColor => Color(BookView._instance.textColor);

  static BookView defaultSettings() {
    return BookView._internal(
      id: 1, // ← ID по умолчанию
      fontSize: 16,
      lineHeight: 1.5,
      backgroundColor: 0xFFFFFFFF, // белый
      textColor: 0xFF000000, // черный
    );
  }

  @override
  String toString() {
    return 'BookView{id: $id, fontSize: $fontSize, lineHeight: $lineHeight, backgroundColor: $backgroundColor, textColor: $textColor}';
  }
}