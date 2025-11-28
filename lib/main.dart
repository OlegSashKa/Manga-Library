import 'package:flutter/material.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:provider/provider.dart';
import 'package:mangalibrary/ui/library/library_screen.dart';
import 'package:mangalibrary/core/services/app_info_service.dart';
import 'package:mangalibrary/ui/library/time_provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInfoService.instance.initialize();
  await BookView.loadFromDatabase();

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
        home: const LibraryScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}