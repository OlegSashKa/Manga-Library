import 'package:flutter/material.dart';

class AppGlobals {
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // 🔥 БАЗОВЫЕ НАСТРОЙКИ SNACKBAR
  static Duration defaultDuration = Duration(seconds: 1);
  static Color defaultColor = Colors.grey[800]!;
  static Color successColor = Colors.green;
  static Color errorColor = Colors.red;
  static Color warningColor = Colors.orange;
  static Color infoColor = Colors.blue;

  // 🔥 ОСНОВНОЙ МЕТОД С ВОЗМОЖНОСТЬЮ КАСТОМИЗАЦИИ
  static void showSnackBar(
      String message, {
        Duration? duration,
        Color? backgroundColor,
        TextStyle? textStyle,
        SnackBarAction? action,
        double? elevation,
        ShapeBorder? shape,
        EdgeInsetsGeometry? margin,
        EdgeInsetsGeometry? padding,
        bool? dismissible,
      }) {
    scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: textStyle ?? TextStyle(color: Colors.white),
          ),
          duration: duration ?? defaultDuration,
          backgroundColor: backgroundColor ?? defaultColor,
          action: action,
          elevation: elevation ?? 6.0,
          shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: margin,
          padding: padding,
          behavior: margin != null ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
          dismissDirection: dismissible ?? true ? DismissDirection.down : DismissDirection.none,
        )
    );
  }

  // БЫСТРЫЕ МЕТОДЫ ДЛЯ ЧАСТЫХ СЛУЧАЕВ
  static void showSuccess(String message, {Duration? duration}) {
    showSnackBar(
      message,
      duration: duration,
      backgroundColor: successColor,
    );
  }

  static void showError(String message, {Duration? duration}) {
    showSnackBar(
      message,
      duration: duration,
      backgroundColor: errorColor,
    );
  }

  static void showWarning(String message, {Duration? duration}) {
    showSnackBar(
      message,
      duration: duration,
      backgroundColor: warningColor,
    );
  }

  static void showInfo(String message, {Duration? duration}) {
    showSnackBar(
      message,
      duration: duration,
      backgroundColor: infoColor,
    );
  }
}