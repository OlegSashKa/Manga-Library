class TextSettings {
  static const double fontSize = 16.0;
  static const double lineHeight = 1.5; // межстрочный интервал (множитель)
  static const double paragraphSpacing = 8.0; // отступ между абзацами
  static const double charWidthFactor = 0.6; // примерная ширина символа относительно высоты

  // Рассчитываем высоту одной строки
  static double get lineHeightPixels => fontSize * lineHeight;
}