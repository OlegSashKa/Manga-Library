import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangalibrary/core/database/tables/book_view_table.dart';
import 'package:mangalibrary/domain/models/book.dart';
import 'package:mangalibrary/domain/models/bookView.dart';
import 'package:mangalibrary/ui/reader_screen/text_page_widget.dart';

class TextReaderScreen extends StatefulWidget {
  final Book book;

  const TextReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
    bool _isLoading = true;
    bool _hasError = false;
    bool _showAppBar = false;

    BookView _bookView = BookView.defaultSettings();

    void _toggleAppBar() {
      setState(() {
        _showAppBar = !_showAppBar;
      });
    }

    @override
    void initState() {
      super.initState();
      _loadSettings();
    }

    Future<void> _loadSettings() async {
      try{
        final settings = await BookViewTable.getSettings();
        setState(() {
          _bookView = settings;
        });
      }catch(e){
        print('Ошибка загрузки настроек: $e');
        setState(() {
        });
      }
    }

    void _changeLineHeight() {
      final double newLineHeight = _bookView.lineHeight <= 1 ? 1 : _bookView.lineHeight - 0.25;
      final updatedBookView = BookView(
        id: _bookView.id,
        fontSize: _bookView.fontSize,
        lineHeight: newLineHeight,
        backgroundColor: _bookView.backgroundColor,
        textColor: _bookView.textColor,
      );

      setState(() {
        _bookView = updatedBookView;
      });

      BookViewTable.updateSettings(updatedBookView);
    }

    void _changeLineLower() {
      final double newLineHeight = _bookView.lineHeight >= 5 ? 5 : _bookView.lineHeight + 0.25;

      final updatedBookView = BookView(
        id: _bookView.id,
        fontSize: _bookView.fontSize,
        lineHeight: newLineHeight,
        backgroundColor: _bookView.backgroundColor,
        textColor: _bookView.textColor,
      );

      setState(() {
        _bookView = updatedBookView;
      });

      BookViewTable.updateSettings(updatedBookView);
    }

    void _increaseFontSize() {
      final double newFontSize = _bookView.fontSize + 3 >= 32 ? 32 : _bookView.fontSize + 3;
      print("newFontSize " + newFontSize.toString());

      final updatedBookView = BookView(
        id: _bookView.id,
        fontSize: newFontSize,
        lineHeight: _bookView.lineHeight,
        backgroundColor: _bookView.backgroundColor,
        textColor: _bookView.textColor,
      );

      // Точечное обновление в базе
      setState(() {
        _bookView = updatedBookView;
      });

      BookViewTable.updateSettings(updatedBookView);
    }

    void _decreaseFontSize() {
      final double newFontSize = _bookView.fontSize - 3 <= 14 ? 14 : _bookView.fontSize - 3;
      print("newFontSize " + newFontSize.toString());
      final updatedBookView = BookView(
        id: _bookView.id,
        fontSize: newFontSize,
        lineHeight: _bookView.lineHeight,
        backgroundColor: _bookView.backgroundColor,
        textColor: _bookView.textColor,
      );

      setState(() {
        _bookView = updatedBookView;
      });

      BookViewTable.updateSettings(updatedBookView);
    }


    void _toggleDarkMode() {
      final newBackgroundColor = _bookView.getBackgroundColor == Colors.white
          ? Colors.black.toARGB32()
          : Colors.white.toARGB32();
      final newTextColor = _bookView.getTextColor == Colors.white
          ? Colors.black.toARGB32()
          : Colors.white.toARGB32();

      final updatedBookView = BookView(
        id: _bookView.id,
        fontSize: _bookView.fontSize,
        lineHeight: _bookView.lineHeight,
        backgroundColor: newBackgroundColor,
        textColor: newTextColor,
      );

      setState(() {
        _bookView = updatedBookView;
      });

      BookViewTable.updateSettings(updatedBookView);
    }

    @override
    Widget build(BuildContext context) {
      Color _backgroundColor = _bookView.getBackgroundColor;
      Color _textColor = _bookView.getTextColor;

      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Stack(
          children: [
            // Основной контент БЕЗ отступов
            GestureDetector(
              onTap: _toggleAppBar,
              child: Container(
                color: _backgroundColor,
                width: double.infinity,
                height: double.infinity,
                child: _buildContent(),
              ),
            ),

            // AppBar с ограниченной высотой
            AnimatedOpacity(
              duration: Duration(milliseconds: 150),
              opacity: _showAppBar ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showAppBar,
                child: Container(
                  height: kToolbarHeight + MediaQuery.of(context).padding.top, // ← ОГРАНИЧИВАЕМ ВЫСОТУ
                  child: _buildAppBar(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildAppBar() {
      return Material(
        color: _bookView.getBackgroundColor,
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
          backgroundColor: _bookView.getBackgroundColor,
          foregroundColor: _bookView.getTextColor,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              color: _bookView.getBackgroundColor,
              icon: Icon(Icons.settings, color: _bookView.getTextColor),
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
                      Icon(Icons.text_increase, color: _bookView.getTextColor),
                      SizedBox(width: 8),
                      Text('Увеличить шрифт', style: TextStyle(color: _bookView.getTextColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'decrease_font',
                  child: Row(
                    children: [
                      Icon(Icons.text_decrease, color: _bookView.getTextColor),
                      SizedBox(width: 8),
                      Text('Уменьшить шрифт', style: TextStyle(color: _bookView.getTextColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'dark_mode',
                  child: Row(
                    children: [
                      Icon(_bookView.getBackgroundColor == Colors.white
                          ? Icons.dark_mode
                          : Icons.light_mode,
                          color: _bookView.getTextColor
                      ),
                      SizedBox(width: 8),
                      Text(_bookView.getTextColor == Colors.white
                          ? 'Темный режим'
                          : 'Светлый режим',
                          style: TextStyle(color: _bookView.getTextColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'line_height_increase',
                  child: Row(
                    children: [
                      Icon(Icons.format_line_spacing, color: _bookView.getTextColor),
                      SizedBox(width: 8),
                      Text('Высота строки: ${_bookView.lineHeight}', style: TextStyle(color: _bookView.getTextColor)),
                      Icon(Icons.remove, color: Colors.black),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'line_height_decrease',
                  child: Row(
                    children: [
                      Icon(Icons.format_line_spacing, color: _bookView.getTextColor),
                      SizedBox(width: 8),
                      Text('Высота строки: ${_bookView.lineHeight}', style: TextStyle(color: _bookView.getTextColor)),
                      Icon(Icons.add, color: Colors.black),
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
      return Scaffold(
        body: SafeArea(
          child: TextPageWidget(
            bookView: _bookView,
            book: widget.book,
          ),
        ),
      );
    }


    @override
    void dispose() {
      super.dispose();
    }
}