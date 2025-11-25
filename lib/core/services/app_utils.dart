import 'dart:convert';
import 'dart:io';
import 'package:downloadsfolder/downloadsfolder.dart' as downloadsfolder;
import 'package:path_provider/path_provider.dart';

class AppUtils {
  /// Преобразует байты в читаемый формат (Б, КБ, МБ, ГБ)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  /// Форматирует время в читаемый вид
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}ч ${duration.inMinutes.remainder(60)}мин';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}мин ${duration.inSeconds.remainder(60)}сек';
    } else {
      return '${duration.inSeconds}сек';
    }
  }

  /// Обрезает строку если она слишком длинная
  static String truncateString(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static Future<File> createTextFile(String text, String fileName) async {
    try {
      // Получаем директорию для документов
      final directory = await downloadsfolder.getDownloadDirectory();
      final file = File('${directory.path}/$fileName.txt');

      // Записываем текст в файл
      await file.writeAsString(text, encoding: utf8);

      // print('✅ Файл создан: ${file.path}');
      return file;
    } catch (e) {
      // print('❌ Ошибка создания файла: $e');
      rethrow;
    }
  }
}