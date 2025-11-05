// lib/core/ui/components/database_info_widget.dart
import 'package:flutter/material.dart';
import '../../services/database_info_service.dart';
import '../../../domain/models/manga.dart';

class DatabaseInfoWidget extends StatelessWidget {
  final DatabaseInfoService databaseInfoService;
  final VoidCallback onExportDatabase;

  const DatabaseInfoWidget({
    super.key,
    required this.databaseInfoService,
    required this.onExportDatabase,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DatabaseInfo>(
      future: databaseInfoService.getDatabaseInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Ошибка загрузки информации о БД: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,

            ),
          );
        }

        final dbInfo = snapshot.data!;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              // Основная статистика
              _buildDatabaseStat('📚 Всего манг', '${dbInfo.mangaCount}'),
              _buildDatabaseStat('📖 Всего страниц', '${dbInfo.totalPages}'),
              _buildDatabaseStat('✅ Прочитано страниц', '${dbInfo.readPages}'),
              _buildDatabaseStat('📊 Общий прогресс', '${(dbInfo.progress * 100).toStringAsFixed(1)}%'),

              SizedBox(height: 20),

              // Статистика по статусам
              if (dbInfo.statusStats.isNotEmpty) ...[
                Text(
                  'СТАТУСЫ МАНГ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                ...dbInfo.statusStats.entries.map((entry) =>
                    _buildStatItem(entry.key, '${entry.value}')
                ).toList(),
                SizedBox(height: 20),
              ],

              // Список всех манг (простой вариант)
              _buildSimpleMangaList(dbInfo.allMangas),

              SizedBox(height: 20),

              // Действия с БД
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onExportDatabase, // ← Используем колбэк
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Экспорт БД в файл'),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () => Navigator.pop(context),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.deepPurple,
                  //       foregroundColor: Colors.white,
                  //     ),
                  //     child: Text('Закрыть'),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatabaseStat(String label, String value) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMangaList(List<Manga> mangas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'СПИСОК МАНГ (${mangas.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        ...mangas.map((manga) => _buildSimpleMangaListItem(manga)).toList(),
      ],
    );
  }

  Widget _buildSimpleMangaListItem(Manga manga) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // ID
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              manga.id,
              style: TextStyle(
                fontSize: 10,
                color: Colors.deepPurple,
                fontFamily: 'Monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          // Название
          Expanded(
            child: Text(
              manga.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}