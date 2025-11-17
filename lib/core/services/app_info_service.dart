import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._private();
  static final AppInfoService _instance = AppInfoService._private();
  static AppInfoService get instance => _instance;

  PackageInfo? _packageInfo;
//Ошибка загрузки книги:
  bool get isInitialized => _packageInfo != null;

  Future<void> initialize() async {
    if (!isInitialized) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
  }

  AppInfoData get appInfo{
    if(!isInitialized) throw Exception('Сначала вызовите initialize()');
    return AppInfoData (_packageInfo!);
  }
}

class AppInfoData {
  final PackageInfo _packageInfo;

  AppInfoData (this._packageInfo);

  String get appName => _packageInfo.appName;
  String get version => _packageInfo.version;
  String get buildNumber => _packageInfo.buildNumber;
  String get fullInfoApp => "Приложение: $appName \n"
                            "Версия: $version \n"
                            "Билд: $buildNumber";
}