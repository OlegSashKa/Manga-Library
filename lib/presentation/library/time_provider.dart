import 'package:flutter/foundation.dart';
import '../../domain/models/world_time.dart';

class TimeProvider with ChangeNotifier {
  WorldTime _currentTime = _getTokyoTime();
  bool _isTokyoTime = true;

  WorldTime get currentTime => _currentTime;
  bool get isTokyoTime => _isTokyoTime;

  static WorldTime _getTokyoTime() {
    final now = DateTime.now();
    final tokyoTime = now.add(const Duration(hours: 9)); // UTC+9 для Токио

    return WorldTime(
      datetime: tokyoTime,
      timezone: 'JST',
      location: 'Токийское',
    );
  }

  static WorldTime _getLocalTime() {
    final now = DateTime.now();
    // final localTime = now.add(const Duration(hours: 3));

    return WorldTime(
      datetime: now,
      timezone: 'MSK', // или другой локальный часовой пояс
      location: 'Локальное',
    );
  }

  void toggleTime() {
    _isTokyoTime = !_isTokyoTime;
    _currentTime = _isTokyoTime ? _getTokyoTime() : _getLocalTime();
    notifyListeners();
  }

  void updateTime() {
    _currentTime = _isTokyoTime ? _getTokyoTime() : _getLocalTime();
    notifyListeners();
  }
}