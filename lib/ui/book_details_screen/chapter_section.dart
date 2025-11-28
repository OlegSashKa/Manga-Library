import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/chapters_table.dart';
import 'package:mangalibrary/core/database/tables/volume_table.dart';
import 'package:mangalibrary/core/services/app_globals.dart';
import 'package:mangalibrary/domain/models/book_volume.dart';
import 'package:mangalibrary/domain/models/volume_chapter.dart';
import 'package:mangalibrary/enums/book_enums.dart';

class ChapterSection extends StatefulWidget{
  final int bookId;
  final List<BookVolume>? initialVolumes;
  final Function(int targetPage)? onChapterSelected;

  const ChapterSection({
    super.key,
    required this.bookId,
    this.initialVolumes,
    this.onChapterSelected,
  });

  @override
  State<ChapterSection> createState() => _ChapterSectionState();
}

class _ChapterSectionState extends State<ChapterSection> {
  final ChapterTable _chaptersTable = ChapterTable();
  final VolumesTable _volumesTable = VolumesTable();
  late Future<List<BookVolume>> _volumesFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialVolumes != null && widget.initialVolumes!.isNotEmpty) {
      _volumesFuture = Future.value(widget.initialVolumes!);
    } else {
      _volumesFuture = _loadVolumesAndChapters();
    }
  }

  Future<List<BookVolume>> _loadVolumesAndChapters() async {
    try {
      List<BookVolume> volumes = await _volumesTable.getVolumesByBookId(widget.bookId);

      await Future.wait(volumes.map((volume) async {
        if (volume.id != null) {
          volume.chapters = await _chaptersTable.getChaptersByVolumeId(volume.id!);
        }
      }));

      return volumes;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookVolume>>(
      future: _volumesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppGlobals.showError('Не удалось загрузить Тома и Главы');
          });
          return Center(
            child: Text(
              'Ошибка загрузки данных: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final List<BookVolume> volumes = snapshot.data ?? [];

        if (volumes.isEmpty) {
          return Center(child: Text('Нет доступных томов.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: BouncingScrollPhysics(),
          itemCount: volumes.length,
          itemBuilder: (context, volumeIndex) {
            final volume = volumes[volumeIndex];

            // Проверяем, есть ли у тома filePath для кликабельности
            final bool isVolumeClickable = volume.fileFolderPath != null && volume.fileFolderPath!.isNotEmpty;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ExpansionTile(
                title: GestureDetector(
                  onTap: isVolumeClickable ? () => _openVolume(volume) : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          volume.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isVolumeClickable ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                      if (isVolumeClickable)
                        Icon(Icons.play_arrow, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
                subtitle: GestureDetector(
                  onTap: isVolumeClickable ? () => _openVolume(volume) : null,
                  child: Text(
                    'Страницы: ${_calculateCurrentPageInVolume(volume)}/${_calculateTotalPagesInVolume(volume)} | Глав: ${volume.chapters.length}',
                    style: TextStyle(
                      color: isVolumeClickable ? Colors.blue : null,
                    ),
                  ),
                ),
                children: [
                  if (volume.chapters.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
                      child: Text(
                        'Нет глав в этом томе.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...volume.chapters.map((chapter) =>
                        _buildChapterListTile(chapter)).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Метод для открытия тома
  void _openVolume(BookVolume volume) {
    print('📖 Открыть том: \"${volume.title}\"');
    print('📄 Страницы: ${volume.startPage}-${volume.endPage}');
    print('📍 Путь к файлу: ${volume.fileFolderPath}');

    if (widget.onChapterSelected != null) {
      widget.onChapterSelected!(volume.startPage);
    }
  }

  int _calculateCurrentPageInVolume(BookVolume volume) {
    if (volume.book == null) return 0;
    final currentInVolume = volume.book!.currentPage - volume.startPage + 1;
    final totalInVolume = volume.endPage! - volume.startPage + 1;
    return currentInVolume.clamp(0, totalInVolume);
  }

  int _calculateTotalPagesInVolume(BookVolume volume) {
    return volume.endPage! - volume.startPage + 1;
  }

  Widget _buildChapterListTile(VolumeChapter chapter) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 32, right: 16),
      title: Text(chapter.title),
      subtitle: _buildChapterSubtitle(chapter),
      trailing: _buildChapterTrailing(chapter),
      onTap: () => _openChapter(chapter),
    );
  }

  Widget _buildChapterSubtitle(VolumeChapter chapter) {
    if (chapter.isRead == BookStatus.completed) {
      return Text('Прочитано');
    } else if (chapter.isRead == BookStatus.reading) {
      final currentInChapter = chapter.pageInChapter;
      final totalInChapter = chapter.totalPagesInChapter ?? 1;
      return Text('Страница $currentInChapter/$totalInChapter ${chapter.isRead.name}');
    } else {
      return Text('Не начато');
    }
  }

  Widget _buildChapterTrailing(VolumeChapter chapter) {
    if (chapter.isRead == BookStatus.completed) {
      return Icon(Icons.done_all, color: Colors.green);
    } else if (chapter.isRead == BookStatus.reading) {
      final currentInChapter = chapter.pageInChapter;
      final totalInChapter = chapter.totalPagesInChapter ?? 1;
      return Text(
        '$currentInChapter/$totalInChapter',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  void _openChapter(VolumeChapter chapter) {
    print('📖 Открыть главу: \"${chapter.title}\"');
    print('📄 Страницы: ${chapter.startPage}-${chapter.endPage}');
    print('📍 Текущая страница: ${chapter.pageInChapter}');

    if (widget.onChapterSelected != null) {
      widget.onChapterSelected!(chapter.startPage);
    }
  }
}