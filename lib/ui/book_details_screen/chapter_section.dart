import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mangalibrary/domain/models/book.dart';

class ChapterSection extends StatefulWidget{
  final List<BookChapter> chapters;

  const ChapterSection({
      super.key,
      required this.chapters,
  });

  @override
  State<ChapterSection> createState() => _ChapterSectionState();
}

class _ChapterSectionState extends State<ChapterSection> {
  int collViewBook = 5;

  void _showAllChapters(){
    setState(() {
      collViewBook = widget.chapters.length;
    });
  }

  @override
  Widget build(BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Заголовок не прокручивается
        Text(
          'Главы'.toUpperCase(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),

        Expanded(
            child: ListView(
          children: [
          // Список глав (показываем только первые 3)
          ...widget.chapters.take(collViewBook).map((chapter) => _buildChapterTile(chapter)),

          // Кнопка "Показать все" если глав больше 3
          if(widget.chapters.length > collViewBook)
            TextButton(
              onPressed: _showAllChapters,
              child: Text('Показать все главы еще(${widget.chapters.length - collViewBook})'),),
            ],
          )
        )
      ],
    );
  }

  Widget _buildChapterTile(BookChapter chapter) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: _buildChapterIcon(chapter),
      title: Text(
        chapter.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: chapter.currentPage > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: _buildChapterSubtitle(chapter),
      trailing: chapter.isRead ? Text('✓') : null,
      onTap: () => _openChapter(chapter),
    );
  }

  Widget _buildChapterIcon(BookChapter chapter) {
    if(chapter.isRead){
      return Icon(Icons.check_circle, color: Colors.green);
    } else if (chapter.currentPage > 0) {
      return Icon(Icons.play_circle, color: Colors.orange);
    } else{
      return Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
  }

  Widget _buildChapterSubtitle(BookChapter chapter) {
    if(chapter.isRead){
      return Text('Прочитано');
    } else if (chapter.currentPage > 0){
      return Text('Страница ${chapter.currentPage}');
    } else {
      return Text('Не начато');
    }
  }

  void _openChapter(BookChapter chapter) {
    print('Открыть главу: ${chapter.title}');
  }
}
