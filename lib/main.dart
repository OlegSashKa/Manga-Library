import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/core/database/database_helper.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:provider/provider.dart';
import 'package:mangalibrary/ui/library/library_screen.dart';
import 'package:mangalibrary/core/services/app_info_service.dart';
import 'package:mangalibrary/ui/library/time_provider.dart';
import 'package:mangalibrary/core/services/screen_size_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInfoService.instance.initialize();


  runApp(MangaLibraryApp());
}

class MangaLibraryApp extends StatelessWidget {
  const MangaLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimeProvider()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: AppGlobals.scaffoldMessengerKey,
        title: 'Manga Library',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: FutureBuilder(
          future: DatabaseHelper.initialize(), // ← ИНИЦИАЛИЗАЦИЯ ЗДЕСЬ
          builder: (context, snapshot) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScreenSizeService.initialize(context);
            });
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Загрузка...'),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Ошибка загрузки: ${snapshot.error}'),
                ),
              );
            }

            return const LibraryScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}