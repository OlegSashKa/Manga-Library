import 'package:flutter/material.dart';

class BookView{
  int? id;
  //поиде здесь должен быть настройки аккаунта но здесь их не будет
  double fontSize;
  double lineHeight;
  int backgroundColor;
  int textColor;

  BookView({
    this.id,
    required this.fontSize,
    required this.lineHeight,
    required this.backgroundColor,
    required this.textColor,
  });

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

  factory BookView.fromMap(Map<String, dynamic> map) {
    return BookView(
      id: map['id'],
      fontSize: map['font_size'] ?? 16.0,
      lineHeight: map['line_height'] ?? 1.5,
      backgroundColor: map['background_color'] ?? 0xFFFFFFFF,
      textColor: map['text_color'] ?? 0xFF000000,
    );
  }

  Color get getBackgroundColor => Color(backgroundColor);
  Color get getTextColor => Color(textColor);

  static BookView defaultSettings() {
    return BookView(
      fontSize: 16.0,
      lineHeight: 1.5,
      backgroundColor: 0xFFFFFFFF, // белый
      textColor: 0xFF000000, // черный
    );
  }
}