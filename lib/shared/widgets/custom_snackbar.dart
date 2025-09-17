import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class CustomSnackBar {
  static SnackBar create(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    return SnackBar(
      content: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: action,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      create(context, message: message, action: action, duration: duration),
    );
  }

  // Deprecated methods for backwards compatibility
  @deprecated
  static SnackBar success(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => create(context, message: message, action: action, duration: duration);

  @deprecated
  static SnackBar error(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => create(context, message: message, action: action, duration: duration);

  @deprecated
  static SnackBar info(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => create(context, message: message, action: action, duration: duration);

  @deprecated
  static SnackBar download(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => create(context, message: message, action: action, duration: duration);

  @deprecated
  static void showSuccess(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message: message, action: action, duration: duration);

  @deprecated
  static void showError(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message: message, action: action, duration: duration);

  @deprecated
  static void showInfo(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message: message, action: action, duration: duration);

  @deprecated
  static void showDownload(
    BuildContext context, {
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) => show(context, message: message, action: action, duration: duration);
}
