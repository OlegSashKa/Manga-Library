import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  PackageInfo? _packageInfo;

  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  // Геттеры для удобного доступа
  String get version => _packageInfo?.version ?? 'Неизвестно';
  String get buildNumber => _packageInfo?.buildNumber ?? 'Неизвестно';
  String get appName => _packageInfo?.appName ?? 'Неизвестно';
  String get packageName => _packageInfo?.packageName ?? 'Неизвестно';

  // Форматированные строки
  String get versionCompact => 'v$version ($buildNumber)';
  String get versionWithName => '$appName v$version';
  String get versionDetailed => '''Приложение: $appName
  Версия: $version
  Сборка: $buildNumber
  ''';
}