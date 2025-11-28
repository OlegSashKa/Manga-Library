import 'package:flutter/material.dart';
import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/core/services/book_view_service.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/ui/reader_screen/text_page_widget.dart';

//TODO этот класс должен читать книгу с учетом нашей иерархии
//TODO поидее сильно тут менять ничего не надо, я думаю с text_page_widget придется покапатся
class TextReaderScreen extends StatefulWidget {
  final Book book;
  final int? targetPage;

  const TextReaderScreen({
    super.key,
    required this.book,
    this.targetPage,
  });

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
    bool _showAppBar = false;
    final _bookView = BookView.instance;
    bool _isBookReady = false;
    final GlobalKey<TextPageWidgetState> _textPageKey = GlobalKey<TextPageWidgetState>();

    void _onBookReady(bool isRead) {
      setState(() {
        _isBookReady = isRead;
      });
    }

    void _toggleAppBar() {
      if (_isBookReady) {
        setState(() {
          _showAppBar = !_showAppBar;
        });
      }
    }

    @override
    void initState() {
      super.initState();
      _initializeSettings();
    }


    Future<void> _initializeSettings() async {
      // 🔥 ЗАГРУЖАЕМ НАСТРОЙКИ ИЗ БД В СИНГЛТОН
      await BookView.loadFromDatabase();
      if (mounted) {
        setState(() {});
      }
    }

    void _changeLineHeight() async {
      final double newLineHeight = _bookView.lineHeight <= 1 ? 1 : _bookView.lineHeight - 0.25;

      await BookView.updateSettings(
        lineHeight: newLineHeight,
      );
      _textPageKey.currentState?.reloadPages();
      setState(() {});
    }

    void _changeLineLower() async {
      final double newLineHeight = _bookView.lineHeight >= 5 ? 5 : _bookView.lineHeight + 0.25;

      await BookView.updateSettings(
        lineHeight: newLineHeight,
      );
      _textPageKey.currentState?.reloadPages();
      setState(() {});
    }

    void _increaseFontSize() async {
      final double newFontSize = _bookView.fontSize + 3 >= 32 ? 32 : _bookView.fontSize + 3;

      await BookView.updateSettings(
        fontSize: newFontSize,
      );
      _textPageKey.currentState?.reloadPages();
      setState(() {});
    }

    void _decreaseFontSize() async {
      final double newFontSize = _bookView.fontSize - 3 <= 14 ? 14 : _bookView.fontSize - 3;

      await BookView.updateSettings(
        fontSize: newFontSize,
      );
      _textPageKey.currentState?.reloadPages();
      setState(() {});
    }


    void _toggleDarkMode() async {
      final newBackgroundColor = _bookView.getBackgroundColor == Colors.white
          ? Colors.black.toARGB32()
          : Colors.white.toARGB32();
      final newTextColor = _bookView.getTextColor == Colors.white
          ? Colors.black.toARGB32()
          : Colors.white.toARGB32();

      await BookView.updateSettings(
        textColor: newTextColor,
        backgroundColor: newBackgroundColor,
      );
      // _textPageKey.currentState?.reloadPages();
      setState(() {});
    }

    @override
    Widget build(BuildContext context) {
      Color _backgroundColor = _bookView.getBackgroundColor;
      Color _textColor = _bookView.getTextColor;

      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Stack(
          children: [
            // Основной контент БЕЗ GestureDetector (он теперь в TextPageWidget)
            Container(
              color: _backgroundColor,
              width: double.infinity,
              height: double.infinity,
              child: _buildContent(),
            ),

            // AppBar с ограниченной высотой
            AnimatedOpacity(
              duration: Duration(milliseconds: 150),
              opacity: (_isBookReady && _showAppBar) ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !(_isBookReady && _showAppBar),
                child: Container(
                  height: kToolbarHeight + MediaQuery.of(context).padding.top,
                  child: _buildAppBar(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildAppBar() {
      Color _backgroundColor = _bookView.getBackgroundColor;
      Color _textColor = _bookView.getTextColor;
      return Material(
        color: _backgroundColor,
        elevation: 2,
        child: AppBar(
          title: Text(
            widget.book.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              color: _backgroundColor,
              icon: Icon(Icons.settings, color: _textColor),
              onSelected: (value) {
                switch (value) {
                  case 'increase_font':
                    _increaseFontSize();
                    break;
                  case 'decrease_font':
                    _decreaseFontSize();
                    break;
                  case 'dark_mode':
                    _toggleDarkMode();
                    break;
                  case 'line_height_increase':
                    _changeLineHeight();
                    break;
                  case 'line_height_decrease':
                    _changeLineLower();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'increase_font',
                  child: Row(
                    children: [
                      Icon(Icons.text_increase, color: _textColor),
                      SizedBox(width: 8),
                      Text('Увеличить шрифт', style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'decrease_font',
                  child: Row(
                    children: [
                      Icon(Icons.text_decrease, color: _textColor),
                      SizedBox(width: 8),
                      Text('Уменьшить шрифт', style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'dark_mode',
                  child: Row(
                    children: [
                      Icon(_backgroundColor == Colors.white
                          ? Icons.dark_mode
                          : Icons.light_mode,
                          color: _textColor
                      ),
                      SizedBox(width: 8),
                      Text(_textColor == Colors.white
                          ? 'Светлый режим'
                          : 'Темный режим',
                          style: TextStyle(color: _textColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'line_height_increase',
                  child: Row(
                    children: [
                      Icon(Icons.format_line_spacing, color: _textColor),
                      SizedBox(width: 8),
                      Text('Высота строки: ${_bookView.lineHeight}', style: TextStyle(color: _textColor)),
                      Icon(Icons.remove, color: _textColor),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'line_height_decrease',
                  child: Row(
                    children: [
                      Icon(Icons.format_line_spacing, color: _textColor),
                      SizedBox(width: 8),
                      Text('Высота строки: ${_bookView.lineHeight}', style: TextStyle(color: _textColor)),
                      Icon(Icons.add, color: _textColor),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    Widget _buildContent() {
      // AppGlobals.showInfo('из textReader targetPage ${widget.targetPage}');
      return SafeArea(
        child: TextPageWidget(
          key: _textPageKey,
          book: widget.book,
          onScreenTap: _toggleAppBar, //_toggleAppBar
          onBookReady: _onBookReady,
          targetPage: widget.targetPage,
        ),
      );
    }


    @override
    void dispose() {
      super.dispose();
    }
}