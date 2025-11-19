// text_page_widget.dart - ШАГ 12 (полноэкранный со свайпом)
import 'package:flutter/material.dart';
import 'package:mangalibrary/core/utils/page_manager.dart';
import 'package:mangalibrary/core/utils/text_paginator.dart';

class TextPageWidget extends StatefulWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Color backgroundColor;
  final Size? fixedSize; // ← НОВЫЙ ПАРАМЕТР

  const TextPageWidget({
    super.key,
    required this.text,
    required this.fontSize,
    required this.lineHeight,
    required this.textColor,
    required this.backgroundColor,
    this.fixedSize, // ← ОПЦИОНАЛЬНЫЙ ФИКСИРОВАННЫЙ РАЗМЕР
  });

  @override
  State<TextPageWidget> createState() => _TextPageWidgetState();
}

class _TextPageWidgetState extends State<TextPageWidget> {
  List<String> _pages = [];
  int _currentPageIndex = 0;
  bool _isCalculatingPages = false;
  Size? _lastCalculatedSize;

  @override
  void initState() {
    super.initState();
  }

  void _onPagesUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    if (widget.fixedSize != null) {
      print('📐 [TEXT_PAGE] Используем фиксированный размер: ${widget.fixedSize}');
      return _buildWithFixedSize(widget.fixedSize!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        print('🎯 [TEXT_PAGE] LayoutBuilder размер: ${constraints.maxWidth}x${constraints.maxHeight}');
        return _buildContent(constraints.maxWidth, constraints.maxHeight);
      },
    );
  }

  Widget _buildWithFixedSize(Size fixedSize) {
    // 🔥 РАСЧЕТ СТРАНИЦ ДЛЯ ФИКСИРОВАННОГО РАЗМЕРА
    if (!_isCalculatingPages && _pages.isEmpty) {
      _isCalculatingPages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatePages(
          text: widget.text,
          pageWidth: fixedSize.width,
          pageHeight: fixedSize.height,
          fontSize: widget.fontSize,
          lineHeight: widget.lineHeight,
        );
      });
    }

    return _buildContent(fixedSize.width, fixedSize.height);
  }

  Widget _buildContent(double width, double height) {
    return Container(
      decoration: BoxDecoration( // ← ДОБАВИЛ ГРАНИЦУ
        border: Border.all(color: Colors.blue, width: 3.0),
        color: widget.backgroundColor,
      ),
      width: width,
      height: height,
      child: _pages.isNotEmpty
          ? PageView.builder(
        itemCount: _pages.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPageIndex = page;
          });
        },
        itemBuilder: (context, index) {
          return Container(
            // padding: EdgeInsets.all(16.0),
            child: SelectableText(
              _pages[index],
              style: TextStyle(
                fontSize: widget.fontSize,
                height: widget.lineHeight,
                color: widget.textColor,
              ),
              textAlign: TextAlign.justify,
            ),
          );
        },
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _calculatePages({
    required String text,
    required double pageWidth,
    required double pageHeight,
    required double fontSize,
    required double lineHeight,
  }) {
    print('🔄 [TEXT_PAGE] Calculating pages with TextPaginator');

    final paginator = TextPaginator();
    final newPages = paginator.paginate(
      fullText: text,
      textStyle: TextStyle(
        fontSize: fontSize,
        height: lineHeight,
        color: widget.textColor,
      ),
      pageSize: Size(pageWidth, pageHeight),
      // padding: EdgeInsets.all(16.0),
    );

    if (mounted) {
      setState(() {
        _pages = newPages;
        _isCalculatingPages = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

